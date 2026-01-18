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

    func sendBooks(_ books: [BookInfo]) {
        guard let session = session, session.isReachable else { return }

        do {
            let data = try JSONEncoder().encode(books)
            let message = ["books": data]
            session.sendMessage(message, replyHandler: nil) { error in
                print("Error sending books: \(error.localizedDescription)")
            }
        } catch {
            print("Error encoding books: \(error.localizedDescription)")
        }
    }

    func sendBookContent(bookID: UUID, words: [String]) {
        guard let session = session, session.isReachable else { return }

        do {
            let data = try JSONEncoder().encode(words)
            let message = ["bookContent": data, "bookID": bookID.uuidString]
            session.sendMessage(message, replyHandler: nil) { error in
                print("Error sending book content: \(error.localizedDescription)")
            }
        } catch {
            print("Error encoding book content: \(error.localizedDescription)")
        }
    }

    func updateReadingPosition(bookID: UUID, position: Int) {
        guard let session = session else { return }

        let message = [
            "positionUpdate": true,
            "bookID": bookID.uuidString,
            "position": position
        ] as [String : Any]

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil)
        } else {
            do {
                try session.updateApplicationContext(message)
            } catch {
                print("Error updating context: \(error.localizedDescription)")
            }
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let positionUpdate = message["positionUpdate"] as? Bool, positionUpdate,
           let bookIDString = message["bookID"] as? String,
           let bookID = UUID(uuidString: bookIDString),
           let position = message["position"] as? Int {

            DispatchQueue.main.async {
                self.updateLocalPosition(bookID: bookID, position: position)
            }
        }
    }

    private func updateLocalPosition(bookID: UUID, position: Int) {
        let context = DataController.shared.container.viewContext
        let fetchRequest = Book.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", bookID as CVarArg)

        if let book = try? context.fetch(fetchRequest).first {
            book.currentPosition = Int64(position)
            DataController.shared.save()
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
