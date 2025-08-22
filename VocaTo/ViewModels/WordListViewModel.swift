import Foundation
import CoreData

final class WordListViewModel: ObservableObject {
    private let context: NSManagedObjectContext

    @Published var searchText: String = ""

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func addWord(term: String, meaning: String, memo: String?, synonyms: String?) {
        let word = Word(context: context)
        word.uuid = UUID().uuidString
        word.term = term
        word.meaning = meaning
        word.memo = memo
        word.synonyms = synonyms
        word.createdAt = Date()
        word.srsStage = 0
        word.correctCount = 0
        word.wrongCount = 0
        word.isFavorite = false
        save()
    }

    func delete(_ word: Word) {
        context.delete(word)
        save()
    }

    func save() {
        do { try context.save() } catch { print("Save error: \(error)") }
    }
}

