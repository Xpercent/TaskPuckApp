import SwiftUI

public struct TaskManagementView: View {
    @Environment(TaskEngine.self) private var engine

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Task Management")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                .padding(.horizontal, 24)
                .padding(.top, 16)

            LazyVGrid(columns: columns, spacing: 16) {
                // 卡片 1: 今天
                CategoryGridCard(title: "今天", count: "1", iconSymbol: "calendar", gradientColors: [Color(red: 0.38, green: 0.68, blue: 0.93), Color(red: 0.28, green: 0.58, blue: 0.88)])
                
                // 卡片 2: 计划
                CategoryGridCard(title: "计划", count: "2", iconSymbol: "calendar", gradientColors: [Color(red: 0.93, green: 0.52, blue: 0.52), Color(red: 0.88, green: 0.42, blue: 0.42)])
                
                // 卡片 3: 全部
                CategoryGridCard(title: "全部", count: "3", iconSymbol: "archivebox.fill", gradientColors: [Color(red: 0.28, green: 0.28, blue: 0.30), Color(red: 0.22, green: 0.22, blue: 0.24)])
                
                // 卡片 4: 旗标
                CategoryGridCard(title: "旗标", count: "0", iconSymbol: "flag.fill", gradientColors: [Color(red: 0.95, green: 0.73, blue: 0.48), Color(red: 0.92, green: 0.65, blue: 0.38)])
                
                // 卡片 5: 紧急
                CategoryGridCard(title: "紧急", count: "1", iconSymbol: "clock.fill", gradientColors: [Color(red: 0.93, green: 0.42, blue: 0.58), Color(red: 0.88, green: 0.32, blue: 0.48)])
                
                // 卡片 6: 完成
                CategoryGridCard(title: "完成", count: nil, iconSymbol: "checkmark", gradientColors: [Color(red: 0.55, green: 0.60, blue: 0.65), Color(red: 0.45, green: 0.50, blue: 0.55)])
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.97))
    }
}

struct CategoryGridCard: View {
    let title: String
    let count: String?
    let iconSymbol: String
    let gradientColors: [Color]

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image(systemName: iconSymbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer()

                if let count {
                    Text(count)
                        .font(.system(size: 32, weight: .heavy, design: .rounded)) // 👈 修正：.extrabold 改为 .heavy
                        .foregroundColor(.white)
                }
            }

            Spacer()

            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(16)
        .frame(height: 105)
        .background(
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: gradientColors.first?.opacity(0.2) ?? .clear, radius: 8, x: 0, y: 4)
    }
}