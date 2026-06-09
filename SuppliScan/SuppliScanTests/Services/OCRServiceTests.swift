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
}

private struct StubRecognizer: OCRTextRecognizing {
    let lines: [OCRRecognizedLine]

    func recognizedLines(in image: CGImage) async throws -> [OCRRecognizedLine] {
        lines
    }
}

private func makeImage() throws -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    guard let context = CGContext(
        data: nil,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ), let image = context.makeImage() else {
        throw AppError.unknown(description: "Test image creation failed.")
    }

    return image
}
