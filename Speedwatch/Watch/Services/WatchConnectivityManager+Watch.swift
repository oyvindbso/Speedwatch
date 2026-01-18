import Foundation
import WatchConnectivity

extension WatchConnectivityManager {
    func requestBooks() {
        guard let session = session, session.isReachable else { return }

        let message = ["requestBooks": true]
        session.sendMessage(message, replyHandler: nil) { error in
            print("Error requesting books: \(error.localizedDescription)")
        }
    }

    func requestBookContent(bookID: UUID) {
        guard let session = session, session.isReachable else { return }

        let message = ["requestBookContent": bookID.uuidString]
        session.sendMessage(message, replyHandler: nil) { error in
            print("Error requesting book content: \(error.localizedDescription)")
        }
    }
}

// Watch-specific delegate methods
extension WatchConnectivityManager {
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let booksData = message["books"] as? Data {
            if let books = try? JSONDecoder().decode([BookInfo].self, from: booksData) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ReceivedBooks"),
                    object: books
                )
            }
        }

        if let contentData = message["bookContent"] as? Data,
           let bookIDString = message["bookID"] as? String,
           let bookID = UUID(uuidString: bookIDString) {
            if let words = try? JSONDecoder().decode([String].self, from: contentData) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ReceivedBookContent"),
                    object: (bookID, words)
                )
            }
        }

        replyHandler([:])
    }
}
