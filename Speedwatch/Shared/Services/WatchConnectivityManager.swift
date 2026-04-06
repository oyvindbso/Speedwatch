import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isReachable = false
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    func updateReadingPosition(bookID: UUID, position: Int) {
        guard let session = session else { return }

        let message: [String: Any] = [
            "positionUpdate": true,
            "bookID": bookID.uuidString,
            "position": position
        ]

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil)
        } else {
            try? session.updateApplicationContext(message)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let positionUpdate = message["positionUpdate"] as? Bool, positionUpdate,
           let bookIDString = message["bookID"] as? String,
           let bookID = UUID(uuidString: bookIDString),
           let position = message["position"] as? Int {
            DispatchQueue.main.async {
                self.handlePositionUpdate(bookID: bookID, position: position)
            }
        }
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        // Handle position updates received while app was in background
        session(session, didReceiveMessage: applicationContext)
    }

    private func handlePositionUpdate(bookID: UUID, position: Int) {
#if os(iOS)
        let context = DataController.shared.container.viewContext
        let fetchRequest = Book.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", bookID as CVarArg)
        if let book = try? context.fetch(fetchRequest).first {
            book.currentPosition = Int64(position)
            DataController.shared.save()
        }
#else
        // Notify the WatchBookManager about the position update
        NotificationCenter.default.post(
            name: .receivedPositionUpdate,
            object: nil,
            userInfo: ["bookID": bookID, "position": position]
        )
#endif
    }

#if os(iOS)
    // MARK: iOS-only: send library to watch

    func sendBooks(_ books: [BookInfo]) {
        guard let session = session, session.isReachable else { return }
        guard let data = try? JSONEncoder().encode(books) else { return }
        session.sendMessage(["books": data], replyHandler: nil)
    }

    func sendBookContent(bookID: UUID, words: [String]) {
        guard let session = session, session.isReachable else { return }
        guard let data = try? JSONEncoder().encode(words) else { return }
        let message: [String: Any] = ["bookContent": data, "bookID": bookID.uuidString]
        session.sendMessage(message, replyHandler: nil)
    }

    // MARK: iOS-only WCSessionDelegate methods

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        // iOS receives requests from the watch
        if message["requestBooks"] as? Bool == true {
            let context = DataController.shared.container.viewContext
            let fetchRequest = Book.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Book.lastOpened, ascending: false)]
            if let books = try? context.fetch(fetchRequest) {
                let bookInfos = books.map { $0.bookInfo }
                if let data = try? JSONEncoder().encode(bookInfos) {
                    replyHandler(["books": data])
                    return
                }
            }
        }

        if let bookIDString = message["requestBookContent"] as? String,
           let bookID = UUID(uuidString: bookIDString) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let wordsURL = documentsPath.appendingPathComponent("\(bookID.uuidString).json")
            if let data = try? Data(contentsOf: wordsURL) {
                replyHandler(["bookContent": data, "bookID": bookIDString])
                return
            }
        }

        replyHandler([:])
    }
#endif

#if os(watchOS)
    // MARK: watchOS-only: request data from iPhone

    func requestBooks() {
        guard let session = session, session.isReachable else { return }
        session.sendMessage(["requestBooks": true], replyHandler: { response in
            if let data = response["books"] as? Data,
               let books = try? JSONDecoder().decode([BookInfo].self, from: data) {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .receivedBooks,
                        object: nil,
                        userInfo: ["books": books]
                    )
                }
            }
        })
    }

    func requestBookContent(bookID: UUID) {
        guard let session = session, session.isReachable else { return }
        session.sendMessage(["requestBookContent": bookID.uuidString], replyHandler: { response in
            if let contentData = response["bookContent"] as? Data,
               let bookIDString = response["bookID"] as? String,
               let bookID = UUID(uuidString: bookIDString),
               let words = try? JSONDecoder().decode([String].self, from: contentData) {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .receivedBookContent,
                        object: nil,
                        userInfo: ["bookID": bookID, "words": words]
                    )
                }
            }
        })
    }
#endif
}
