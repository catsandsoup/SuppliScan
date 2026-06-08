// LabelRecognisedBannerView.swift
// SuppliScan
// Green checkmark + "Label recognised" + standard — shown at top of ReviewView.

import SwiftUI

struct LabelRecognisedBannerView: View {
    let standard: ReferenceStandard
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(.systemGreen))
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Label Recognised")
                    .font(.subheadline.weight(.semibold))
                Text("\(standard.rawValue) Label")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGreen).opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.70)) {
                isVisible = true
            }
        }
    }
}
