// ScanViewModel.swift
// SuppliScan

import Foundation

@MainActor
@Observable
final class ScanViewModel {
    var rawText = ""
    var loadingState: LoadingState<OCRResult> = .idle
    var reviewWarning: AppError?
    var isShowingError = false
    var capturedImageData: Data?

    private(set) var parseResult = ParseResult(entries: [], extractedServing: nil)
    private(set) var pendingDestination: AppDestination?

    @ObservationIgnored private var ocrService: OCRService
    @ObservationIgnored private var parser: ParserService
    @ObservationIgnored private var ocrTask: Task<Void, Never>?

    init(
        ocrService: OCRService = OCRService(),
        parser: ParserService = ParserService()
    ) {
        self.ocrService = ocrService
        self.parser = parser
    }

    func configure(ocrService: OCRService, parser: ParserService) {
        self.ocrService = ocrService
        self.parser = parser
    }

    func processPhotoData(_ data: Data) {
        ocrTask?.cancel()
        loadingState = .loading
        reviewWarning = nil
        isShowingError = false

        ocrTask = Task { @MainActor [weak self, ocrService, parser, data] in
            do {
                let result = try await ocrService.recognizeText(in: data)
                try Task.checkCancellation()

                let parseResult = parser.parse(result.rawText)
                self?.rawText = result.rawText
                self?.parseResult = parseResult
                self?.reviewWarning = result.hasLowConfidenceText
                    ? .ocrLowConfidence(recognisedText: result.rawText)
                    : nil
                self?.loadingState = .loaded(result)

#if DEBUG
                let scanID = UUID().uuidString
                let decisions = parser.debugDecisions(for: result.rawText)
                let bundle = OCRDebugBundle(
                    scanID: scanID,
                    capturedAt: ISO8601DateFormatter().string(from: Date()),
                    rawText: result.rawText,
                    rawObservations: result.lines.map { line in
                        OCRDebugObservation(
                            text: line.text,
                            confidence: line.confidence,
                            boundingBox: OCRDebugBBox(
                                minX: line.region.minX,
                                minY: line.region.minY,
                                width: line.region.width,
                                height: line.region.height
                            ),
                            alternatives: line.alternatives.map {
                                OCRDebugCandidate(text: $0.text, confidence: $0.confidence)
                            }
                        )
                    },
                    mergedRows: result.lines.map { OCRDebugMergedRow(text: $0.text, confidence: $0.confidence, mergedFromCount: 1) },
                    parserDecisions: decisions
                )
                OCRDebugWriter.write(bundle)
#endif

                // Brief pause so the "Label detected" badge renders before navigating
                try await Task.sleep(for: .milliseconds(700))
                self?.navigateToReview()
            } catch is CancellationError {
                self?.loadingState = .idle
            } catch let error as AppError {
                self?.loadingState = .failed(error)
                self?.isShowingError = true
            } catch {
                let appError = AppError.unknown(description: error.localizedDescription)
                self?.loadingState = .failed(appError)
                self?.isShowingError = true
            }
        }
    }

    func parseEditedText() {
        let trimmedText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            loadingState = .failed(.ocrNoTextFound)
            isShowingError = true
            return
        }

        parseResult = parser.parse(trimmedText)
        reviewWarning = nil
        loadingState = .idle
    }

    func handlePhotoImportFailure(_ error: Error) {
        let appError = error as? AppError ?? AppError.unknown(description: error.localizedDescription)
        loadingState = .failed(appError)
        isShowingError = true
    }

    func navigateToReview() {
        let trimmedText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            loadingState = .failed(.ocrNoTextFound)
            isShowingError = true
            return
        }

        if parseResult.entries.isEmpty {
            parseResult = parser.parse(trimmedText)
        }

        pendingDestination = .review(
            entries: parseResult.entries,
            serving: parseResult.extractedServing
        )
    }

    func consumePendingDestination() -> AppDestination? {
        defer { pendingDestination = nil }
        return pendingDestination
    }

    func cancel() {
        ocrTask?.cancel()
        ocrTask = nil
    }

    isolated deinit {
        ocrTask?.cancel()
    }
}
