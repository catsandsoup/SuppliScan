// OCRServiceTests.swift
// SuppliScanTests

import CoreGraphics
import Testing
@testable import SuppliScan

struct OCRServiceTests {
    @Test func returnsLowConfidenceMetadataForReview() async throws {
        let service = OCRService(recognizer: StubRecognizer(lines: [
            OCRRecognizedLine(
                text: "Vitamin D 1000IU",
                confidence: 0.41,
                region: OCRTextRegion(minX: 0, minY: 0.7, width: 0.8, height: 0.1)
            )
        ]))

        let result = try await service.recognizeText(in: try makeImage())

        #expect(result.rawText == "Vitamin D 1000IU")
        #expect(result.hasLowConfidenceText)
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
