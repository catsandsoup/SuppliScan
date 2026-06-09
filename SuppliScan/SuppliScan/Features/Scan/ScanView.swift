// ScanView.swift
// SuppliScan
// Live camera viewfinder. Full-screen camera with shutter button and photo-library
// fallback. Falls back to import-only in the Simulator (no camera device).
// Uses only SwiftUI + AVFoundation. UIKit entry point is UIViewRepresentable in
// CameraPreviewView — necessary because AVCaptureVideoPreviewLayer requires UIView.

import AVFoundation
import PhotosUI
import SwiftUI

struct ScanView: View {
    @Environment(NavigationRouter.self) private var router
    @Environment(AppDependencies.self) private var dependencies: AppDependencies?
    @Environment(\.openURL) private var openURL

    @State private var viewModel = ScanViewModel()
    @State private var camera = CameraController()
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            cameraLayer
            overlayLayer
        }
        .navigationTitle("Scan Label")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.black.opacity(0.45), for: .navigationBar)
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: captureTriggered)
        .task {
            guard let dependencies else {
                print("[SuppliScan] DIAGNOSTIC: ScanView AppDependencies missing from environment")
                return
            }
            viewModel.configure(
                ocrService: dependencies.ocrService,
                parser: dependencies.parserService
            )
            await camera.requestAndStart()
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                do {
                    guard let data = try await newItem.loadTransferable(type: Data.self) else {
                        throw AppError.unknown(description: "Photo could not be loaded.")
                    }
                    selectedItem = nil
                    viewModel.capturedImageData = data
                    viewModel.processPhotoData(data)
                } catch {
                    selectedItem = nil
                    viewModel.handlePhotoImportFailure(error)
                }
            }
        }
        .onChange(of: viewModel.pendingDestination) {
            guard let dest = viewModel.consumePendingDestination() else { return }
            router.navigate(to: dest)
        }
        .alert("Scan Failed", isPresented: $viewModel.isShowingError) {
            Button("Try Again", role: .cancel) {
                selectedItem = nil
                viewModel.capturedImageData = nil
            }
        } message: {
            Text(viewModel.loadingState.error?.errorDescription ?? "The label could not be scanned.")
        }
        .onDisappear {
            viewModel.cancel()
            camera.stop()
        }
    }

    // MARK: - Camera layer

    @ViewBuilder
    private var cameraLayer: some View {
        switch camera.authState {
        case .authorized:
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()
                .overlay {
                    if isScanning {
                        Color.black.opacity(0.4).ignoresSafeArea()
                    }
                }
        case .denied:
            permissionDeniedView
        case .unavailable, .unknown:
            Color.black.ignoresSafeArea()
        }
    }

    // MARK: - Overlay

    private var overlayLayer: some View {
        VStack(spacing: 0) {
            hintText
                .padding(.top, 12)
                .padding(.bottom, 8)

            Spacer()

            statusOrFrame
                .padding(.horizontal, 32)

            Spacer()

            bottomBar
        }
    }

    private var hintText: some View {
        Text("Align the supplement facts panel within the frame")
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.78))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 48)
    }

    @ViewBuilder
    private var statusOrFrame: some View {
        if isScanning {
            scanningBadge
        } else if scanSucceeded {
            detectedBadge
        } else {
            ViewfinderFrame()
                .aspectRatio(0.72, contentMode: .fit)
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 0) {
                photoLibraryButton
                Spacer()
                shutterButton
                    .sensoryFeedback(.impact(weight: .heavy), trigger: captureTriggered)
                Spacer()
                Color.clear.frame(width: 56, height: 56)
            }
            .padding(.horizontal, 40)
        }
        .padding(.top, 16)
        .padding(.bottom, 44)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    @State private var captureTriggered = false

    private var photoLibraryButton: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            Image(systemName: "photo.on.rectangle")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.90))
                .frame(width: 56, height: 56)
                .background(.white.opacity(0.15), in: Circle())
        }
        .disabled(isScanning)
        .accessibilityLabel("Import Label Photo")
    }

    private var shutterButton: some View {
        Button {
            guard !isScanning else { return }
            captureTriggered.toggle()
            if camera.isRunning {
                triggerCameraCapture()
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.40), lineWidth: 4)
                    .frame(width: 80, height: 80)
                Circle()
                    .fill(.white)
                    .frame(width: 66, height: 66)
                    .overlay {
                        if isScanning {
                            ProgressView()
                                .tint(.black)
                                .scaleEffect(1.1)
                        }
                    }
            }
        }
        .disabled(isScanning || (!camera.isRunning && camera.authState != .unavailable))
        .scaleEffect(isScanning ? 0.90 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isScanning)
        .accessibilityLabel("Capture label")
    }

    // MARK: - Status badges

    private var scanningBadge: some View {
        HStack(spacing: 10) {
            ProgressView().tint(.white)
            Text("Reading label…")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var detectedBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Label detected")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - Fallback views

    private var permissionDeniedView: some View {
        VStack(spacing: 18) {
            Image(systemName: "camera.slash")
                .font(.system(size: 54, weight: .thin))
                .foregroundStyle(.white.opacity(0.55))
            Text("Camera access required")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text("Allow camera access in Settings to scan supplement labels.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Open Settings") {
                if let url = URL(string: "app-settings:") {
                    openURL(url)
                }
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
    }

    // MARK: - Helpers

    private var isScanning: Bool {
        if case .loading = viewModel.loadingState { return true }
        return false
    }

    private var scanSucceeded: Bool {
        if case .loaded = viewModel.loadingState { return true }
        return false
    }

    private func triggerCameraCapture() {
        Task {
            do {
                let data = try await camera.capturePhoto()
                viewModel.capturedImageData = data
                viewModel.processPhotoData(data)
            } catch {
                viewModel.handlePhotoImportFailure(error)
            }
        }
    }
}

// MARK: - ViewfinderFrame

private struct ViewfinderFrame: View {
    @State private var pulse = false

    var body: some View {
        Canvas { context, size in
            let arm: CGFloat = 36
            let lw:  CGFloat = 3
            let style = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)
            var path = Path()

            // Top-left
            path.move(to: CGPoint(x: arm, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: arm))

            // Top-right
            path.move(to: CGPoint(x: size.width - arm, y: 0))
            path.addLine(to: CGPoint(x: size.width, y: 0))
            path.addLine(to: CGPoint(x: size.width, y: arm))

            // Bottom-left
            path.move(to: CGPoint(x: 0, y: size.height - arm))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.addLine(to: CGPoint(x: arm, y: size.height))

            // Bottom-right
            path.move(to: CGPoint(x: size.width - arm, y: size.height))
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: size.width, y: size.height - arm))

            context.stroke(path, with: .color(.white.opacity(pulse ? 0.45 : 0.88)), style: style)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
