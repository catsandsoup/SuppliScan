// ScanView.swift
// SuppliScan

import PhotosUI
import SwiftUI

struct ScanView: View {
    @Environment(NavigationRouter.self) private var router
    @Environment(AppDependencies.self) private var dependencies

    @State private var viewModel = ScanViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var displayImage: UIImage?
    @AppStorage("defaultStandard") private var selectedStandard: ReferenceStandard = .au

    private var isScanning: Bool {
        if case .loading = viewModel.loadingState { return true }
        return false
    }

    private var scanSucceeded: Bool {
        if case .loaded = viewModel.loadingState { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            viewfinderSection
                .frame(maxHeight: .infinity)
            bottomSection
        }
        .navigationTitle("Scan Label")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(
                ocrService: dependencies.ocrService,
                parser: dependencies.parserService
            )
        }
        .task(id: selectedItem) {
            guard let item = selectedItem else { return }
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw AppError.unknown(description: "Photo could not be loaded.")
                }
                displayImage = UIImage(data: data)
                viewModel.processPhotoData(data)
            } catch {
                viewModel.handlePhotoImportFailure(error)
            }
        }
        .onChange(of: viewModel.pendingDestination) {
            guard let destination = viewModel.consumePendingDestination() else { return }
            router.navigate(to: destination)
        }
        .alert("Scan Failed", isPresented: $viewModel.isShowingError) {
            Button("Try Again", role: .cancel) {
                selectedItem = nil
                displayImage = nil
            }
        } message: {
            Text(viewModel.loadingState.error?.errorDescription ?? "The label could not be scanned.")
        }
        .onDisappear { viewModel.cancel() }
    }

    // MARK: - Viewfinder

    private var viewfinderSection: some View {
        ZStack {
            Color(.secondarySystemBackground)

            if let image = displayImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityHidden(true)

                if isScanning { scanningOverlay }
                if scanSucceeded { detectedBadge }
            } else {
                emptyViewfinder
            }

            ViewfinderCorners()
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var emptyViewfinder: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60, weight: .thin))
                .foregroundStyle(.tertiary)
            Text("Import a supplement label photo")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }

    private var scanningOverlay: some View {
        ZStack {
            Color(.systemBackground).opacity(0.55)
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.3)
                Text("Reading label…")
                    .font(.subheadline.weight(.medium))
            }
        }
    }

    private var detectedBadge: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Label detected")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
            .padding(.bottom, 20)
        }
    }

    // MARK: - Bottom controls

    private var bottomSection: some View {
        VStack(spacing: 14) {
            if case .failed(let error) = viewModel.loadingState {
                Label(
                    error.errorDescription ?? "Scan failed",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.subheadline)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Picker("Reference Standard", selection: $selectedStandard) {
                ForEach(ReferenceStandard.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Reference standard for nutritional values")

            let scanning = isScanning
            let hasImage = displayImage != nil
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ImportButtonLabel(isScanning: scanning, hasImage: hasImage)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isScanning)
            .accessibilityHint("Opens your photo library to select a supplement label image.")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 32)
    }
}

// MARK: - ImportButtonLabel

private struct ImportButtonLabel: View {
    let isScanning: Bool
    let hasImage: Bool

    var body: some View {
        Group {
            if isScanning {
                Label("Reading label…", systemImage: "ellipsis")
            } else if hasImage {
                Label("Choose Different Photo", systemImage: "photo.badge.plus")
            } else {
                Label("Import Label Photo", systemImage: "photo.badge.plus")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ViewfinderCorners

private struct ViewfinderCorners: View {
    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 20
            let leg: CGFloat = 26
            let style = StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)

            var path = Path()

            // Top-left
            path.move(to: CGPoint(x: inset + leg, y: inset))
            path.addLine(to: CGPoint(x: inset, y: inset))
            path.addLine(to: CGPoint(x: inset, y: inset + leg))

            // Top-right
            path.move(to: CGPoint(x: size.width - inset - leg, y: inset))
            path.addLine(to: CGPoint(x: size.width - inset, y: inset))
            path.addLine(to: CGPoint(x: size.width - inset, y: inset + leg))

            // Bottom-left
            path.move(to: CGPoint(x: inset + leg, y: size.height - inset))
            path.addLine(to: CGPoint(x: inset, y: size.height - inset))
            path.addLine(to: CGPoint(x: inset, y: size.height - inset - leg))

            // Bottom-right
            path.move(to: CGPoint(x: size.width - inset - leg, y: size.height - inset))
            path.addLine(to: CGPoint(x: size.width - inset, y: size.height - inset))
            path.addLine(to: CGPoint(x: size.width - inset, y: size.height - inset - leg))

            context.stroke(path, with: .color(.primary), style: style)
        }
    }
}
