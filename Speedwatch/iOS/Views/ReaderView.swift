import SwiftUI

struct ReaderView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var watchConnectivity: WatchConnectivityManager

    @ObservedObject var book: Book
    @AppStorage("readingSpeed") private var wordsPerMinute: Int = 300
    @State private var words: [String] = []
    @State private var currentIndex: Int = 0
    @State private var isPlaying = false
    @State private var timer: Timer?
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Progress indicator
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .tint(.blue)
                    Text("\(currentIndex + 1) / \(words.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Spacer()

                // Main word display
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)

                    if !words.isEmpty && currentIndex < words.count {
                        SpritzWordView(word: words[currentIndex])
                    } else {
                        Text("Loading...")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()

                // Controls
                VStack(spacing: 20) {
                    // Speed control
                    VStack(spacing: 8) {
                        Text("\(wordsPerMinute) WPM")
                            .font(.headline)
                        HStack {
                            Button(action: { adjustSpeed(by: -50) }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                            }

                            Slider(value: Binding(
                                get: { Double(wordsPerMinute) },
                                set: { wordsPerMinute = Int($0) }
                            ), in: 100...1000, step: 10)
                            .frame(maxWidth: 200)

                            Button(action: { adjustSpeed(by: 50) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Playback controls
                    HStack(spacing: 40) {
                        Button(action: skipBackward) {
                            Image(systemName: "backward.fill")
                                .font(.title)
                        }

                        Button(action: togglePlayback) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60))
                        }

                        Button(action: skipForward) {
                            Image(systemName: "forward.fill")
                                .font(.title)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        savePosition()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadWords()
                currentIndex = Int(book.currentPosition)
            }
            .onDisappear {
                savePosition()
            }
        }
    }

    private var progress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentIndex) / Double(words.count)
    }

    private func loadWords() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let wordsFileName = "\(book.id.uuidString).json"
        let wordsURL = documentsPath.appendingPathComponent(wordsFileName)

        do {
            let data = try Data(contentsOf: wordsURL)
            words = try JSONDecoder().decode([String].self, from: data)
        } catch {
            print("Error loading words: \(error.localizedDescription)")
        }
    }

    private func togglePlayback() {
        isPlaying.toggle()

        if isPlaying {
            startReading()
        } else {
            stopReading()
        }
    }

    private func startReading() {
        let interval = 60.0 / Double(wordsPerMinute)

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            if currentIndex < words.count - 1 {
                currentIndex += 1
                savePositionPeriodically()
            } else {
                stopReading()
            }
        }
    }

    private func stopReading() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
        savePosition()
    }

    private func skipForward() {
        currentIndex = min(currentIndex + 10, words.count - 1)
        savePosition()
    }

    private func skipBackward() {
        currentIndex = max(currentIndex - 10, 0)
        savePosition()
    }

    private func adjustSpeed(by amount: Int) {
        wordsPerMinute = max(100, min(1000, wordsPerMinute + amount))
        if isPlaying {
            stopReading()
            startReading()
        }
    }

    @State private var saveCounter = 0
    private func savePositionPeriodically() {
        saveCounter += 1
        if saveCounter >= 50 {
            savePosition()
            saveCounter = 0
        }
    }

    private func savePosition() {
        book.currentPosition = Int64(currentIndex)
        book.lastOpened = Date()
        try? viewContext.save()

        // Sync to watch
        watchConnectivity.updateReadingPosition(bookID: book.id, position: currentIndex)
    }
}

struct SpritzWordView: View {
    let word: String

    var body: some View {
        HStack(spacing: 0) {
            // Calculate optimal recognition point (ORP)
            let orpIndex = calculateORP(for: word)

            if word.count > 0 {
                // Text before ORP
                if orpIndex > 0 {
                    Text(String(word.prefix(orpIndex)))
                        .font(.system(size: 48, weight: .regular, design: .monospaced))
                }

                // ORP character (highlighted)
                if orpIndex < word.count {
                    Text(String(word[word.index(word.startIndex, offsetBy: orpIndex)]))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                }

                // Text after ORP
                if orpIndex + 1 < word.count {
                    Text(String(word.suffix(word.count - orpIndex - 1)))
                        .font(.system(size: 48, weight: .regular, design: .monospaced))
                }
            }
        }
    }

    private func calculateORP(for word: String) -> Int {
        let length = word.count
        switch length {
        case 0:
            return 0
        case 1:
            return 0
        case 2...5:
            return 1
        case 6...9:
            return 2
        case 10...13:
            return 3
        default:
            return 4
        }
    }
}
