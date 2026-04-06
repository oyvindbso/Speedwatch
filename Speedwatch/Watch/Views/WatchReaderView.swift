import SwiftUI

struct WatchReaderView: View {
    @EnvironmentObject var bookManager: WatchBookManager
    @EnvironmentObject var watchConnectivity: WatchConnectivityManager

    let book: BookInfo
    @AppStorage("readingSpeed") private var wordsPerMinute: Int = 300
    @State private var currentIndex: Int = 0
    @State private var isPlaying = false
    @State private var timer: Timer?
    @State private var words: [String] = []

    var body: some View {
        VStack(spacing: 8) {
            // Progress
            ProgressView(value: progress)
                .tint(.blue)

            Spacer()

            // Word display
            if !words.isEmpty && currentIndex < words.count {
                SpritzWordView(word: words[currentIndex])
                    .padding()
            } else {
                Text("Loading...")
                    .font(.title3)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Speed indicator
            Text("\(wordsPerMinute) WPM")
                .font(.caption2)
                .foregroundColor(.secondary)

            // Controls
            HStack(spacing: 20) {
                Button(action: skipBackward) {
                    Image(systemName: "backward.fill")
                }
                .buttonStyle(.plain)

                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)

                Button(action: skipForward) {
                    Image(systemName: "forward.fill")
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 4)

            // Speed adjustment
            HStack {
                Button(action: { adjustSpeed(by: -50) }) {
                    Image(systemName: "minus.circle")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Button(action: { adjustSpeed(by: 50) }) {
                    Image(systemName: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadWords()
            currentIndex = book.currentPosition
        }
        .onDisappear {
            savePosition()
        }
    }

    private var progress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentIndex) / Double(words.count)
    }

    private func loadWords() {
        words = bookManager.getWords(for: book.id) ?? []
        if words.isEmpty {
            bookManager.requestBookContent(bookID: book.id)
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
        bookManager.updatePosition(bookID: book.id, position: currentIndex)
        watchConnectivity.updateReadingPosition(bookID: book.id, position: currentIndex)
    }
}
