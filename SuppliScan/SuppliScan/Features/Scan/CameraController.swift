// CameraController.swift
// SuppliScan
// Manages AVCaptureSession lifecycle and still-photo capture.
// Session start/stop run on a detached task to avoid blocking the main thread.
// Gracefully handles permission denied and no-camera-device (Simulator).

@preconcurrency import AVFoundation
import SwiftUI

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

    private var isSessionConfigured = false
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
        let needsInputSetup = !isSessionConfigured

        await Task.detached(priority: .userInitiated) {
            if needsInputSetup {
                // Inputs are added exactly once — re-adding them on subsequent
                // tab-switches causes canAddInput to return false, preventing startRunning.
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
            }
            if !s.isRunning {
                s.startRunning()
            }
        }.value

        isSessionConfigured = true
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
