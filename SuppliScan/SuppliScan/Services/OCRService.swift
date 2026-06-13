// OCRService.swift
// SuppliScan
//
// Vision OCR boundary. The service returns raw recognized text and confidence
// metadata only; parsing and clinical calculations stay in separate services.

import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import Vision

/// Recognizes text lines from a downsampled image.
nonisolated protocol OCRTextRecognizing: Sendable {
    func recognizedLines(in image: CGImage) async throws -> [OCRRecognizedLine]
}

/// Runs Vision text recognition off the caller actor.
nonisolated struct VisionTextRecognizer: OCRTextRecognizing {
    private let customWords: [String]
    private let usesLanguageCorrection: Bool
    private let recognitionRevision: Int

    init(
        customWords: [String] = Self.defaultCustomWords(),
        usesLanguageCorrection: Bool = true,
        recognitionRevision: Int = VNRecognizeTextRequestRevision3
    ) {
        self.customWords = customWords
        self.usesLanguageCorrection = usesLanguageCorrection
        self.recognitionRevision = recognitionRevision
    }

    @concurrent
    func recognizedLines(in image: CGImage) async throws -> [OCRRecognizedLine] {
        try Task.checkCancellation()

        let variants = Self.imageVariants(from: image)
        var lines: [OCRRecognizedLine] = []

        for pass in Self.defaultPasses(usesLanguageCorrection: usesLanguageCorrection) {
            guard let variantImage = variants[pass.variant] else { continue }
            lines.append(contentsOf: try recognizeLegacyLines(in: variantImage, pass: pass))
            try Task.checkCancellation()
        }

        if let documentImage = variants[.contrast] ?? variants[.original],
           let documentLines = try? await recognizeDocumentLines(in: documentImage) {
            lines.append(contentsOf: documentLines)
        }

        return lines
    }

    private func recognizeLegacyLines(in image: CGImage, pass: VisionOCRPass) throws -> [OCRRecognizedLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = pass.recognitionLevel.vnValue
        request.revision = recognitionRevision
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = pass.usesLanguageCorrection
        request.customWords = customWords
        request.minimumTextHeight = pass.minimumTextHeight

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        return request.results?.compactMap { observation -> OCRRecognizedLine? in
#if DEBUG
            let candidateCount = 3
#else
            let candidateCount = 1
#endif
            let candidates = observation.topCandidates(candidateCount)
            guard let top = candidates.first else { return nil }
            let text = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }

            let bounds = observation.boundingBox
            let region = OCRTextRegion(
                minX: bounds.minX,
                minY: bounds.minY,
                width: bounds.width,
                height: bounds.height
            )
#if DEBUG
            let alts = candidates.dropFirst().map {
                OCRAlternativeCandidate(
                    text: $0.string.trimmingCharacters(in: .whitespacesAndNewlines),
                    confidence: $0.confidence
                )
            }
            return OCRRecognizedLine(
                text: text,
                confidence: top.confidence,
                region: region,
                sourceID: pass.id,
                sourcePassIDs: [pass.id],
                alternatives: alts
            )
#else
            return OCRRecognizedLine(
                text: text,
                confidence: top.confidence,
                region: region,
                sourceID: pass.id,
                sourcePassIDs: [pass.id]
            )
#endif
        } ?? []
    }

    @available(iOS 26.0, *)
    private func recognizeDocumentLines(in image: CGImage) async throws -> [OCRRecognizedLine] {
        var request = RecognizeDocumentsRequest(.revision1)
        request.textRecognitionOptions.minimumTextHeightFraction = 0.008
        request.textRecognitionOptions.recognitionLanguages = [Locale.Language(identifier: "en-US")]
        request.textRecognitionOptions.useLanguageCorrection = true
        request.textRecognitionOptions.customWords = customWords
        request.textRecognitionOptions.maximumCandidateCount = 3
        request.barcodeDetectionOptions.enabled = false

        let handler = ImageRequestHandler(image)
        let documents = try await handler.perform(request)
        try Task.checkCancellation()

        return documents.flatMap { document in
            document.document.text.lines.compactMap { observation in
                Self.recognizedLine(
                    from: observation,
                    sourceID: "document-structure",
                    documentConfidence: document.confidence
                )
            }
        }
    }

    @available(iOS 26.0, *)
    private static func recognizedLine(
        from observation: RecognizedTextObservation,
        sourceID: String,
        documentConfidence: Float
    ) -> OCRRecognizedLine? {
#if DEBUG
        let candidateCount = 3
#else
        let candidateCount = 1
#endif
        let candidates = observation.topCandidates(candidateCount)
        guard let top = candidates.first else { return nil }
        let text = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        let region = OCRTextRegion(
            minX: Double(min(observation.topLeft.x, observation.bottomLeft.x)),
            minY: Double(min(observation.bottomLeft.y, observation.bottomRight.y)),
            width: Double(max(observation.topRight.x, observation.bottomRight.x) - min(observation.topLeft.x, observation.bottomLeft.x)),
            height: Double(max(observation.topLeft.y, observation.topRight.y) - min(observation.bottomLeft.y, observation.bottomRight.y))
        )
        let confidence = min(top.confidence, documentConfidence)

#if DEBUG
        let alts = candidates.dropFirst().map {
            OCRAlternativeCandidate(
                text: $0.string.trimmingCharacters(in: .whitespacesAndNewlines),
                confidence: $0.confidence
            )
        }
        return OCRRecognizedLine(
            text: text,
            confidence: confidence,
            region: region,
            sourceID: sourceID,
            sourcePassIDs: [sourceID],
            alternatives: alts
        )
#else
        return OCRRecognizedLine(
            text: text,
            confidence: confidence,
            region: region,
            sourceID: sourceID,
            sourcePassIDs: [sourceID]
        )
#endif
    }

    private static func defaultCustomWords() -> [String] {
        let lexiconWords = (try? NutritionLexicon.load().ocrCustomWords) ?? []
        let knowledgeWords = (try? SupplementKnowledgeService.load().ocrCustomWords) ?? []
        return Array(Set(supplementVocabulary + lexiconWords + knowledgeWords)).sorted()
    }

    private static func defaultPasses(usesLanguageCorrection: Bool) -> [VisionOCRPass] {
        [
            VisionOCRPass(
                id: "vn-original-accurate",
                variant: .original,
                recognitionLevel: .accurate,
                usesLanguageCorrection: usesLanguageCorrection,
                minimumTextHeight: 0.015
            ),
            VisionOCRPass(
                id: "vn-small-text",
                variant: .original,
                recognitionLevel: .accurate,
                usesLanguageCorrection: usesLanguageCorrection,
                minimumTextHeight: 0.008
            ),
            VisionOCRPass(
                id: "vn-contrast",
                variant: .contrast,
                recognitionLevel: .accurate,
                usesLanguageCorrection: true,
                minimumTextHeight: 0.010
            ),
            VisionOCRPass(
                id: "vn-sharpened-technical",
                variant: .sharpened,
                recognitionLevel: .accurate,
                usesLanguageCorrection: false,
                minimumTextHeight: 0.008
            )
        ]
    }

    private static func imageVariants(from image: CGImage) -> [OCRImageVariant: CGImage] {
        let input = CIImage(cgImage: image)
        let context = CIContext(options: [.useSoftwareRenderer: false])
        var variants: [OCRImageVariant: CGImage] = [.original: image]

        let contrast = input.applyingFilter(
            "CIColorControls",
            parameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 1.42,
                kCIInputBrightnessKey: 0.02
            ]
        )
        if let contrastImage = context.createCGImage(contrast, from: input.extent) {
            variants[.contrast] = contrastImage
        }

        let sharpenBase = variants[.contrast].map(CIImage.init(cgImage:)) ?? input
        let sharpened = sharpenBase.applyingFilter(
            "CISharpenLuminance",
            parameters: [kCIInputSharpnessKey: 0.75]
        )
        if let sharpenedImage = context.createCGImage(sharpened, from: input.extent) {
            variants[.sharpened] = sharpenedImage
        }

        return variants
    }

    private static let supplementVocabulary: [String] = [
        "Ascorbic", "ascorbic", "Bioflavonoids", "bioflavonoids",
        "Bifidobacterium", "Lactobacillus", "Lactococcus",
        "Bacillus", "Saccharomyces", "rhamnosus", "plantarum",
        "paracasei", "casei", "acidophilus", "brevis", "lactis",
        "longum", "coagulans", "boulardii", "Florafit",
        "FloraFIT", "HOWARU", "DSM", "HN001", "HN019", "BL-04",
        "Lpc-37", "Lp-115", "Bi-07", "Lbr-35", "BB-12",
        "CFU", "cfu", "IU", "mcg", "micrograms", "µg", "μg",
        "Selenomethionine", "selenium", "Eicosapentaenoic",
        "Docosahexaenoic", "Quercetin", "Rutoside", "Hesperidin",
        "Hypromellose", "N-Acetyl-L-Cysteine", "Acetyl-L-Cysteine",
        "NAC", "Glycinate", "dihydrate", "chelate", "elemental"
    ]
}

nonisolated private struct VisionOCRPass: Sendable {
    let id: String
    let variant: OCRImageVariant
    let recognitionLevel: LegacyTextRecognitionLevel
    let usesLanguageCorrection: Bool
    let minimumTextHeight: Float
}

nonisolated private enum OCRImageVariant: Hashable, Sendable {
    case original
    case contrast
    case sharpened
}

nonisolated private enum LegacyTextRecognitionLevel: Sendable {
    case accurate
    case fast

    var vnValue: VNRequestTextRecognitionLevel {
        switch self {
        case .accurate: .accurate
        case .fast: .fast
        }
    }
}

/// Extracts OCR text from images while preserving confidence metadata.
nonisolated struct OCRService: Sendable {
    private let recognizer: any OCRTextRecognizing
    private let maxImageDimension: Int

    init(
        recognizer: any OCRTextRecognizing = VisionTextRecognizer(),
        maxImageDimension: Int = 3_000
    ) {
        self.recognizer = recognizer
        self.maxImageDimension = maxImageDimension
    }

    /// Recognizes text from encoded image data after downsampling to the OCR size cap.
    @concurrent
    func recognizeText(in imageData: Data) async throws -> OCRResult {
        let image = try await downsampledImage(from: imageData)
        return try await recognizeText(in: image)
    }

    /// Recognizes text from an already decoded image.
    @concurrent
    func recognizeText(in image: CGImage) async throws -> OCRResult {
        try Task.checkCancellation()
        let imageQuality = OCRImageQualityAnalyzer().analyze(image)
        try Task.checkCancellation()

        let lines = try await recognizer.recognizedLines(in: image)
        let result = OCRResult(lines: lines, imageQuality: imageQuality)

        guard !result.allRecognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.ocrNoTextFound
        }

        guard !result.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.ocrLowConfidence(recognisedText: result.allRecognizedText)
        }

        guard result.hasSupplementLabelSignals else {
            throw AppError.ocrNoSupplementLabelFound
        }

        return result
    }

    @concurrent
    private func downsampledImage(from imageData: Data) async throws -> CGImage {
        try Task.checkCancellation()

        let options = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary

        guard let source = CGImageSourceCreateWithData(imageData as CFData, options) else {
            throw AppError.unknown(description: "Photo could not be decoded for text recognition.")
        }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxImageDimension
        ] as CFDictionary

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            throw AppError.unknown(description: "Photo could not be prepared for text recognition.")
        }

        return image
    }
}
