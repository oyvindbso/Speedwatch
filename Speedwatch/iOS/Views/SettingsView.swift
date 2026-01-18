import SwiftUI

struct SettingsView: View {
    @AppStorage("readingSpeed") private var wordsPerMinute: Int = 300
    @AppStorage("autoSyncEnabled") private var autoSyncEnabled: Bool = true
    @EnvironmentObject var watchConnectivity: WatchConnectivityManager

    var body: some View {
        NavigationView {
            Form {
                Section("Reading") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Default Speed")
                            Spacer()
                            Text("\(wordsPerMinute) WPM")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: Binding(
                            get: { Double(wordsPerMinute) },
                            set: { wordsPerMinute = Int($0) }
                        ), in: 100...1000, step: 10)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speed Guide")
                            .font(.headline)
                        Text("100-200 WPM: Slow, comfortable")
                            .font(.caption)
                        Text("250-300 WPM: Average reading speed")
                            .font(.caption)
                        Text("400-500 WPM: Fast reading")
                            .font(.caption)
                        Text("600+ WPM: Speed reading")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Section("Sync") {
                    Toggle("Auto-sync with Apple Watch", isOn: $autoSyncEnabled)

                    HStack {
                        Text("Watch Status")
                        Spacer()
                        if watchConnectivity.isReachable {
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("Disconnected", systemImage: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
