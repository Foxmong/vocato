import SwiftUI
import CoreData

struct RecommendedWordsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @State private var selectedCategories: Set<WordCategory> = [.basic, .daily]
    @State private var selectedWords: Set<String> = []
    @State private var showSuccessAlert = false
    
    private let recommendedWords: [WordCategory: [RecommendedWord]] = [
        .basic: [
            RecommendedWord(term: "hello", meaning: "안녕하세요", memo: "기본 인사말", synonyms: "hi, hey"),
            RecommendedWord(term: "goodbye", meaning: "안녕히 가세요", memo: "작별 인사", synonyms: "bye, see you"),
            RecommendedWord(term: "thank you", meaning: "감사합니다", memo: "고마움 표현", synonyms: "thanks, thx"),
            RecommendedWord(term: "please", meaning: "제발", memo: "정중한 요청", synonyms: "kindly, if you would"),
            RecommendedWord(term: "sorry", meaning: "죄송합니다", memo: "사과 표현", synonyms: "apologize, excuse me"),
            RecommendedWord(term: "yes", meaning: "네", memo: "긍정 응답", synonyms: "yeah, sure, okay"),
            RecommendedWord(term: "no", meaning: "아니요", memo: "부정 응답", synonyms: "nope, not really"),
            RecommendedWord(term: "water", meaning: "물", memo: "기본 음료", synonyms: "H2O, aqua"),
            RecommendedWord(term: "food", meaning: "음식", memo: "먹는 것", synonyms: "meal, cuisine"),
            RecommendedWord(term: "house", meaning: "집", memo: "거주 공간", synonyms: "home, residence")
        ],
        .daily: [
            RecommendedWord(term: "morning", meaning: "아침", memo: "하루의 시작", synonyms: "AM, dawn"),
            RecommendedWord(term: "afternoon", meaning: "오후", memo: "점심 후 시간", synonyms: "PM, midday"),
            RecommendedWord(term: "evening", meaning: "저녁", memo: "일과 후 시간", synonyms: "night, dusk"),
            RecommendedWord(term: "breakfast", meaning: "아침 식사", memo: "첫 번째 식사", synonyms: "morning meal"),
            RecommendedWord(term: "lunch", meaning: "점심 식사", memo: "두 번째 식사", synonyms: "noon meal"),
            RecommendedWord(term: "dinner", meaning: "저녁 식사", memo: "마지막 식사", synonyms: "supper, evening meal"),
            RecommendedWord(term: "work", meaning: "일", memo: "직업 활동", synonyms: "job, employment"),
            RecommendedWord(term: "study", meaning: "공부", memo: "학습 활동", synonyms: "learn, research"),
            RecommendedWord(term: "sleep", meaning: "잠", memo: "휴식 시간", synonyms: "rest, nap"),
            RecommendedWord(term: "exercise", meaning: "운동", memo: "신체 활동", synonyms: "workout, training")
        ],
        .business: [
            RecommendedWord(term: "meeting", meaning: "회의", memo: "업무 논의", synonyms: "conference, discussion"),
            RecommendedWord(term: "project", meaning: "프로젝트", memo: "업무 계획", synonyms: "task, assignment"),
            RecommendedWord(term: "deadline", meaning: "마감일", memo: "완료 기한", synonyms: "due date, limit"),
            RecommendedWord(term: "client", meaning: "고객", memo: "서비스 이용자", synonyms: "customer, patron"),
            RecommendedWord(term: "budget", meaning: "예산", memo: "재정 계획", synonyms: "finance, cost"),
            RecommendedWord(term: "report", meaning: "보고서", memo: "업무 문서", synonyms: "document, summary"),
            RecommendedWord(term: "presentation", meaning: "발표", memo: "업무 소개", synonyms: "speech, talk"),
            RecommendedWord(term: "team", meaning: "팀", memo: "협업 그룹", synonyms: "group, crew"),
            RecommendedWord(term: "goal", meaning: "목표", memo: "달성하고자 하는 것", synonyms: "objective, target"),
            RecommendedWord(term: "success", meaning: "성공", memo: "목표 달성", synonyms: "achievement, victory")
        ],
        .travel: [
            RecommendedWord(term: "airport", meaning: "공항", memo: "비행기 이용", synonyms: "airfield, terminal"),
            RecommendedWord(term: "hotel", meaning: "호텔", memo: "숙박 시설", synonyms: "inn, lodge"),
            RecommendedWord(term: "restaurant", meaning: "레스토랑", memo: "외식 장소", synonyms: "cafe, diner"),
            RecommendedWord(term: "museum", meaning: "박물관", memo: "문화 시설", synonyms: "gallery, exhibit"),
            RecommendedWord(term: "beach", meaning: "해변", memo: "바닷가", synonyms: "shore, coast"),
            RecommendedWord(term: "mountain", meaning: "산", memo: "자연 지형", synonyms: "peak, hill"),
            RecommendedWord(term: "city", meaning: "도시", memo: "도시 지역", synonyms: "town, metropolis"),
            RecommendedWord(term: "country", meaning: "국가", memo: "국가", synonyms: "nation, state"),
            RecommendedWord(term: "language", meaning: "언어", memo: "의사소통 수단", synonyms: "tongue, speech"),
            RecommendedWord(term: "culture", meaning: "문화", memo: "사회적 관습", synonyms: "tradition, custom")
        ]
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categorySelectionView
                wordListView
            }
            .navigationTitle("추천 단어장")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("추가") {
                        addSelectedWords()
                    }
                    .disabled(selectedWords.isEmpty)
                }
            }
            .alert("단어 추가 완료", isPresented: $showSuccessAlert) {
                Button("확인") {
                    dismiss()
                }
            } message: {
                Text("선택한 \(selectedWords.count)개의 단어가 추가되었습니다.")
            }
        }
    }
    
    private var categorySelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(WordCategory.allCases, id: \.self) { category in
                    categoryButton(for: category)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
    }
    
    private func categoryButton(for category: WordCategory) -> some View {
        Button {
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }
        } label: {
            Text(category.displayName)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedCategories.contains(category) ? Color("PrimaryGreen") : Color.gray.opacity(0.1))
                .foregroundStyle(selectedCategories.contains(category) ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
    
    private var wordListView: some View {
        List {
            ForEach(selectedCategories.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { category in
                Section(category.displayName) {
                    ForEach(recommendedWords[category] ?? [], id: \.term) { word in
                        wordRowView(for: word)
                    }
                }
            }
        }
    }
    
    private func wordRowView(for word: RecommendedWord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.term)
                    .font(.headline)
                Text(word.meaning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !word.memo.isEmpty {
                    Text(word.memo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                if selectedWords.contains(word.term) {
                    selectedWords.remove(word.term)
                } else {
                    selectedWords.insert(word.term)
                }
            } label: {
                Image(systemName: selectedWords.contains(word.term) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selectedWords.contains(word.term) ? Color("PrimaryGreen") : .gray)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func addSelectedWords() {
        for category in selectedCategories {
            for word in recommendedWords[category] ?? [] {
                if selectedWords.contains(word.term) {
                    let newWord = Word(context: context)
                    newWord.uuid = UUID().uuidString
                    newWord.term = word.term
                    newWord.meaning = word.meaning
                    newWord.memo = word.memo.isEmpty ? nil : word.memo
                    newWord.synonyms = word.synonyms.isEmpty ? nil : word.synonyms
                    newWord.createdAt = Date()
                    newWord.srsStage = 0
                    newWord.correctCount = 0
                    newWord.wrongCount = 0
                    newWord.isFavorite = false
                }
            }
        }
        
        do {
            try context.save()
            showSuccessAlert = true
        } catch {
            print("Save error: \(error)")
        }
    }
}

struct RecommendedWord {
    let term: String
    let meaning: String
    let memo: String
    let synonyms: String
}

enum WordCategory: Int, CaseIterable {
    case basic = 0
    case daily = 1
    case business = 2
    case travel = 3
    
    var displayName: String {
        switch self {
        case .basic: return "기본"
        case .daily: return "일상"
        case .business: return "비즈니스"
        case .travel: return "여행"
        }
    }
}
