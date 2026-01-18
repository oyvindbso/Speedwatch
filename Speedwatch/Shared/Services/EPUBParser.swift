import Foundation
import UIKit

class EPUBParser {
    struct EPUBMetadata {
        let title: String
        let author: String?
        let coverImage: UIImage?
    }

    struct EPUBContent {
        let metadata: EPUBMetadata
        let words: [String]
    }

    static func parse(fileURL: URL) throws -> EPUBContent {
        // Create a temporary directory to extract EPUB
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // EPUB is a ZIP file
        try FileManager.default.unzipItem(at: fileURL, to: tempDir)

        // Read container.xml to find content.opf location
        let containerPath = tempDir.appendingPathComponent("META-INF/container.xml")
        guard let containerData = try? Data(contentsOf: containerPath),
              let containerXML = try? XMLDocument(data: containerData),
              let rootfilePath = try? containerXML.nodes(forXPath: "//*[local-name()='rootfile']/@full-path").first?.stringValue else {
            throw EPUBError.invalidFormat
        }

        let contentOPFPath = tempDir.appendingPathComponent(rootfilePath)
        let contentDir = contentOPFPath.deletingLastPathComponent()

        guard let opfData = try? Data(contentsOf: contentOPFPath),
              let opfXML = try? XMLDocument(data: opfData) else {
            throw EPUBError.invalidFormat
        }

        // Extract metadata
        let title = try? opfXML.nodes(forXPath: "//*[local-name()='title']").first?.stringValue ?? "Unknown"
        let author = try? opfXML.nodes(forXPath: "//*[local-name()='creator']").first?.stringValue

        // Try to find cover image
        var coverImage: UIImage?
        if let coverID = try? opfXML.nodes(forXPath: "//*[local-name()='meta'][@name='cover']/@content").first?.stringValue,
           let coverHref = try? opfXML.nodes(forXPath: "//*[local-name()='item'][@id='\(coverID)']/@href").first?.stringValue {
            let coverPath = contentDir.appendingPathComponent(coverHref)
            if let imageData = try? Data(contentsOf: coverPath) {
                coverImage = UIImage(data: imageData)
            }
        }

        let metadata = EPUBMetadata(title: title ?? "Unknown", author: author, coverImage: coverImage)

        // Get spine (reading order)
        let spineItems = try opfXML.nodes(forXPath: "//*[local-name()='spine']/*[local-name()='itemref']/@idref")
        var allWords: [String] = []

        for spineItem in spineItems {
            guard let idref = spineItem.stringValue,
                  let href = try? opfXML.nodes(forXPath: "//*[local-name()='item'][@id='\(idref)']/@href").first?.stringValue else {
                continue
            }

            let contentPath = contentDir.appendingPathComponent(href)
            if let htmlData = try? Data(contentsOf: contentPath),
               let htmlString = String(data: htmlData, encoding: .utf8) {
                let words = extractWords(from: htmlString)
                allWords.append(contentsOf: words)
            }
        }

        return EPUBContent(metadata: metadata, words: allWords)
    }

    private static func extractWords(from html: String) -> [String] {
        // Remove HTML tags
        var text = html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)

        // Decode HTML entities
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")

        // Split into words
        let components = text.components(separatedBy: .whitespacesAndNewlines)
        return components
            .map { $0.trimmingCharacters(in: .punctuationCharacters.union(.whitespaces)) }
            .filter { !$0.isEmpty }
    }

    enum EPUBError: Error {
        case invalidFormat
        case fileNotFound
    }
}

// Helper extension for unzipping
extension FileManager {
    func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
        // This would normally use a library like ZIPFoundation
        // For now, we'll use the system unzip command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", sourceURL.path, "-d", destinationURL.path]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw EPUBParser.EPUBError.invalidFormat
        }
    }
}
