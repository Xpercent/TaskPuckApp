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
                            .fill(Color.black.opacity(0.06))
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
        .background(Color.black.opacity(0.04), in: Capsule())
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
                            .fill(Color.black.opacity(0.05))
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

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}

enum TaskAppearance {
    static var customPresetStorageKey: String {
        AppConstants.StorageKeys.customColorPresets
    }

    static var defaultPresetHexes: [String] {
        AppConstants.Appearance.defaultPresetHexes
    }

    static var iconSymbols: [String] {
        AppConstants.Appearance.iconSymbols
    }

    private static let hexDigits = Set("0123456789ABCDEF")

    static func sanitizedHexInput(_ value: String) -> String {
        String(value.uppercased().filter { hexDigits.contains($0) }.prefix(6))
    }

    static func normalizedHex(_ value: String) -> String? {
        let normalized = sanitizedHexInput(value)
        return normalized.count == 6 ? normalized : nil
    }

    static func customPresetHexes(from rawValue: String) -> [String] {
        var seen = Set(defaultPresetHexes)
        return rawValue.split(separator: ",").compactMap { value in
            guard let hex = normalizedHex(String(value)), seen.insert(hex).inserted else {
                return nil
            }
            return hex
        }
    }

    static func encodedCustomPresets(_ presets: [String]) -> String {
        presets.compactMap(normalizedHex).joined(separator: ",")
    }
}

extension Color {
    init(hex: String) {
        let defaultHex = AppConstants.Appearance.defaultTintHex
        let normalized = TaskAppearance.normalizedHex(hex) ?? defaultHex
        let value = UInt64(normalized, radix: 16) ?? (UInt64(defaultHex, radix: 16) ?? 0xEE8C8C)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}