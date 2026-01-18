import Foundation
import Combine

class WatchBookManager: ObservableObject {
    @Published var books: [BookInfo] = []
    private var bookContents: [UUID: [String]] = [:]

    init() {
        loadFromUserDefaults()
        setupConnectivityObserver()
    }

    func getWords(for bookID: UUID) -> [String]? {
        return bookContents[bookID]
    }

    func updatePosition(bookID: UUID, position: Int) {
        if let index = books.firstIndex(where: { $0.id == bookID }) {
            var updatedBook = books[index]
            books[index] = BookInfo(
                id: updatedBook.id,
                title: updatedBook.title,
                author: updatedBook.author,
                currentPosition: position,
                totalWords: updatedBook.totalWords
            )
            saveToUserDefaults()
        }
    }

    func requestBookContent(bookID: UUID) {
        // Request will be handled by WatchConnectivityManager
        NotificationCenter.default.post(
            name: NSNotification.Name("RequestBookContent"),
            object: bookID
        )
    }

    private func setupConnectivityObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ReceivedBooks"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let books = notification.object as? [BookInfo] {
                self?.books = books
                self?.saveToUserDefaults()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ReceivedBookContent"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let info = notification.object as? (UUID, [String]) {
                self?.bookContents[info.0] = info.1
                self?.saveBookContent(bookID: info.0, words: info.1)
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ReceivedPositionUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let info = notification.object as? (UUID, Int) {
                self?.updatePosition(bookID: info.0, position: info.1)
            }
        }
    }

    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(books) {
            UserDefaults.standard.set(encoded, forKey: "watchBooks")
        }
    }

    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "watchBooks"),
           let decoded = try? JSONDecoder().decode([BookInfo].self, from: data) {
            books = decoded
        }

        // Load book contents
        for book in books {
            if let words = loadBookContent(bookID: book.id) {
                bookContents[book.id] = words
            }
        }
    }

    private func saveBookContent(bookID: UUID, words: [String]) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let wordsFileName = "\(bookID.uuidString).json"
        let wordsURL = documentsPath.appendingPathComponent(wordsFileName)

        if let wordsData = try? JSONEncoder().encode(words) {
            try? wordsData.write(to: wordsURL)
        }
    }

    private func loadBookContent(bookID: UUID) -> [String]? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let wordsFileName = "\(bookID.uuidString).json"
        let wordsURL = documentsPath.appendingPathComponent(wordsFileName)

        if let data = try? Data(contentsOf: wordsURL),
           let words = try? JSONDecoder().decode([String].self, from: data) {
            return words
        }
        return nil
    }
}
