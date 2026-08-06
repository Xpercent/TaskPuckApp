import SwiftUI
import SwiftData
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

@main
struct TaskPuckApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                TaskEntity.self,
                TaskInstanceEntity.self,
                TimelinePlacementEntity.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not initialize SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainContainerView()
                .modelContainer(container)
        }
    }
}

struct MainContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var engine: TaskEngine?
    @State private var selectedTab: Int = 0
    @State private var showCreateSheet: Bool = false

    var body: some View {
        Group {
            if let engine {
                ZStack(alignment: .bottom) {
                    Group {
                        switch selectedTab {
                        case 0:
                            HomeTimelineView()
                        case 1:
                            TaskManagementView()
                        case 2:
                            RecordsView()
                        default:
                            SettingsView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Floating Glass Bottom Bar
                    FloatingTabBar(selectedTab: $selectedTab) {
                        showCreateSheet = true
                    }
                }
                .environment(engine)
                .sheet(isPresented: $showCreateSheet) {
                    CreateTaskSheet()
                        .environment(engine)
                }
                .overlay(alignment: .top) {
                    if let toast = engine.toastMessage {
                        Text(toast)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.8), in: Capsule())
                            .padding(.top, 50)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    engine.toastMessage = nil
                                }
                            }
                    }
                }
            } else {
                ProgressView()
                    .onAppear {
                        let eng = TaskEngine(modelContext: modelContext)
                        eng.selectDate(DateUtils.todayString())
                        self.engine = eng
                    }
            }
        }
    }
}
