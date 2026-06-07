// AppError.swift
// SuppliScan
//
// All typed errors for the application. Every case maps to:
// - A user-facing xcstrings key (for localised display)
// - A defined recovery action (see ERROR_STATES.md)
// - A defined visual presentation (toast / inline / banner / full-screen)
//
// Errors are never silently swallowed. Log via Logger.suppliScan before presenting.

import Foundation

enum AppError: LocalizedError, Sendable {
    // MARK: OCR
    case ocrNoTextFound
    case ocrLowConfidence(recognisedText: String)
    case ocrCameraPermissionDenied

    // MARK: Parser
    case parserNoNutrientsExtracted
    case parserPartialExtraction(unresolved: Int) // count of unresolved lines

    // MARK: Reference Data
    case referenceDataLoadFailed
    case referenceDataNutrientNotFound(name: String)

    // MARK: Calculation
    case calculationUnitConversionRequired(nutrient: String, unit: String)
    case calculationUnsupportedUnit(nutrient: String, unit: String)

    // MARK: Form Quality / AI
    case formQualityAIUnavailable
    case formQualityAIResponseInvalid
    case aiServiceNetworkUnavailable
    case aiServiceTimeout
    case aiServiceRateLimited
    case aiServiceResponseMalformed

    // MARK: Persistence
    case persistenceSaveFailed(underlying: String)   // String, not Error, for Sendable
    case persistenceLoadFailed(underlying: String)
    case persistenceContainerInitFailed

    // MARK: Export
    case exportPDFGenerationFailed
    case exportShareFailed

    // MARK: General
    case unknown(description: String)
}

extension AppError {
    var errorDescription: String? {
        switch self {
        case .ocrNoTextFound:
            return "No text found on label. Try better lighting or hold the camera steadier."
        case .ocrLowConfidence:
            return "Some text was hard to read. Please review and correct the extracted nutrients."
        case .ocrCameraPermissionDenied:
            return "Camera access is needed to scan labels. Enable it in Settings."
        case .parserNoNutrientsExtracted:
            return "Couldn't identify any nutrients. This might not be a supplement facts panel."
        case .parserPartialExtraction:
            return nil // Not presented as an error — handled inline in ReviewView
        case .referenceDataLoadFailed:
            return "Reference data failed to load. Please reinstall the app."
        case .referenceDataNutrientNotFound:
            return nil // Handled inline in report — "No reference data"
        case .calculationUnitConversionRequired(let nutrient, _):
            return "Calculation error for \(nutrient) — unit conversion required."
        case .calculationUnsupportedUnit(let nutrient, let unit):
            return "Unit '\(unit)' is not supported for \(nutrient). Manual calculation required."
        case .formQualityAIUnavailable, .aiServiceNetworkUnavailable:
            return nil // Inline degradation only — no error dialog
        case .formQualityAIResponseInvalid, .aiServiceResponseMalformed,
             .aiServiceTimeout, .aiServiceRateLimited:
            return nil // Inline degradation only
        case .persistenceContainerInitFailed:
            return "History unavailable — storage error. Scans won't be saved this session."
        case .persistenceSaveFailed:
            return "Report couldn't be saved. It's still available this session."
        case .persistenceLoadFailed:
            return "History couldn't be loaded. Try closing and reopening."
        case .exportPDFGenerationFailed:
            return "PDF couldn't be created. Try again."
        case .exportShareFailed:
            return "Sharing failed. Try again."
        case .unknown(let description):
            return "An unexpected error occurred: \(description)"
        }
    }
}
