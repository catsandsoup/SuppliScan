// OCRImageQualityAnalyzer.swift
// SuppliScan
//
// Deterministic camera-frame risk scoring for OCR. These values do not prove
// the text is wrong; they explain when recognition should be treated cautiously.

import CoreGraphics
import Foundation

nonisolated enum OCRImageQualityIssue: String, Codable, CaseIterable, Hashable, Sendable {
    case analysisUnavailable
    case lowResolution
    case underexposed
    case overexposed
    case glareLikely
    case lowContrast
    case possibleBlur
}

nonisolated struct OCRImageQualityReport: Codable, Hashable, Sendable {
    let pixelWidth: Int
    let pixelHeight: Int
    let sampledPixelCount: Int
    let meanLuminance: Double
    let luminanceStandardDeviation: Double
    let darkPixelRatio: Double
    let brightPixelRatio: Double
    let clippedHighlightRatio: Double
    let sharpnessScore: Double
    let issues: Set<OCRImageQualityIssue>

    var isRiskyForOCR: Bool {
        !issues.isEmpty
    }
}

nonisolated struct OCRImageQualityAnalyzer: Sendable {
    private let sampleEdgeLength = 128

    func analyze(_ image: CGImage) -> OCRImageQualityReport {
        let sampleWidth = min(sampleEdgeLength, max(1, image.width))
        let sampleHeight = min(sampleEdgeLength, max(1, image.height))
        let bytesPerPixel = 4
        let bytesPerRow = sampleWidth * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: sampleHeight * bytesPerRow)

        let didDraw = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let baseAddress = buffer.baseAddress else { return false }

            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
                | CGBitmapInfo.byteOrder32Big.rawValue
            guard let context = CGContext(
                data: baseAddress,
                width: sampleWidth,
                height: sampleHeight,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo
            ) else {
                return false
            }

            context.interpolationQuality = .high
            context.draw(
                image,
                in: CGRect(
                    x: 0,
                    y: 0,
                    width: CGFloat(sampleWidth),
                    height: CGFloat(sampleHeight)
                )
            )
            return true
        }

        guard didDraw else {
            var issues: Set<OCRImageQualityIssue> = [.analysisUnavailable]
            if image.width < 900 || image.height < 900 {
                issues.insert(.lowResolution)
            }

            return OCRImageQualityReport(
                pixelWidth: image.width,
                pixelHeight: image.height,
                sampledPixelCount: 0,
                meanLuminance: 0,
                luminanceStandardDeviation: 0,
                darkPixelRatio: 0,
                brightPixelRatio: 0,
                clippedHighlightRatio: 0,
                sharpnessScore: 0,
                issues: issues
            )
        }

        return report(
            imageWidth: image.width,
            imageHeight: image.height,
            sampleWidth: sampleWidth,
            sampleHeight: sampleHeight,
            pixels: pixels
        )
    }

    private func report(
        imageWidth: Int,
        imageHeight: Int,
        sampleWidth: Int,
        sampleHeight: Int,
        pixels: [UInt8]
    ) -> OCRImageQualityReport {
        let sampleCount = sampleWidth * sampleHeight
        var luminance = [Double]()
        luminance.reserveCapacity(sampleCount)

        var sum = 0.0
        var squaredSum = 0.0
        var darkCount = 0
        var brightCount = 0
        var clippedHighlightCount = 0

        for offset in stride(from: 0, to: pixels.count, by: 4) {
            let red = Double(pixels[offset]) / 255.0
            let green = Double(pixels[offset + 1]) / 255.0
            let blue = Double(pixels[offset + 2]) / 255.0
            let value = 0.2126 * red + 0.7152 * green + 0.0722 * blue

            luminance.append(value)
            sum += value
            squaredSum += value * value

            if value < 0.08 { darkCount += 1 }
            if value > 0.92 { brightCount += 1 }
            if value > 0.985 { clippedHighlightCount += 1 }
        }

        let mean = sum / Double(sampleCount)
        let variance = max(0, squaredSum / Double(sampleCount) - mean * mean)
        let standardDeviation = sqrt(variance)
        let darkRatio = Double(darkCount) / Double(sampleCount)
        let brightRatio = Double(brightCount) / Double(sampleCount)
        let clippedHighlightRatio = Double(clippedHighlightCount) / Double(sampleCount)
        let sharpness = sharpnessScore(
            luminance: luminance,
            sampleWidth: sampleWidth,
            sampleHeight: sampleHeight
        )
        let issues = qualityIssues(
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            mean: mean,
            standardDeviation: standardDeviation,
            darkRatio: darkRatio,
            brightRatio: brightRatio,
            clippedHighlightRatio: clippedHighlightRatio,
            sharpness: sharpness
        )

        return OCRImageQualityReport(
            pixelWidth: imageWidth,
            pixelHeight: imageHeight,
            sampledPixelCount: sampleCount,
            meanLuminance: mean,
            luminanceStandardDeviation: standardDeviation,
            darkPixelRatio: darkRatio,
            brightPixelRatio: brightRatio,
            clippedHighlightRatio: clippedHighlightRatio,
            sharpnessScore: sharpness,
            issues: issues
        )
    }

    private func qualityIssues(
        imageWidth: Int,
        imageHeight: Int,
        mean: Double,
        standardDeviation: Double,
        darkRatio: Double,
        brightRatio: Double,
        clippedHighlightRatio: Double,
        sharpness: Double
    ) -> Set<OCRImageQualityIssue> {
        var issues = Set<OCRImageQualityIssue>()

        if min(imageWidth, imageHeight) < 900 || imageWidth * imageHeight < 1_200_000 {
            issues.insert(.lowResolution)
        }
        if mean < 0.23 || darkRatio > 0.55 {
            issues.insert(.underexposed)
        }
        if mean > 0.86 && brightRatio > 0.55 {
            issues.insert(.overexposed)
        }
        if standardDeviation < 0.11 {
            issues.insert(.lowContrast)
        }
        if clippedHighlightRatio > 0.06 && brightRatio > 0.12 && mean < 0.86 {
            issues.insert(.glareLikely)
        }
        if sharpness < 0.018 && standardDeviation > 0.10 {
            issues.insert(.possibleBlur)
        }

        return issues
    }

    private func sharpnessScore(
        luminance: [Double],
        sampleWidth: Int,
        sampleHeight: Int
    ) -> Double {
        guard sampleWidth > 1 || sampleHeight > 1 else { return 0 }

        var totalDifference = 0.0
        var comparisonCount = 0

        for y in 0..<sampleHeight {
            for x in 0..<sampleWidth {
                let index = y * sampleWidth + x
                let value = luminance[index]

                if x + 1 < sampleWidth {
                    totalDifference += abs(value - luminance[index + 1])
                    comparisonCount += 1
                }
                if y + 1 < sampleHeight {
                    totalDifference += abs(value - luminance[index + sampleWidth])
                    comparisonCount += 1
                }
            }
        }

        guard comparisonCount > 0 else { return 0 }
        return totalDifference / Double(comparisonCount)
    }
}
