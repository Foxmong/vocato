import Foundation
import CoreData

// MARK: - Study Types (Global scope for sharing across files)
struct StudySettings {
    var wordGroup: WordGroup = .all
    var quizMode: QuizMode = .flashcards
    var questionCount: Int = 10
    var includeFavorites: Bool = false
    var autoPlayMode: AutoPlayMode = .both
    var autoPlayInterval: Double = 3.0
}

enum WordGroup: String, CaseIterable {
    case all = "전체 단어"
    case new = "새로운 단어"
    case learning = "학습 중인 단어"
    case reviewing = "복습 단어"
    case mastered = "마스터된 단어"
    case favorites = "즐겨찾기"
    case difficult = "어려운 단어"
    
    var systemImage: String {
        switch self {
        case .all: return "book.fill"
        case .new: return "star.circle"
        case .learning: return "brain.head.profile"
        case .reviewing: return "arrow.clockwise"
        case .mastered: return "checkmark.seal.fill"
        case .favorites: return "heart.fill"
        case .difficult: return "exclamationmark.triangle.fill"
        }
    }
    
    var iconName: String {
        return systemImage
    }
    
    var displayName: String {
        return self.rawValue
    }
}

enum QuizMode: String, CaseIterable {
    case flashcards = "플래시카드"
    case multipleChoice = "객관식"
    case dictation = "받아쓰기"
    case autoPlay = "자동재생"
    
    var systemImage: String {
        switch self {
        case .flashcards: return "rectangle.on.rectangle.angled"
        case .multipleChoice: return "checkmark.circle"
        case .dictation: return "pencil.and.outline"
        case .autoPlay: return "play.circle"
        }
    }
    
    var iconName: String {
        return systemImage
    }
    
    var displayName: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .flashcards: return "카드를 뒤집어 정답 확인"
        case .multipleChoice: return "4개 선택지 중 정답 선택"
        case .dictation: return "듣고 타이핑으로 입력"
        case .autoPlay: return "자동으로 단어와 뜻 재생"
        }
    }
}

enum AutoPlayMode: String, CaseIterable {
    case meaningOnly = "뜻만 읽기"
    case termOnly = "단어만 읽기"
    case both = "둘 다 읽기"
    case none = "읽지 않기"
    
    var systemImage: String {
        switch self {
        case .meaningOnly: return "text.bubble"
        case .termOnly: return "text.bubble.fill"
        case .both: return "text.bubble.fill"
        case .none: return "text.bubble"
        }
    }
}




final class StudyViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    @Published var todaysQueue: [Word] = []
    @Published var currentIndex: Int = 0
    @Published var isAutoAdvanceEnabled: Bool = false
    @Published var hasUnfinishedSession: Bool = false
    @Published var studySettings: StudySettings = StudySettings()
    @Published var autoPlayMode: AutoPlayMode = .both
    @Published var autoPlayInterval: Double = 3.0
    @Published var isAutoPlaying: Bool = false
    @Published var autoPlayTimer: Timer?
    
    private let sessionProgressKey = "StudySessionProgress"
    private let sessionCurrentIndexKey = "StudySessionCurrentIndex"

    init(context: NSManagedObjectContext) {
        self.context = context
        loadTodaysQueue()
        checkUnfinishedSession()
    }

    // 중요도 카운트 증가
    func increaseImportanceCount(for word: Word) {
        word.importanceCount += 1
        save()
    }
    
    // 중요도 카운트 감소 (최소 0)
    func decreaseImportanceCount(for word: Word) {
        if word.importanceCount > 0 {
            word.importanceCount -= 1
            save()
        }
    }
    
    // 정확도 카운트 증가 (1일 최대 1회)
    func increaseAccuracyCount(for word: Word) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 오늘 이미 정확도를 증가했는지 확인
        if let lastDate = word.lastAccuracyDate,
           Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return // 오늘 이미 증가했으므로 무시
        }
        
        word.accuracyCount += 1
        word.lastAccuracyDate = Date()
        
        // 15회 달성시 마스터 처리
        if word.accuracyCount >= 15 {
            word.isMastered = true
        }
        
        save()
    }
    
    // 마스터 상태 토글
    func toggleMasterStatus(for word: Word) {
        word.isMastered.toggle()
        save()
    }
    
    // 자동재생 시작
    func startAutoPlay() {
        isAutoPlaying = true
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: autoPlayInterval, repeats: true) { _ in
            self.advanceAutoPlay()
        }
    }
    
    // 자동재생 정지
    func stopAutoPlay() {
        isAutoPlaying = false
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }
    
    // 자동재생 일시정지
    func pauseAutoPlay() {
        isAutoPlaying = false
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }
    
    // 자동재생 재개
    func resumeAutoPlay() {
        isAutoPlaying = true
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: autoPlayInterval, repeats: true) { _ in
            self.advanceAutoPlay()
        }
    }
    
    // 자동재생으로 다음 단어로 이동
    private func advanceAutoPlay() {
        guard !todaysQueue.isEmpty else { return }
        
        // 현재 단어 읽기
        readCurrentWord()
        
        // 다음 단어로 이동
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.advance()
        }
    }
    
    // 현재 단어 읽기
    private func readCurrentWord() {
        guard !todaysQueue.isEmpty, currentIndex < todaysQueue.count else { return }
        let word = todaysQueue[currentIndex]
        
        switch autoPlayMode {
        case .meaningOnly:
            SpeechService.shared.speakMeaning(word.meaning ?? "")
        case .termOnly:
            SpeechService.shared.speakTerm(word.term ?? "")
        case .both:
            SpeechService.shared.speakTerm(word.term ?? "")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                SpeechService.shared.speakMeaning(word.meaning ?? "")
            }
        case .none:
            break
        }
    }

    // 설정된 값에 따라 학습할 단어들을 로드
    func loadStudyQueue(with settings: StudySettings) {
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        var predicates: [NSPredicate] = []
        
        // 단어 그룹에 따른 필터링
        switch settings.wordGroup {
        case .all:
            break
        case .new:
            predicates.append(NSPredicate(format: "srsStage == 0"))
        case .learning:
            predicates.append(NSPredicate(format: "srsStage == 1"))
        case .reviewing:
            predicates.append(NSPredicate(format: "srsStage == 2"))
        case .mastered:
            predicates.append(NSPredicate(format: "isMastered == true"))
        case .favorites:
            predicates.append(NSPredicate(format: "isFavorite == true"))
        case .difficult:
            predicates.append(NSPredicate(format: "importanceCount > 0"))
        }
        
        // 즐겨찾기 포함 여부
        if settings.includeFavorites && settings.wordGroup != .favorites {
            predicates.append(NSPredicate(format: "isFavorite == true"))
        }
        
        // 복습 날짜 체크
        let now = Date()
        predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "nextReviewDate == nil"),
            NSPredicate(format: "nextReviewDate <= %@", now as NSDate)
        ]))
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        // 중요도가 높은 단어를 우선적으로 정렬
        request.sortDescriptors = [
            NSSortDescriptor(key: "importanceCount", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        
        do {
            let allWords = try context.fetch(request)
            // 설정된 문제 수만큼만 선택
            if settings.questionCount > 0 && settings.questionCount < allWords.count {
                todaysQueue = Array(allWords.prefix(settings.questionCount))
            } else {
                todaysQueue = allWords
            }
            currentIndex = 0
        } catch {
            todaysQueue = []
            currentIndex = 0
        }
    }

    func loadTodaysQueue() {
        loadStudyQueue(with: studySettings)
    }
    
    func loadUnfinishedSession() {
        let defaults = UserDefaults.standard
        if let savedProgress = defaults.array(forKey: sessionProgressKey) as? [String],
           let savedIndex = defaults.object(forKey: sessionCurrentIndexKey) as? Int {
            
            let request: NSFetchRequest<Word> = Word.fetchRequest()
            request.predicate = NSPredicate(format: "uuid IN %@", savedProgress)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            
            do {
                todaysQueue = try context.fetch(request)
                currentIndex = min(savedIndex, todaysQueue.count - 1)
                hasUnfinishedSession = false
            } catch {
                todaysQueue = []
                currentIndex = 0
            }
        }
    }
    
    private func checkUnfinishedSession() {
        let defaults = UserDefaults.standard
        hasUnfinishedSession = defaults.object(forKey: sessionProgressKey) != nil
    }

    func answerCurrent(correct: Bool) {
        guard !todaysQueue.isEmpty, currentIndex < todaysQueue.count else { return }
        let word = todaysQueue[currentIndex]
        if correct {
            word.correctCount += 1
            word.srsStage = min(word.srsStage + 1, 3)
        } else {
            word.wrongCount += 1
            word.srsStage = 0
        }
        word.nextReviewDate = Self.nextReviewDate(forStage: Int(word.srsStage))
        save()
        advance()
    }

    func advance() {
        currentIndex = min(currentIndex + 1, max(todaysQueue.count - 1, 0))
    }
    
    func saveSessionProgress() {
        let defaults = UserDefaults.standard
        let progress = todaysQueue.map { $0.uuid ?? "" }
        defaults.set(progress, forKey: sessionProgressKey)
        defaults.set(currentIndex, forKey: sessionCurrentIndexKey)
        hasUnfinishedSession = true
    }
    
    func completeSession() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: sessionProgressKey)
        defaults.removeObject(forKey: sessionCurrentIndexKey)
        hasUnfinishedSession = false
        
        // 세션 완료 후 다음 학습 일정 업데이트
        loadTodaysQueue()
    }

    static func nextReviewDate(forStage stage: Int) -> Date {
        let days: Int
        switch stage {
        case 0: days = 1
        case 1: days = 3
        default: days = 7
        }
        return Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }

    func multipleChoiceOptions(for word: Word, count: Int = 4) -> [String] {
        var options: [String] = []
        if let meaning = word.meaning, !meaning.isEmpty {
            options.append(meaning)
        }
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        request.fetchLimit = 50
        if let pool = try? context.fetch(request) {
            for candidate in pool.shuffled() {
                guard candidate.objectID != word.objectID else { continue }
                if options.count >= count { break }
                if let m = candidate.meaning, !m.isEmpty, !options.contains(m) {
                    options.append(m)
                }
            }
        }
        return options.shuffled()
    }

    private func save() {
        do { try context.save() } catch { print("Save error: \(error)") }
    }
}

