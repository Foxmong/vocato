import SwiftUI
import CoreData

struct AddOrEditWordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    
    @State private var term = ""
    @State private var meaning = ""
    @State private var memo = ""
    @State private var synonyms = ""
    @State private var isFavorite = false
    
    let word: Word?
    
    init(word: Word? = nil) {
        self.word = word
        if let word = word {
            _term = State(initialValue: word.term ?? "")
            _meaning = State(initialValue: word.meaning ?? "")
            _memo = State(initialValue: word.memo ?? "")
            _synonyms = State(initialValue: word.synonyms ?? "")
            _isFavorite = State(initialValue: word.isFavorite)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("단어 정보") {
                    TextField("단어", text: $term)
                    TextField("뜻", text: $meaning)
                    TextField("메모 (선택사항)", text: $memo)
                    TextField("동의어 (선택사항)", text: $synonyms)
                    Toggle("즐겨찾기", isOn: $isFavorite)
                }
            }
            .navigationTitle(word == nil ? "단어 추가" : "단어 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        saveWord()
                    }
                    .disabled(term.isEmpty || meaning.isEmpty)
                }
            }
        }
    }
    
    private func saveWord() {
        let wordToSave = word ?? Word(context: context)
        
        wordToSave.uuid = wordToSave.uuid ?? UUID().uuidString
        wordToSave.term = term
        wordToSave.meaning = meaning
        wordToSave.memo = memo.isEmpty ? nil : memo
        wordToSave.synonyms = synonyms.isEmpty ? nil : synonyms
        wordToSave.isFavorite = isFavorite
        wordToSave.createdAt = wordToSave.createdAt ?? Date()
        wordToSave.srsStage = wordToSave.srsStage
        wordToSave.correctCount = wordToSave.correctCount
        wordToSave.wrongCount = wordToSave.wrongCount
        wordToSave.importanceCount = wordToSave.importanceCount
        wordToSave.accuracyCount = wordToSave.accuracyCount
        wordToSave.lastAccuracyDate = wordToSave.lastAccuracyDate
        wordToSave.isMastered = wordToSave.isMastered
        
        do {
            try context.save()
            dismiss() 
        } catch { 
            print("Save error: \(error)") 
        }
    }
}