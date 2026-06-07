// ScanPhotoImportView.swift
// SuppliScan

import PhotosUI
import SwiftUI

struct ScanPhotoImportView: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Label Image")
                .font(.headline)

            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images
            ) {
                Label("Import Label Photo", systemImage: "photo.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("Imports a supplement label photo for on-device text recognition.")
        }
    }
}
