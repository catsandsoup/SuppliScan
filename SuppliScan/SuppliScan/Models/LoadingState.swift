// LoadingState.swift
// SuppliScan
//
// Generic async state enum used by all ViewModels.
// Eliminates the impossible state: isLoading=false, result=nil, error=nil.
// Views switch on LoadingState — never check a Bool + optional pair.

import Foundation

nonisolated enum LoadingState<T: Sendable>: Sendable {
    case idle
    case loading
    case loaded(T)
    case failed(AppError)
}

nonisolated extension LoadingState {
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var value: T? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var error: AppError? {
        if case .failed(let error) = self { return error }
        return nil
    }
}
