import SwiftUI

public struct SettingsView: View {
    public var body: some View {
        NavigationStack {
            List {
                Section("关于应用") {
                    HStack {
                        Text("系统版本")
                        Spacer()
                        Text("iOS 17+")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}
