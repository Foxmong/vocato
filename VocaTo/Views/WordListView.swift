import SwiftUI
import CoreData

struct WordsView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var vm: WordListViewModel
    @State private var showAddOptions = false
    @State private var wordToEdit: Word? = nil
    @State private var showFavoritesOnly = false
    @State private var wordToDelete: Word? = nil
    @State private var showDeleteAlert = false

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Word.createdAt, ascending: false)], animation: .default)
    private var words: FetchedResults<Word>

    init() {
        let context = PersistenceController.shared.container.viewContext
        _vm = StateObject(wrappedValue: WordListViewModel(context: context))
    }
    
    private var filteredWords: [Word] {
        let allWords = Array(words)
        if showFavoritesOnly {
            return allWords.filter { $0.isFavorite }
        }
        return allWords
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 상단 헤더
                VStack(spacing: 16) {
                    // 통계 요약
                    HStack {
                        VStack(alignment: .leading) {
                            Text("총 단어")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(words.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("오늘 학습")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(todayStudyCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color("PrimaryGreen"))
                        }
                    }
                    .padding(.horizontal)
                    
                    // 즐겨찾기 토글
                    HStack {
                        Toggle("즐겨찾기만", isOn: $showFavoritesOnly)
                            .toggleStyle(.switch)
                            .tint(Color("PrimaryGreen"))
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(.ultraThinMaterial)
                
                // 단어 목록
                List {
                    ForEach(filteredWords, id: \.uuid) { word in
                        NavigationLink(destination: WordDetailView(word: word)) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(word.term ?? "")
                                        .font(.headline)
                                    Spacer()
                                    Button {
                                        toggleFavorite(word)
                                    } label: {
                                        Image(systemName: word.isFavorite ? "star.fill" : "star")
                                            .foregroundStyle(word.isFavorite ? .yellow : .gray)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Text(word.meaning ?? "")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                // SRS 단계 표시
                                HStack {
                                    Text("Stage \(word.srsStage)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(stageColor(for: word.srsStage).opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Spacer()
                                    
                                    if let nextReview = word.nextReviewDate {
                                        Text("다음: \(nextReview.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .contextMenu {
                            Button(word.isFavorite ? "즐겨찾기 해제" : "즐겨찾기 추가") {
                                toggleFavorite(word)
                            }
                            Button("편집") {
                                wordToEdit = word
                            }
                            Button("삭제", role: .destructive) {
                                wordToDelete = word
                                showDeleteAlert = true
                            }
                        }
                    }.onDelete(perform: delete)
                }
            }
            .searchable(text: $vm.searchText, prompt: "단어 검색")
            .navigationTitle("단어")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddOptions = true
                    } label: { 
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddOptions) {
                AddWordOptionsView()
            }
            .sheet(item: $wordToEdit) { word in
                AddOrEditWordView(wordToEdit: word)
            }
            .alert("단어 삭제", isPresented: $showDeleteAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    if let word = wordToDelete {
                        deleteWord(word)
                        wordToDelete = nil
                    }
                }
            } message: {
                if let word = wordToDelete {
                    Text("'\(word.term ?? "")'를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.")
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let wordsToDelete = offsets.map { filteredWords[$0] }
        wordsToDelete.forEach(context.delete)
        do { try context.save() } catch { print(error) }
    }
    
    private func deleteWord(_ word: Word) {
        context.delete(word)
        do { try context.save() } catch { print(error) }
    }
    
    private func toggleFavorite(_ word: Word) {
        word.isFavorite.toggle()
        do { try context.save() } catch { print(error) }
    }
    
    private var todayStudyCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return words.filter { word in
            guard let nextReview = word.nextReviewDate else { return false }
            return calendar.isDate(nextReview, inSameDayAs: today)
        }.count
    }
    
    private func stageColor(for stage: Int16) -> Color {
        switch stage {
        case 0: return .red
        case 1: return .orange
        case 2: return .blue
        case 3: return .green
        default: return .gray
        }
    }
}

struct WordDetailView: View {
    @ObservedObject var word: Word
    @State private var isPresentingEdit = false
    
    var body: some View {
        Form {
            Section("Term") { 
                HStack { 
                    Text(word.term ?? "")
                    Spacer()
                    Button {
                        SpeechService.shared.speak(word.term ?? "", languageCode: "en-US")
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
            Section("Meaning") { 
                HStack { 
                    Text(word.meaning ?? "")
                    Spacer()
                    Button {
                        SpeechService.shared.speak(word.meaning ?? "", languageCode: "ko-KR")
                    } label: {
                        Image(systemName: "speaker.wave.2")
                    }
                    .buttonStyle(.plain)
                }
            }
            if let memo = word.memo, !memo.isEmpty { Section("Memo") { Text(memo) } }
            if let syn = word.synonyms, !syn.isEmpty { Section("Synonyms") { Text(syn) } }
            Section("Statistics") {
                HStack { Text("Correct"); Spacer(); Text("\(word.correctCount)").foregroundStyle(.green) }
                HStack { Text("Wrong"); Spacer(); Text("\(word.wrongCount)").foregroundStyle(.red) }
                HStack { Text("SRS Stage"); Spacer(); Text("\(word.srsStage)").foregroundStyle(.blue) }
            }
        }
        .navigationTitle(word.term ?? "Detail")
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Edit") { isPresentingEdit = true } } }
        .sheet(isPresented: $isPresentingEdit) { AddOrEditWordView(wordToEdit: word) }
    }
}

