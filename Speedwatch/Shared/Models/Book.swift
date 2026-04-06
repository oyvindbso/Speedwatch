import Foundation
import CoreData

@objc(Book)
public class Book: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var author: String?
    @NSManaged public var coverImageData: Data?
    @NSManaged public var filePath: String
    @NSManaged public var dateAdded: Date
    @NSManaged public var lastOpened: Date?
    @NSManaged public var currentPosition: Int64
    @NSManaged public var totalWords: Int64
}

extension Book {
    static func create(
        in context: NSManagedObjectContext,
        title: String,
        author: String?,
        filePath: String,
        totalWords: Int
    ) -> Book {
        let book = Book(context: context)
        book.id = UUID()
        book.title = title
        book.author = author
        book.filePath = filePath
        book.dateAdded = Date()
        book.currentPosition = 0
        book.totalWords = Int64(totalWords)
        return book
    }

    var progress: Double {
        guard totalWords > 0 else { return 0 }
        return Double(currentPosition) / Double(totalWords)
    }

    var bookInfo: BookInfo {
        BookInfo(
            id: id,
            title: title,
            author: author,
            currentPosition: Int(currentPosition),
            totalWords: Int(totalWords)
        )
    }
}
