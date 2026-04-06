import Foundation
import UIKit
import ZIPFoundation

// MARK: - EPUBParser

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

    enum EPUBError: Error {
        case invalidFormat
        case parsingFailed(String)
    }

    // MARK: - Public API

    static func parse(fileURL: URL) throws -> EPUBContent {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // EPUB is a ZIP archive
        try FileManager.default.unzipItem(at: fileURL, to: tempDir)

        // Find content.opf via container.xml
        let containerURL = tempDir.appendingPathComponent("META-INF/container.xml")
        guard let containerData = try? Data(contentsOf: containerURL) else {
            throw EPUBError.invalidFormat
        }
        guard let rootfilePath = extractAttribute(from: containerData,
                                                  element: "rootfile",
                                                  attribute: "full-path") else {
            throw EPUBError.invalidFormat
        }

        let opfURL = tempDir.appendingPathComponent(rootfilePath)
        let contentDir = opfURL.deletingLastPathComponent()
        guard let opfData = try? Data(contentsOf: opfURL) else {
            throw EPUBError.parsingFailed("Cannot read \(rootfilePath)")
        }

        let opfInfo = parseOPF(data: opfData, contentDir: contentDir)

        let words = readSpine(opfData: opfData, contentDir: contentDir)

        let metadata = EPUBMetadata(
            title: opfInfo.title,
            author: opfInfo.author,
            coverImage: opfInfo.coverImage
        )
        return EPUBContent(metadata: metadata, words: words)
    }

    // MARK: - OPF Parsing (metadata + manifest + spine)

    private struct OPFInfo {
        var title: String = "Unknown"
        var author: String? = nil
        var coverImage: UIImage? = nil
    }

    private static func parseOPF(data: Data, contentDir: URL) -> OPFInfo {
        let handler = OPFHandler()
        let parser = XMLParser(data: data)
        parser.delegate = handler
        parser.parse()

        var info = OPFInfo()
        info.title = handler.title ?? "Unknown"
        info.author = handler.author

        // Resolve cover image
        if let coverID = handler.coverMetaID,
           let href = handler.manifest[coverID] {
            let imgURL = contentDir.appendingPathComponent(href)
            if let imgData = try? Data(contentsOf: imgURL) {
                info.coverImage = UIImage(data: imgData)
            }
        }
        // Fallback: find manifest item with id containing "cover" that is an image
        if info.coverImage == nil {
            for (id, href) in handler.manifest
            where id.lowercased().contains("cover") && isImagePath(href) {
                let imgURL = contentDir.appendingPathComponent(href)
                if let imgData = try? Data(contentsOf: imgURL) {
                    info.coverImage = UIImage(data: imgData)
                    break
                }
            }
        }
        return info
    }

    private static func isImagePath(_ href: String) -> Bool {
        let lower = href.lowercased()
        return lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg")
            || lower.hasSuffix(".png") || lower.hasSuffix(".gif")
    }

    // MARK: - Spine / text extraction

    private static func readSpine(opfData: Data, contentDir: URL) -> [String] {
        let handler = OPFHandler()
        let parser = XMLParser(data: opfData)
        parser.delegate = handler
        parser.parse()

        var words: [String] = []
        for idref in handler.spineOrder {
            guard let href = handler.manifest[idref] else { continue }
            let fileURL = contentDir.appendingPathComponent(href)
            guard let raw = try? Data(contentsOf: fileURL),
                  let html = String(data: raw, encoding: .utf8) ?? String(data: raw, encoding: .isoLatin1) else { continue }
            words.append(contentsOf: wordsFrom(html: html))
        }
        return words
    }

    private static func wordsFrom(html: String) -> [String] {
        // Strip script/style blocks first
        var text = html
            .replacingOccurrences(of: "<(script|style)[^>]*>.*?</(script|style)>",
                                   with: " ",
                                   options: [.regularExpression, .caseInsensitive])
        // Remove remaining tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        // Decode entities
        let entities: [String: String] = [
            "&nbsp;": " ", "&amp;": "&", "&lt;": "<",
            "&gt;": ">", "&quot;": "\"", "&#39;": "'"
        ]
        entities.forEach { text = text.replacingOccurrences(of: $0.key, with: $0.value) }
        return text
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters.union(.whitespaces)) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Minimal XML attribute extractor (for container.xml)

    private static func extractAttribute(from data: Data,
                                         element: String,
                                         attribute: String) -> String? {
        class Handler: NSObject, XMLParserDelegate {
            let targetElement: String
            let targetAttribute: String
            var result: String?
            init(element: String, attribute: String) {
                self.targetElement = element; self.targetAttribute = attribute
            }
            func parser(_ parser: XMLParser,
                        didStartElement elementName: String,
                        namespaceURI: String?,
                        qualifiedName qName: String?,
                        attributes attributeDict: [String: String] = [:]) {
                if elementName == targetElement || elementName.hasSuffix(":\(targetElement)") {
                    result = attributeDict[targetAttribute]
                    if result != nil { parser.abortParsing() }
                }
            }
        }
        let handler = Handler(element: element, attribute: attribute)
        let parser = XMLParser(data: data)
        parser.delegate = handler
        parser.parse()
        return handler.result
    }
}

// MARK: - OPFHandler (SAX delegate for content.opf)

private class OPFHandler: NSObject, XMLParserDelegate {
    // Metadata
    var title: String?
    var author: String?
    var coverMetaID: String?   // id from <meta name="cover" content="..."/>

    // Manifest: id → href
    var manifest: [String: String] = [:]

    // Spine: ordered list of idrefs
    var spineOrder: [String] = [:]

    // State
    private var currentElement: String = ""
    private var currentText: String = ""

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attrs: [String: String] = [:]) {
        let local = localName(elementName)
        currentElement = local
        currentText = ""

        switch local {
        case "item":
            if let id = attrs["id"], let href = attrs["href"] {
                manifest[id] = href
            }
        case "itemref":
            if let idref = attrs["idref"] {
                spineOrder.append(idref)
            }
        case "meta":
            // <meta name="cover" content="cover-image"/>
            if attrs["name"]?.lowercased() == "cover", let content = attrs["content"] {
                coverMetaID = content
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        let local = localName(elementName)
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch local {
        case "title" where title == nil:
            title = text.isEmpty ? nil : text
        case "creator" where author == nil:
            author = text.isEmpty ? nil : text
        default:
            break
        }
        currentText = ""
    }

    private func localName(_ name: String) -> String {
        // Strip namespace prefix (e.g. "dc:title" → "title")
        name.components(separatedBy: ":").last ?? name
    }
}
