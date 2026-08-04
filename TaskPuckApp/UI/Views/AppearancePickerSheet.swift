import Foundation
import SwiftUI

struct AppearancePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var iconSymbol: String
    @Binding var tintHex: String

    @State private var showsCustomColor = false
    @State private var customColorDetent: PresentationDetent = .medium
    @AppStorage(AppConstants.StorageKeys.customColorPresets) private var customPresetsRaw = ""

    private var allPresets: [String] {
        TaskAppearance.defaultPresetHexes + TaskAppearance.customPresetHexes(from: customPresetsRaw)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    presetPicker
                    iconPicker
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .sheet(isPresented: $showsCustomColor) {
            CustomColorSheet(
                tintHex: $tintHex,
                iconSymbol: iconSymbol,
                presentationDetent: $customColorDetent
            )
            .presentationDetents([.medium, .large], selection: $customColorDetent)
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Text("颜色和图标")
                .font(.system(size: 24, weight: .bold))

            Spacer()
            SheetCloseButton()
        }
    }

    private var presetPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(allPresets, id: \.self) { hex in
                    presetButton(hex: hex)
                }

                Button {
                    customColorDetent = .medium
                    showsCustomColor = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(uiColor: .tertiarySystemFill))
                            .frame(width: 38, height: 38)
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(PressScaleButtonStyle())
                .accessibilityLabel("选择更多颜色")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .secondarySystemFill), in: Capsule())
        .clipShape(Capsule())
    }

    private var iconPicker: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5),
            spacing: 14
        ) {
            ForEach(TaskAppearance.iconSymbols, id: \.self) { symbol in
                let isSelected = iconSymbol == symbol
                Button {
                    setWithoutAnimation($iconSymbol, to: symbol)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(uiColor: .tertiarySystemFill))
                        Circle()
                            .fill(Color(hex: tintHex))
                            .opacity(isSelected ? 1 : 0)
                        Image(systemName: symbol)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : Color(hex: tintHex))
                    }
                    .frame(height: 52)
                    .contentShape(Circle())
                }
                .buttonStyle(PressScaleButtonStyle())
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.top, 6)
    }

    private func presetButton(hex: String) -> some View {
        let isSelected = tintHex.caseInsensitiveCompare(hex) == .orderedSame
        return Button {
            setWithoutAnimation($tintHex, to: hex)
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .stroke(Color(hex: hex), lineWidth: 2.5)
                        .frame(width: 42, height: 42)
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 32, height: 32)
                } else {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 38, height: 38)
                }
            }
            .frame(width: 42, height: 42)
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("颜色 #\(hex)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func setWithoutAnimation<Value>(_ binding: Binding<Value>, to value: Value) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            binding.wrappedValue = value
        }
    }
}