import SwiftUI

@main
struct SpeedwatchWatchApp: App {
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @StateObject private var bookManager = WatchBookManager()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(watchConnectivity)
                .environmentObject(bookManager)
        }
    }
}
