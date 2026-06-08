// OCRService.swift
// SuppliScan
//
// Vision OCR boundary. The service returns raw recognized text and confidence
// metadata only; parsing and clinical calculations stay in separate services.

import CoreGraphics
import Foundation
import ImageIO
import Vision

/// Recognizes text lines from a downsampled image.
nonisolated protocol OCRTextRecognizing: Sendable {
    func recognizedLines(in image: CGImage) async throws -> [OCRRecognizedLine]
}

/// Runs Vision text recognition off the caller actor.
nonisolated struct VisionTextRecognizer: OCRTextRecognizing {
    @concurrent
    func recognizedLines(in image: CGImage) async throws -> [OCRRecognizedLine] {
        try Task.checkCancellation()

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = false
        request.customWords = Self.supplementVocabulary
        request.minimumTextHeight = 0.015

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        try Task.checkCancellation()

        return request.results?.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }

            let bounds = observation.boundingBox
            return OCRRecognizedLine(
                text: text,
                confidence: candidate.confidence,
                region: OCRTextRegion(
                    minX: bounds.minX,
                    minY: bounds.minY,
                    width: bounds.width,
                    height: bounds.height
                )
            )
        } ?? []
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

/// Extracts OCR text from images while preserving confidence metadata.
nonisolated struct OCRService: Sendable {
    private let recognizer: any OCRTextRecognizing
    private let maxImageDimension: Int

    init(
        recognizer: any OCRTextRecognizing = VisionTextRecognizer(),
        maxImageDimension: Int = 2_000
    ) {
        self.recognizer = recognizer
        self.maxImageDimension = maxImageDimension
    }

    /// Recognizes text from encoded image data after downsampling to the OCR size cap.
    func recognizeText(in imageData: Data) async throws -> OCRResult {
        let image = try await downsampledImage(from: imageData)
        return try await recognizeText(in: image)
    }

    /// Recognizes text from an already decoded image.
    func recognizeText(in image: CGImage) async throws -> OCRResult {
        let lines = try await recognizer.recognizedLines(in: image)
        let result = OCRResult(lines: lines)

        guard !result.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.ocrNoTextFound
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
