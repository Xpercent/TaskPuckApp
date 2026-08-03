import SwiftUI

public struct SettingsView: View {
    @Environment(TaskEngine.self) private var engine
    @AppStorage("app_theme_hex") private var themeHex = "EE8C8C"
    @AppStorage("user_name") private var userName = "TaskPuck 用户"
    @AppStorage("user_avatar_symbol") private var avatarSymbol = "person.crop.circle.fill"

    @State private var showsThemePicker = false
    @State private var themeDetent: PresentationDetent = .medium
    @State private var showsClearConfirmation = false

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    profileCard
                    appearanceSection
                    dataSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 110)
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.97))
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showsThemePicker) {
                CustomColorSheet(
                    tintHex: $themeHex,
                    iconSymbol: "paintpalette.fill",
                    presentationDetent: .constant(.medium)
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .alert("清空全部数据？", isPresented: $showsClearConfirmation) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    engine.clearAllData()
                }
            } message: {
                Text("任务、排程和完成状态都会被删除。")
            }
        }
    }

    private var profileCard: some View {
        HStack(spacing: 14) {
            Image(systemName: avatarSymbol)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Color(hex: themeHex))
                .frame(width: 64, height: 64)
                .background(Color(hex: themeHex).opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                TextField("用户名", text: $userName)
                    .font(.system(size: 20, weight: .bold))
                    .textFieldStyle(.plain)
                Text("专注于今天要完成的事")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(18)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("外观")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            Button {
                themeDetent = .large
                showsThemePicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "paintpalette.fill")
                        .foregroundStyle(Color(hex: themeHex))
                        .frame(width: 28)
                    Text("主题色")
                        .foregroundStyle(.primary)
                    Spacer()
                    Circle()
                        .fill(Color(hex: themeHex))
                        .frame(width: 26, height: 26)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("数据")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                Button {
                    engine.initializeSampleData()
                } label: {
                    settingsRow(title: "初始化测试数据", icon: "wand.and.stars", tint: Color(hex: themeHex))
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 56)

                Button {
                    showsClearConfirmation = true
                } label: {
                    settingsRow(title: "清空数据", icon: "trash", tint: .red)
                }
                .buttonStyle(.plain)
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func settingsRow(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 28)
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }
}
