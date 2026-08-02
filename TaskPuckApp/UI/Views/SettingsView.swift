import SwiftUI

public struct SettingsView: View {
    @Environment(TaskEngine.self) private var engine

    public var body: some View {
        NavigationStack {
            List {
                Section("开发者工具与 MVP 数据注入") {
                    Button(action: {
                        engine.initializeMVPData()
                    }) {
                        HStack {
                            Image(systemName: "cylinder.split.1x2.fill")
                                .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.55))
                            Text("重置并注入图示 MVP 测试数据")
                                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                        }
                    }
                }

                Section("关于应用") {
                    HStack {
                        Text("系统版本")
                        Spacer()
                        Text("iOS 18+ (Swift 6 Standard)")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}