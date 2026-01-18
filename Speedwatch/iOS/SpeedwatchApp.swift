import SwiftUI

@main
struct SpeedwatchApp: App {
    @StateObject private var dataController = DataController.shared
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(watchConnectivity)
        }
    }
}
