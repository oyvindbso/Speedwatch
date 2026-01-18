import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var bookManager: WatchBookManager

    var body: some View {
        NavigationView {
            if bookManager.books.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No Books")
                        .font(.headline)
                    Text("Add books from your iPhone")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List(bookManager.books) { book in
                    NavigationLink(destination: WatchReaderView(book: book)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.headline)
                                .lineLimit(2)

                            if let author = book.author {
                                Text(author)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            ProgressView(value: Double(book.currentPosition) / Double(book.totalWords))
                                .tint(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Library")
            }
        }
    }
}
