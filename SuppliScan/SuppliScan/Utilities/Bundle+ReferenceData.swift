// Bundle+ReferenceData.swift
// SuppliScan
//
// Typed accessors for bundled reference data JSON files.
// All files live in Resources/ReferenceData/.

import Foundation

nonisolated extension Bundle {
    /// Load and decode a bundled JSON file from Resources/ReferenceData/.
    func referenceData<T: Decodable>(named name: String, as type: T.Type) throws -> T {
        guard let url = self.url(forResource: name, withExtension: "json") else {
            throw BundleError.fileNotFound(name: name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }

    /// Load raw Data from Resources/ReferenceData/.
    func referenceDataRaw(named name: String) throws -> Data {
        guard let url = self.url(forResource: name, withExtension: "json") else {
            throw BundleError.fileNotFound(name: name)
        }
        return try Data(contentsOf: url)
    }
}

// MARK: - BundleError

enum BundleError: LocalizedError {
    case fileNotFound(name: String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "Bundled resource '\(name).json' not found. This is a build error — file may be missing from the target."
        }
    }
}
