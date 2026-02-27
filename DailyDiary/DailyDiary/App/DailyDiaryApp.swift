import SwiftUI
import SwiftData

@main
struct DailyDiaryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: DiaryEntry.self)
    }
}
