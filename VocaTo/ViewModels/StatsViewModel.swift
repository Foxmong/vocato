import Foundation
import CoreData

final class StatsViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    @Published var todayCount: Int = 0
    @Published var accuracy: Double = 0.0
    @Published var totalWords: Int = 0
    @Published var favoriteWords: Int = 0
    @Published var stage0Count: Int = 0
    @Published var stage1Count: Int = 0
    @Published var stage2Count: Int = 0
    @Published var stage3Count: Int = 0
    @Published var recentWords: [Word] = []
    @Published var studySecondsToday: Int = 0
    
    private var currentTimeRange: TimeRange = .week

    init(context: NSManagedObjectContext) {
        self.context = context
        loadStats()
    }
    
    func updateTimeRange(_ timeRange: TimeRange) {
        currentTimeRange = timeRange
        loadStats()
    }

    func loadStats() {
        loadTodayStats()
        loadOverallStats()
        loadStageStats()
        loadRecentWords()
        studySecondsToday = DailyStudyTracker.shared.todaySeconds()
    }
    
    private func loadTodayStats() {
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 오늘 학습한 단어들 (nextReviewDate가 오늘로 업데이트된 단어들)
        request.predicate = NSPredicate(format: "nextReviewDate >= %@ AND nextReviewDate < %@", 
                                      today as NSDate, 
                                      calendar.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let todayWords = try context.fetch(request)
            todayCount = todayWords.count
            
            // 정확도 계산
            let totalAttempts = todayWords.reduce(0) { $0 + $1.correctCount + $1.wrongCount }
            if totalAttempts > 0 {
                let totalCorrect = todayWords.reduce(0) { $0 + $1.correctCount }
                accuracy = Double(totalCorrect) / Double(totalAttempts)
            } else {
                accuracy = 0.0
            }
        } catch {
            todayCount = 0
            accuracy = 0.0
        }
    }
    
    private func loadOverallStats() {
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        
        do {
            let allWords = try context.fetch(request)
            totalWords = allWords.count
            favoriteWords = allWords.filter { $0.isFavorite }.count
        } catch {
            totalWords = 0
            favoriteWords = 0
        }
    }
    
    private func loadStageStats() {
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        
        do {
            let allWords = try context.fetch(request)
            stage0Count = allWords.filter { $0.srsStage == 0 }.count
            stage1Count = allWords.filter { $0.srsStage == 1 }.count
            stage2Count = allWords.filter { $0.srsStage == 2 }.count
            stage3Count = allWords.filter { $0.srsStage == 3 }.count
        } catch {
            stage0Count = 0
            stage1Count = 0
            stage2Count = 0
            stage3Count = 0
        }
    }
    
    private func loadRecentWords() {
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        
        // 최근에 nextReviewDate가 업데이트된 단어들을 가져옴
        request.sortDescriptors = [NSSortDescriptor(key: "nextReviewDate", ascending: false)]
        request.fetchLimit = 10
        
        do {
            recentWords = try context.fetch(request)
        } catch {
            recentWords = []
        }
    }
}

