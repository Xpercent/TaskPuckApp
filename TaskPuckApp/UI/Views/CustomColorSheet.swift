import Foundation
import SwiftUI
import UIKit

struct CustomColorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var tintHex: String
    let iconSymbol: String
    @Binding var presentationDetent: PresentationDetent

    @State private var hue = 0.0
    @State private var saturation = 0.75
    @State private var brightness = 0.95
    @State private var hexInputText = ""
    @State private var isEditingPresets = false
    @State private var isUpdatingHexFromControls = false
    @FocusState private var isHexFieldFocused: Bool

    @AppStorage(AppConstants.StorageKeys.customColorPresets) private var customPresetsRaw = ""

    private var customPresets: [String] {
        TaskAppearance.customPresetHexes(from: customPresetsRaw)
    }

    private var allPresets: [String] {
        TaskAppearance.defaultPresetHexes + customPresets
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                colorControls
                presetsHeader
                presets
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear(perform: initializeColor)
    }

    private var header: some View {
        HStack {
            Text("选择颜色")
                .font(.system(size: 24, weight: .bold))

            Spacer()
            hexEditor
            Spacer().frame(width: 8)
            SheetCloseButton()
        }
    }

    private var hexEditor: some View {
        HStack(spacing: 4) {
            Text("#")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppConstants.Colors.hexPrefixPink)

            TextField("HEX", text: $hexInputText)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .frame(width: 90)
                .focused($isHexFieldFocused)
                .allowsHitTesting(presentationDetent == .large)
                .accessibilityHidden(presentationDetent != .large)
                .overlay {
                    if presentationDetent != .large {
                        Button(action: expandThenFocusHexField) {
                            Color.clear
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("编辑 HEX 颜色")
                    }
                }
                .onChange(of: hexInputText) { _, newValue in
                    handleHexInputChange(newValue)
                }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(uiColor: .separator))
                .frame(height: 1)
        }
    }

    private var colorControls: some View {
        VStack(spacing: 22) {
            ColorValueSlider(
                value: $hue,
                colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red],
                handleColor: Color(hue: hue, saturation: 1, brightness: 1),
                onChange: updateHexFromHSB
            )

            ColorValueSlider(
                value: $brightness,
                colors: [
                    .black,
                    Color(hue: hue, saturation: max(0.4, saturation), brightness: 1)
                ],
                handleColor: Color(hex: tintHex),
                onChange: updateHexFromHSB
            )
        }
    }

    private var presetsHeader: some View {
        HStack {
            Text("预设")
                .font(.system(size: 18, weight: .bold))

            Spacer()

            Button {
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.2)) {
                    isEditingPresets.toggle()
                }
            } label: {
                Label(
                    isEditingPresets ? "完成" : "编辑",
                    systemImage: isEditingPresets ? "checkmark" : "star.fill"
                )
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isEditingPresets ? Color(uiColor: .selectedControlColor) : Color(uiColor: .tertiarySystemFill),
                    in: Capsule()
                )
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    private var presets: some View {
        HStack(alignment: .top, spacing: 16) {
            colorPreview

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(minimum: 36), spacing: 8),
                    count: 5
                ),
                alignment: .leading,
                spacing: 14
            ) {
                ForEach(Array(allPresets.enumerated()), id: \.offset) { index, hex in
                    presetButton(
                        hex: hex,
                        isRemovable: index >= TaskAppearance.defaultPresetHexes.count
                    )
                }
                addPresetButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var colorPreview: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: tintHex).opacity(0.3))
                .frame(width: 2, height: 125)

            Circle()
                .fill(Color(hex: tintHex))
                .frame(width: 50, height: 50)
                .shadow(color: Color(hex: tintHex).opacity(0.3), radius: 6, y: 3)
                .overlay {
                    Image(systemName: iconSymbol)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
        }
        .frame(width: 50)
    }

    private func presetButton(hex: String, isRemovable: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            Button {
                guard !isEditingPresets else { return }
                applyHex(hex)
            } label: {
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 36, height: 36)
                    .overlay {
                        if tintHex.caseInsensitiveCompare(hex) == .orderedSame {
                            Circle()
                                .stroke(Color(uiColor: .systemBackground), lineWidth: 2.5)
                                .shadow(color: .black.opacity(0.2), radius: 2)
                        }
                    }
            }
            .buttonStyle(PressScaleButtonStyle())
            .accessibilityLabel("颜色 #\(hex)")

            if isEditingPresets && isRemovable {
                Button {
                    withAnimation(reduceMotion ? nil : .smooth(duration: 0.2)) {
                        removeCustomPreset(hex)
                    }
                } label: {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 18, height: 18)
                        .overlay {
                            Image(systemName: "minus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                }
                .buttonStyle(.plain)
                .offset(x: 5, y: -5)
                .zIndex(1)
                .accessibilityLabel("删除颜色 #\(hex)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var addPresetButton: some View {
        Button {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.2)) {
                addCustomPreset(tintHex)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: tintHex).opacity(0.15))
                    .frame(width: 36, height: 36)
                Circle()
                    .stroke(
                        Color(hex: tintHex),
                        style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: tintHex))
            }
        }
        .buttonStyle(PressScaleButtonStyle())
        .frame(maxWidth: .infinity)
        .accessibilityLabel("将当前颜色添加到预设")
    }

    private func initializeColor() {
        let normalized = TaskAppearance.normalizedHex(tintHex) ?? AppConstants.Appearance.defaultTintHex
        applyHex(normalized)
    }

    private func handleHexInputChange(_ newValue: String) {
        let sanitized = TaskAppearance.sanitizedHexInput(newValue)
        guard sanitized == newValue else {
            hexInputText = sanitized
            return
        }
        guard !isUpdatingHexFromControls, sanitized.count == 6 else { return }
        tintHex = sanitized
        syncHSBFromHex(sanitized)
    }

    private func applyHex(_ hex: String) {
        guard let normalized = TaskAppearance.normalizedHex(hex) else { return }
        tintHex = normalized
        hexInputText = normalized
        syncHSBFromHex(normalized)
    }

    private func expandThenFocusHexField() {
        guard presentationDetent != .large else {
            isHexFieldFocused = true
            return
        }

        if reduceMotion {
            presentationDetent = .large
            DispatchQueue.main.async {
                isHexFieldFocused = true
            }
        } else {
            withAnimation(.smooth(duration: 0.25), completionCriteria: .logicallyComplete) {
                presentationDetent = .large
            } completion: {
                isHexFieldFocused = true
            }
        }
    }

    private func addCustomPreset(_ hex: String) {
        guard let normalized = TaskAppearance.normalizedHex(hex),
              !allPresets.contains(normalized) else { return }
        customPresetsRaw = TaskAppearance.encodedCustomPresets(customPresets + [normalized])
    }

    private func removeCustomPreset(_ hex: String) {
        customPresetsRaw = TaskAppearance.encodedCustomPresets(
            customPresets.filter { $0 != hex }
        )
    }

    private func syncHSBFromHex(_ hex: String) {
        guard let hsb = ColorConversion.hsb(from: hex) else { return }
        if hsb.saturation > 0.05 {
            hue = hsb.hue
        }
        saturation = hsb.saturation
        brightness = hsb.brightness
    }

    private func updateHexFromHSB() {
        isUpdatingHexFromControls = true
        let newHex = ColorConversion.hex(hue: hue, saturation: saturation, brightness: brightness)
        tintHex = newHex
        hexInputText = newHex
        DispatchQueue.main.async {
            isUpdatingHexFromControls = false
        }
    }
}

private struct ColorValueSlider: View {
    @Binding var value: Double
    let colors: [Color]
    let handleColor: Color
    let onChange: () -> Void

    private let handleSize: CGFloat = 32

    var body: some View {
        GeometryReader { geometry in
            let travelWidth = max(1, geometry.size.width - handleSize)
            let clampedValue = min(max(value, 0), 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .frame(height: handleSize)

                Circle()
                    .fill(Color(uiColor: .systemBackground)) // 自适应动态系统底色替换写死的 .white
                    .frame(width: handleSize, height: handleSize)
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                    .overlay {
                        Circle()
                            .fill(handleColor)
                            .padding(3)
                    }
                    .offset(x: CGFloat(clampedValue) * travelWidth)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let position = min(max(drag.location.x - handleSize / 2, 0), travelWidth)
                        value = Double(position / travelWidth)
                        onChange()
                    }
            )
        }
        .frame(height: 32)
    }
}

private enum ColorConversion {
    static func hsb(from hex: String) -> (hue: Double, saturation: Double, brightness: Double)? {
        guard let normalized = TaskAppearance.normalizedHex(hex),
              let value = UInt64(normalized, radix: 16) else { return nil }

        let color = UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getHue(
            &hue,
            saturation: &saturation,
            brightness: &brightness,
            alpha: &alpha
        ) else { return nil }

        return (Double(hue), Double(saturation), Double(brightness))
    }

    static func hex(hue: Double, saturation: Double, brightness: Double) -> String {
        let color = UIColor(
            hue: CGFloat(hue),
            saturation: CGFloat(saturation),
            brightness: CGFloat(brightness),
            alpha: 1
        )
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return String(
            format: "%02X%02X%02X",
            Int(round(red * 255)),
            Int(round(green * 255)),
            Int(round(blue * 255))
        )
    }
}