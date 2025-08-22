import Foundation
import UniformTypeIdentifiers
import CoreData
import SwiftUI

final class CSVService {
    static let shared = CSVService()
    private init() {}

    func importCSV(from url: URL) throws {
        let data = try Data(contentsOf: url)
        guard let csv = String(data: data, encoding: .utf8) else { return }
        let lines = csv.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let context = PersistenceController.shared.container.viewContext
        for line in lines.dropFirstIfHasHeader() {
            let cols = line.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            guard cols.count >= 2 else { continue }
            let term = cols[0]
            let meaning = cols[1]
            let memo = cols.count > 2 ? cols[2] : nil
            let synonyms = cols.count > 3 ? cols[3] : nil
            let w = Word(context: context)
            w.uuid = UUID().uuidString; w.term = term; w.meaning = meaning; w.memo = memo; w.synonyms = synonyms; w.createdAt = Date(); w.srsStage = 0
        }
        try context.save()
    }

    func exportCSV() throws -> URL {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        let words = try context.fetch(request)
        var rows: [String] = ["term,meaning,memo,synonyms"]
        for w in words {
            let row = [w.term ?? "", w.meaning ?? "", w.memo ?? "", w.synonyms ?? ""].map { escapeCSV($0) }.joined(separator: ",")
            rows.append(row)
        }
        let csv = rows.joined(separator: "\n")
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("VocaTo_Export.csv")
        try csv.data(using: .utf8)?.write(to: tmp, options: .atomic)
        return tmp
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\n") || value.contains("\"") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}

extension Array where Element == String {
    func dropFirstIfHasHeader() -> ArraySlice<String> {
        if let first = first, first.lowercased().contains("term") && first.lowercased().contains("meaning") {
            return dropFirst()
        }
        return ArraySlice(self)
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var url: URL
    init(url: URL) { self.url = url }
    init(configuration: ReadConfiguration) throws { self.url = URL(fileURLWithPath: "") }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { try FileWrapper(url: url, options: []) }
}

