import SwiftUI
import SwiftData

@main
struct DailyDiaryApp: App {
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .modelContainer(for: DiaryEntry.self)
    }
}
