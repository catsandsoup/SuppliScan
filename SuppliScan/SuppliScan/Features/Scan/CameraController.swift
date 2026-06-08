// CameraController.swift
// SuppliScan
// Manages AVCaptureSession lifecycle and still-photo capture.
// Session start/stop run on a detached task to avoid blocking the main thread.
// Gracefully handles permission denied and no-camera-device (Simulator).

import AVFoundation
import SwiftUI

// AVFoundation session types are designed for cross-thread use; @unchecked Sendable
// conformances let Swift 6 strict concurrency accept them in Task.detached closures.
extension AVCaptureSession:     @unchecked Sendable {}
extension AVCapturePhotoOutput: @unchecked Sendable {}
extension AVCaptureDevice:      @unchecked Sendable {}

@Observable
@MainActor
final class CameraController: NSObject {

    enum AuthState {
        case unknown, authorized, denied, unavailable
    }

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()

    private(set) var authState: AuthState = .unknown
    private(set) var isRunning = false

    private var captureContinuation: CheckedContinuation<Data, any Error>?

    // MARK: - Start

    func requestAndStart() async {
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil else {
            authState = .unavailable
            return
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            await configure()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authState = granted ? .authorized : .denied
            if granted { await configure() }
        case .denied, .restricted:
            authState = .denied
        @unknown default:
            authState = .denied
        }
    }

    private func configure() async {
        let s = session
        let out = photoOutput
        // Task.detached so startRunning() doesn't block the main thread.
        // AVCaptureSession/@unchecked Sendable conformance above permits the capture.
        await Task.detached(priority: .userInitiated) {
            guard !s.isRunning else { return }
            s.beginConfiguration()
            s.sessionPreset = .photo
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                s.canAddInput(input)
            else {
                s.commitConfiguration()
                return
            }
            s.addInput(input)
            if s.canAddOutput(out) { s.addOutput(out) }
            s.commitConfiguration()
            s.startRunning()
        }.value

        authState = .authorized
        isRunning = session.isRunning
    }

    // MARK: - Stop

    func stop() {
        let s = session
        // stopRunning() can block; detach to keep main thread free.
        Task.detached(priority: .userInitiated) { s.stopRunning() }
        isRunning = false
    }

    // MARK: - Capture

    func capturePhoto() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            captureContinuation = continuation
            photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        // Extract Data synchronously here (nonisolated context) so we never
        // carry AVCapturePhoto — a non-Sendable type — across the actor boundary.
        let result: Result<Data, any Error>
        if let error {
            result = .failure(error)
        } else if let data = photo.fileDataRepresentation() {
            result = .success(data)
        } else {
            result = .failure(AppError.ocrNoTextFound)
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            switch result {
            case .success(let data):   captureContinuation?.resume(returning: data)
            case .failure(let error):  captureContinuation?.resume(throwing: error)
            }
            captureContinuation = nil
        }
    }
}
