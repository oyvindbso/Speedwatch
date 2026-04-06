import Foundation
import Combine

class WatchBookManager: ObservableObject {
    @Published var books: [BookInfo] = []
    private var bookContents: [UUID: [String]] = [:]

    init() {
        loadFromDefaults()
        setupObservers()
    }

    func getWords(for bookID: UUID) -> [String]? {
        bookContents[bookID]
    }

    func updatePosition(bookID: UUID, position: Int) {
        guard let idx = books.firstIndex(where: { $0.id == bookID }) else { return }
        let old = books[idx]
        books[idx] = BookInfo(id: old.id, title: old.title, author: old.author,
                              currentPosition: position, totalWords: old.totalWords)
        saveToDefaults()
    }

    func requestBookContent(bookID: UUID) {
        WatchConnectivityManager.shared.requestBookContent(bookID: bookID)
    }

    // MARK: - Private

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            forName: .receivedBooks, object: nil, queue: .main
        ) { [weak self] note in
            if let books = note.userInfo?["books"] as? [BookInfo] {
                self?.books = books
                self?.saveToDefaults()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .receivedBookContent, object: nil, queue: .main
        ) { [weak self] note in
            if let bookID = note.userInfo?["bookID"] as? UUID,
               let words = note.userInfo?["words"] as? [String] {
                self?.bookContents[bookID] = words
                self?.saveBookContent(bookID: bookID, words: words)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .receivedPositionUpdate, object: nil, queue: .main
        ) { [weak self] note in
            if let bookID = note.userInfo?["bookID"] as? UUID,
               let position = note.userInfo?["position"] as? Int {
                self?.updatePosition(bookID: bookID, position: position)
            }
        }
    }

    private func saveToDefaults() {
        if let encoded = try? JSONEncoder().encode(books) {
            UserDefaults.standard.set(encoded, forKey: "watchBooks")
        }
    }

    private func loadFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: "watchBooks"),
           let decoded = try? JSONDecoder().decode([BookInfo].self, from: data) {
            books = decoded
        }
        for book in books {
            if let words = loadBookContent(bookID: book.id) {
                bookContents[book.id] = words
            }
        }
    }

    private func saveBookContent(bookID: UUID, words: [String]) {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent("\(bookID.uuidString).json")
        if let data = try? JSONEncoder().encode(words) {
            try? data.write(to: url)
        }
    }

    private func loadBookContent(bookID: UUID) -> [String]? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent("\(bookID.uuidString).json")
        if let data = try? Data(contentsOf: url),
           let words = try? JSONDecoder().decode([String].self, from: data) {
            return words
        }
        return nil
    }
}

// Notification.Name extensions are in Shared/Services/NotificationNames.swift
