// ReferenceStandard.swift
// SuppliScan
//
// The three supported nutritional reference standards.
// Default is AU. Persisted per scan via ScanRecord.referenceStandard.

import Foundation

enum ReferenceStandard: String, Codable, Hashable, CaseIterable, Sendable {
    case au = "AU"   // NHMRC Nutrient Reference Values for Australia and New Zealand
    case us = "US"   // NIH/FDA Dietary Reference Intakes
    case eu = "EU"   // EFSA Nutrient Reference Values
}

extension ReferenceStandard {
    var displayName: String {
        switch self {
        case .au: "AU (NHMRC)"
        case .us: "US (NIH/FDA)"
        case .eu: "EU (EFSA)"
        }
    }

    var jsonFileName: String {
        switch self {
        case .au: "nrv_au"
        case .us: "nrv_us"
        case .eu: "nrv_eu"
        }
    }
}
