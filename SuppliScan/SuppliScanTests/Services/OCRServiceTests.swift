// OCRServiceTests.swift
// SuppliScanTests

import CoreGraphics
import Testing
@testable import SuppliScan

struct OCRServiceTests {
    @Test func returnsLowConfidenceMetadataForReview() async throws {
        let result = OCRResult(lines: [
            OCRRecognizedLine(
                text: "Vitamin D 1000IU",
                confidence: 0.41,
                region: OCRTextRegion(minX: 0, minY: 0.7, width: 0.8, height: 0.1)
            )
        ])

        #expect(result.rawText.isEmpty)
        #expect(result.allRecognizedText == "Vitamin D 1000IU")
        #expect(result.hasLowConfidenceText)
        #expect(result.rejectedLines.count == 1)
    }

    @Test func throwsWhenOnlyLowConfidenceTextRemains() async throws {
        let service = OCRService(recognizer: StubRecognizer(lines: [
            OCRRecognizedLine(
                text: "Aracted by your hoait prot2 yonal.",
                confidence: 0.32,
                region: OCRTextRegion(minX: 0.1, minY: 0.7, width: 0.8, height: 0.1)
            )
        ]))

        do {
            _ = try await service.recognizeText(in: try makeImage())
            Issue.record("Expected low-confidence OCR error")
        } catch AppError.ocrLowConfidence(let recognisedText) {
            #expect(recognisedText == "Aracted by your hoait prot2 yonal.")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func throwsWhenNoTextIsFound() async throws {
        let service = OCRService(recognizer: StubRecognizer(lines: []))

        do {
            _ = try await service.recognizeText(in: try makeImage())
            Issue.record("Expected no-text error")
        } catch AppError.ocrNoTextFound {
            #expect(true)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func joinsMultilineTextInVisualReadingOrder() async throws {
        let service = OCRService(recognizer: StubRecognizer(lines: [
            OCRRecognizedLine(
                text: "Magnesium 300mg",
                confidence: 0.93,
                region: OCRTextRegion(minX: 0.1, minY: 0.2, width: 0.8, height: 0.1)
            ),
            OCRRecognizedLine(
                text: "Supplement Facts",
                confidence: 0.95,
                region: OCRTextRegion(minX: 0.1, minY: 0.8, width: 0.8, height: 0.1)
            ),
            OCRRecognizedLine(
                text: "Vitamin C 500mg",
                confidence: 0.96,
                region: OCRTextRegion(minX: 0.1, minY: 0.5, width: 0.8, height: 0.1)
            )
        ]))

        let result = try await service.recognizeText(in: try makeImage())

        #expect(result.rawText == """
            Supplement Facts
            Vitamin C 500mg
            Magnesium 300mg
            """)
    }

    @Test func throwsWhenTextDoesNotLookLikeSupplementLabel() async throws {
        let service = OCRService(recognizer: StubRecognizer(lines: [
            OCRRecognizedLine(
                text: "Clinically researched formula",
                confidence: 0.96,
                region: OCRTextRegion(minX: 0.1, minY: 0.7, width: 0.8, height: 0.1)
            ),
            OCRRecognizedLine(
                text: "Recommended by practitioners",
                confidence: 0.94,
                region: OCRTextRegion(minX: 0.1, minY: 0.5, width: 0.8, height: 0.1)
            )
        ]))

        do {
            _ = try await service.recognizeText(in: try makeImage())
            Issue.record("Expected non-label OCR error")
        } catch AppError.ocrNoSupplementLabelFound {
            #expect(true)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func focusesParserTextOnSupplementFactsPanelOverMarketingAndDirections() async throws {
        let service = OCRService(recognizer: StubRecognizer(lines: [
            OCRRecognizedLine(
                text: "Ultra Calm Sleep Support",
                confidence: 0.96,
                region: OCRTextRegion(minX: 0.1, minY: 0.88, width: 0.7, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "Clinically researched practitioner formula",
                confidence: 0.95,
                region: OCRTextRegion(minX: 0.1, minY: 0.80, width: 0.8, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "Supplement Facts",
                confidence: 0.97,
                region: OCRTextRegion(minX: 0.1, minY: 0.68, width: 0.5, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "Amount Per Serving",
                confidence: 0.94,
                region: OCRTextRegion(minX: 0.1, minY: 0.60, width: 0.5, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "Magnesium glycinate 300mg",
                confidence: 0.93,
                region: OCRTextRegion(minX: 0.1, minY: 0.52, width: 0.6, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "Zinc 15mg",
                confidence: 0.94,
                region: OCRTextRegion(minX: 0.1, minY: 0.44, width: 0.4, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "Directions: take 2 capsules daily",
                confidence: 0.96,
                region: OCRTextRegion(minX: 0.1, minY: 0.30, width: 0.7, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "Distributed by Example Health Pty Ltd",
                confidence: 0.95,
                region: OCRTextRegion(minX: 0.1, minY: 0.20, width: 0.8, height: 0.05)
            )
        ]))

        let result = try await service.recognizeText(in: try makeImage())

        #expect(result.rawText == """
            Supplement Facts
            Amount Per Serving
            Magnesium glycinate 300mg
            Zinc 15mg
            """)
        #expect(result.allRecognizedText.contains("Clinically researched practitioner formula"))
        #expect(result.rawText.contains("Clinically researched") == false)
        #expect(result.rawText.contains("Directions") == false)
        #expect(result.rawText.contains("Distributed by") == false)
        #expect(result.quality.panelConfidence >= 0.70)
        #expect(result.quality.excludedNonPanelLineCount == 4)
        #expect(result.quality.hasAmbiguousPanelBoundary == false)
    }

    @Test func keepsIngredientLikeRowsOutsidePanelWhenBoundaryIsUnclear() async throws {
        let service = OCRService(recognizer: StubRecognizer(lines: [
            OCRRecognizedLine(
                text: "Supplement Facts",
                confidence: 0.97,
                region: OCRTextRegion(minX: 0.1, minY: 0.78, width: 0.5, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "Magnesium glycinate 300mg",
                confidence: 0.94,
                region: OCRTextRegion(minX: 0.1, minY: 0.68, width: 0.6, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "Warnings: consult your doctor before use",
                confidence: 0.96,
                region: OCRTextRegion(minX: 0.1, minY: 0.50, width: 0.8, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "Selenium 150mcg",
                confidence: 0.92,
                region: OCRTextRegion(minX: 0.1, minY: 0.40, width: 0.5, height: 0.05)
            )
        ]))

        let result = try await service.recognizeText(in: try makeImage())

        #expect(result.rawText == """
            Supplement Facts
            Magnesium glycinate 300mg
            Selenium 150mcg
            """)
        #expect(result.rawText.contains("Warnings") == false)
        #expect(result.panelReconstruction.rows.contains { row in
            row.line.text == "Selenium 150mcg" && row.section == .ingredientLikeOutsidePanel
        })
        #expect(result.quality.hasAmbiguousPanelBoundary)
        #expect(result.hasLowConfidenceText)
    }

    @Test func mergesAmountColumnFragmentsOnSameVisualRow() async throws {
        let service = OCRService(recognizer: StubRecognizer(lines: [
            OCRRecognizedLine(
                text: "Calcium ascorbate dihydrate",
                confidence: 0.92,
                region: OCRTextRegion(minX: 0.1, minY: 0.5, width: 0.5, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "605.3mg",
                confidence: 0.91,
                region: OCRTextRegion(minX: 0.78, minY: 0.502, width: 0.12, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "Each tablet contains",
                confidence: 0.95,
                region: OCRTextRegion(minX: 0.1, minY: 0.7, width: 0.6, height: 0.05)
            )
        ]))

        let result = try await service.recognizeText(in: try makeImage())

        #expect(result.rawText == """
            Each tablet contains
            Calcium ascorbate dihydrate 605.3mg
            """)
    }

    @Test func mergesProbioticCFUFragmentsOnSameVisualRow() async throws {
        let service = OCRService(recognizer: StubRecognizer(lines: [
            OCRRecognizedLine(
                text: "Lactobacillus rhamnosus GG",
                confidence: 0.92,
                region: OCRTextRegion(minX: 0.1, minY: 0.5, width: 0.55, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "6 billion CFU",
                confidence: 0.91,
                region: OCRTextRegion(minX: 0.76, minY: 0.502, width: 0.14, height: 0.05)
            )
        ]))

        let result = try await service.recognizeText(in: try makeImage())

        #expect(result.rawText == "Lactobacillus rhamnosus GG 6 billion CFU")
    }

    @Test func splitsTwoIngredientPairsOnSameVisualRow() async throws {
        let service = OCRService(recognizer: StubRecognizer(lines: [
            OCRRecognizedLine(
                text: "Supplement Facts",
                confidence: 0.95,
                region: OCRTextRegion(minX: 0.1, minY: 0.8, width: 0.4, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "Magnesium ascorbate",
                confidence: 0.92,
                region: OCRTextRegion(minX: 0.08, minY: 0.5, width: 0.28, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "210mg",
                confidence: 0.91,
                region: OCRTextRegion(minX: 0.38, minY: 0.502, width: 0.09, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "Magnesium glycinate dihydrate",
                confidence: 0.90,
                region: OCRTextRegion(minX: 0.55, minY: 0.501, width: 0.28, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "104mg",
                confidence: 0.90,
                region: OCRTextRegion(minX: 0.86, minY: 0.503, width: 0.08, height: 0.05)
            )
        ]))

        let result = try await service.recognizeText(in: try makeImage())

        #expect(result.rawText == """
            Supplement Facts
            Magnesium ascorbate 210mg
            Magnesium glycinate dihydrate 104mg
            """)
        #expect(result.lines.filter { $0.sourceLineCount == 2 }.count == 2)
    }

    @Test func reconcilesSupportedLinesAcrossMultipleRecognitionPasses() async throws {
        let result = OCRResult(lines: [
            OCRRecognizedLine(
                text: "Magnesium glycinate 300mg",
                confidence: 0.63,
                region: OCRTextRegion(minX: 0.1, minY: 0.5, width: 0.7, height: 0.05),
                sourceID: "vn-original",
                sourcePassIDs: ["vn-original"]
            ),
            OCRRecognizedLine(
                text: "Magnesium glycinate 300mg",
                confidence: 0.67,
                region: OCRTextRegion(minX: 0.102, minY: 0.502, width: 0.7, height: 0.05),
                sourceID: "vn-contrast",
                sourcePassIDs: ["vn-contrast"]
            ),
            OCRRecognizedLine(
                text: "Supplement Facts",
                confidence: 0.93,
                region: OCRTextRegion(minX: 0.1, minY: 0.8, width: 0.5, height: 0.05),
                sourceID: "vn-original",
                sourcePassIDs: ["vn-original"]
            )
        ])

        let magnesium = try #require(result.lines.first { $0.text == "Magnesium glycinate 300mg" })
        #expect(magnesium.supportCount == 2)
        #expect(magnesium.qualityFlags.contains(.lowConfidence))
        #expect(result.quality.supportedLineCount == 1)
        #expect(result.quality.recognitionPassCount == 2)
        #expect(result.rawText.contains("Magnesium glycinate 300mg"))
    }

    @Test func flagsConflictingOCRWitnessesInsteadOfSilentlyChoosing() throws {
        let result = OCRResult(lines: [
            OCRRecognizedLine(
                text: "Selenium 150mcg",
                confidence: 0.72,
                region: OCRTextRegion(minX: 0.1, minY: 0.5, width: 0.5, height: 0.05),
                sourceID: "vn-original",
                sourcePassIDs: ["vn-original"]
            ),
            OCRRecognizedLine(
                text: "Selenium 150mg",
                confidence: 0.70,
                region: OCRTextRegion(minX: 0.102, minY: 0.501, width: 0.5, height: 0.05),
                sourceID: "vn-sharpened",
                sourcePassIDs: ["vn-sharpened"]
            ),
            OCRRecognizedLine(
                text: "Supplement Facts",
                confidence: 0.93,
                region: OCRTextRegion(minX: 0.1, minY: 0.8, width: 0.5, height: 0.05),
                sourceID: "vn-original",
                sourcePassIDs: ["vn-original"]
            )
        ])

        let selenium = try #require(result.recognizedLines.first { $0.text.hasPrefix("Selenium") })
        #expect(selenium.qualityFlags.contains(.conflictingCandidates))
        #expect(result.hasLowConfidenceText)
        #expect(result.quality.conflictingLineCount == 1)
    }

    @Test func flagsLowContrastCaptureAsOCRRisk() async throws {
        let service = OCRService(recognizer: StubRecognizer(lines: [
            OCRRecognizedLine(
                text: "Supplement Facts",
                confidence: 0.96,
                region: OCRTextRegion(minX: 0.1, minY: 0.8, width: 0.5, height: 0.05)
            ),
            OCRRecognizedLine(
                text: "Magnesium glycinate 300mg",
                confidence: 0.94,
                region: OCRTextRegion(minX: 0.1, minY: 0.5, width: 0.7, height: 0.05)
            )
        ]))

        let result = try await service.recognizeText(in: try makeSolidImage(gray: 142))
        let report = try #require(result.quality.imageQuality)

        #expect(report.issues.contains(.lowContrast))
        #expect(report.isRiskyForOCR)
        #expect(result.hasLowConfidenceText)
    }

    @Test func flagsGlareLikeClippedHighlightsAsOCRRisk() throws {
        let report = OCRImageQualityAnalyzer().analyze(try makeGlareImage())

        #expect(report.issues.contains(.glareLikely))
        #expect(report.clippedHighlightRatio > 0.06)
        #expect(report.isRiskyForOCR)
    }

    @Test func flagsSmoothHighContrastCaptureAsPossibleBlur() throws {
        let report = OCRImageQualityAnalyzer().analyze(try makeHorizontalGradientImage())

        #expect(report.issues.contains(.possibleBlur))
        #expect(report.luminanceStandardDeviation > 0.10)
        #expect(report.sharpnessScore < 0.018)
    }
}

private struct StubRecognizer: OCRTextRecognizing {
    let lines: [OCRRecognizedLine]

    func recognizedLines(in image: CGImage) async throws -> [OCRRecognizedLine] {
        lines
    }
}

private func makeImage() throws -> CGImage {
    try makeSolidImage(width: 1, height: 1, gray: 255)
}

private func makeSolidImage(
    width: Int = 1_200,
    height: Int = 1_200,
    gray: UInt8
) throws -> CGImage {
    try makeTestImage(width: width, height: height) { context in
        let value = CGFloat(gray) / 255.0
        context.setFillColor(red: value, green: value, blue: value, alpha: 1)
        context.fill(
            CGRect(
                x: 0,
                y: 0,
                width: CGFloat(width),
                height: CGFloat(height)
            )
        )
    }
}

private func makeGlareImage(width: Int = 1_200, height: Int = 1_200) throws -> CGImage {
    try makeTestImage(width: width, height: height) { context in
        context.setFillColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1)
        context.fill(
            CGRect(
                x: 0,
                y: 0,
                width: CGFloat(width),
                height: CGFloat(height)
            )
        )

        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(
            CGRect(
                x: CGFloat(width * 5 / 8),
                y: CGFloat(height / 6),
                width: CGFloat(width / 5),
                height: CGFloat(height * 2 / 3)
            )
        )
    }
}

private func makeHorizontalGradientImage(
    width: Int = 1_200,
    height: Int = 1_200
) throws -> CGImage {
    try makeTestImage(width: width, height: height) { context in
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            CGColor(red: 0, green: 0, blue: 0, alpha: 1),
            CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        ] as CFArray
        let locations: [CGFloat] = [0, 1]
        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors,
            locations: locations
        ) else {
            return
        }

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: CGFloat(width), y: 0),
            options: []
        )
    }
}

private func makeTestImage(
    width: Int,
    height: Int,
    drawing: (CGContext) -> Void
) throws -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        throw AppError.unknown(description: "Test image creation failed.")
    }

    drawing(context)

    guard let image = context.makeImage() else {
        throw AppError.unknown(description: "Test image creation failed.")
    }

    return image
}
