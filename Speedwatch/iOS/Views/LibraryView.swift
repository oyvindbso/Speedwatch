import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.lastOpened, ascending: false)],
        animation: .default)
    private var books: FetchedResults<Book>

    @State private var showingImporter = false
    @State private var selectedBook: Book?

    var body: some View {
        NavigationView {
            Group {
                if books.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        Text("No Books Yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Button("Import EPUB") {
                            showingImporter = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                            ForEach(books) { book in
                                BookCard(book: book)
                                    .onTapGesture {
                                        selectedBook = book
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingImporter = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [UTType(filenameExtension: "epub")!],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .sheet(item: $selectedBook) { book in
                ReaderView(book: book)
            }
        }
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            do {
                // Start accessing security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    print("Couldn't access security-scoped resource")
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }

                // Parse EPUB
                let content = try EPUBParser.parse(fileURL: url)

                // Save to app documents directory
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let bookFileName = "\(UUID().uuidString).epub"
                let destinationURL = documentsPath.appendingPathComponent(bookFileName)
                try FileManager.default.copyItem(at: url, to: destinationURL)

                // Create book in Core Data
                let book = Book.create(
                    in: viewContext,
                    title: content.metadata.title,
                    author: content.metadata.author,
                    filePath: bookFileName,
                    totalWords: content.words.count
                )

                if let coverImage = content.metadata.coverImage,
                   let imageData = coverImage.jpegData(compressionQuality: 0.7) {
                    book.coverImageData = imageData
                }

                // Save words to separate file
                let wordsFileName = "\(book.id.uuidString).json"
                let wordsURL = documentsPath.appendingPathComponent(wordsFileName)
                let wordsData = try JSONEncoder().encode(content.words)
                try wordsData.write(to: wordsURL)

                try viewContext.save()

            } catch {
                print("Error importing book: \(error.localizedDescription)")
            }

        case .failure(let error):
            print("Error selecting file: \(error.localizedDescription)")
        }
    }
}

struct BookCard: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image
            Group {
                if let imageData = book.coverImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "book.closed")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipped()
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                if let author = book.author {
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Progress bar
                ProgressView(value: book.progress)
                    .tint(.blue)

                Text("\(Int(book.progress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
