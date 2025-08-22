import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Word.createdAt, ascending: true)], animation: .default)
    private var words: FetchedResults<Word>
    
    @State private var showAddWord = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 환영 메시지
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to VocaTo!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Let's improve your vocabulary today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // 주요 통계 카드들
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        GlassCard(title: "Total Words", subtitle: "\(words.count)", systemImage: "book.fill")
                        GlassCard(title: "Favorites", subtitle: "\(favoriteWords.count)", systemImage: "star.fill")
                        GlassCard(title: "Today's Goal", subtitle: "\(todayGoal)", systemImage: "target")
                        GlassCard(title: "Streak", subtitle: "\(currentStreak) days", systemImage: "flame.fill")
                    }
                    .padding(.horizontal)
                    
                    // 학습 진행상황
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Learning Progress")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            ProgressRow(label: "New", value: stage0Words.count, total: words.count, color: .red)
                            ProgressRow(label: "Learning", value: stage1Words.count, total: words.count, color: .orange)
                            ProgressRow(label: "Reviewing", value: stage2Words.count, total: words.count, color: .blue)
                            ProgressRow(label: "Mastered", value: stage3Words.count, total: words.count, color: .green)
                        }
                        .padding(.horizontal)
                    }
                    
                    // 그룹별 단어 현황
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("그룹별 단어 현황")
                                .font(.headline)
                            
                            Spacer()
                            
                            NavigationLink(destination: GroupManagementView()) {
                                Text("자세히 보기")
                                    .font(.caption)
                                    .foregroundStyle(Color("PrimaryGreen"))
                            }
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(WordGroup.allCases, id: \.self) { group in
                                    VStack(spacing: 8) {
                                        Image(systemName: group.systemImage)
                                            .font(.title2)
                                            .foregroundStyle(Color("PrimaryGreen"))
                                        
                                        Text(group.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .multilineTextAlignment(.center)
                                        
                                        Text("\(getWordCount(for: group))")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.primary)
                                    }
                                    .frame(width: 80)
                                    .padding()
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 다음 복습할 단어
                    if let nextWord = nextReviewWord {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Next Review")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            GlassCard(
                                title: nextWord.term ?? "",
                                subtitle: "Due: \(nextWord.nextReviewDate?.formatted(date: .abbreviated, time: .omitted) ?? "Today")",
                                systemImage: "clock"
                            )
                            .padding(.horizontal)
                        }
                    }
                    
                    // 즐겨찾기된 단어들
                    if !favoriteWords.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Favorite Words")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(favoriteWords.prefix(5), id: \.uuid) { word in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(word.term ?? "")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text(word.meaning ?? "")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding()
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                        .frame(width: 120)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // 빠른 액션 버튼들
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            Button {
                                showAddWord = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(Color("PrimaryGreen"))
                                    Text("Add Word")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: StudyHubView()) {
                                VStack(spacing: 8) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.title)
                                        .foregroundStyle(.blue)
                                    Text("Start Study")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("VocaTo")
            .sheet(isPresented: $showAddWord) {
                AddOrEditWordView(wordToEdit: nil)
            }
        }
    }
    
    // 계산된 속성들
    private var favoriteWords: [Word] {
        words.filter { $0.isFavorite }
    }
    
    private var stage0Words: [Word] {
        words.filter { $0.srsStage == 0 }
    }
    
    private var stage1Words: [Word] {
        words.filter { $0.srsStage == 1 }
    }
    
    private var stage2Words: [Word] {
        words.filter { $0.srsStage == 2 }
    }
    
    private var stage3Words: [Word] {
        words.filter { $0.srsStage == 3 }
    }
    
    private var nextReviewWord: Word? {
        words.sorted(by: { ($0.nextReviewDate ?? .distantFuture) < ($1.nextReviewDate ?? .distantFuture) }).first
    }
    
    private var todayGoal: String {
        let todayCount = words.filter { word in
            guard let nextReview = word.nextReviewDate else { return false }
            return Calendar.current.isDateInToday(nextReview)
        }.count
        return "\(todayCount) words"
    }
    
    private var currentStreak: Int {
        // 간단한 연속 학습 일수 계산 (실제로는 더 복잡한 로직이 필요)
        let recentWords = words.sorted(by: { ($0.nextReviewDate ?? .distantPast) > ($1.nextReviewDate ?? .distantPast) })
        var streak = 0
        let calendar = Calendar.current
        var currentDate = Date()
        
        for _ in 0..<30 { // 최대 30일 체크
            let dayWords = recentWords.filter { word in
                guard let reviewDate = word.nextReviewDate else { return false }
                return calendar.isDate(reviewDate, inSameDayAs: currentDate)
            }
            
            if !dayWords.isEmpty {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func getWordCount(for group: WordGroup) -> Int {
        switch group {
        case .all:
            return words.count
        case .new:
            return words.filter { $0.srsStage == 0 }.count
        case .learning:
            return words.filter { $0.srsStage == 1 }.count
        case .reviewing:
            return words.filter { $0.srsStage >= 2 && $0.srsStage <= 4 }.count
        case .mastered:
            return words.filter { $0.isMastered }.count
        case .favorites:
            return words.filter { $0.isFavorite }.count
        }
    }
}

// MARK: - Group Management View
struct GroupManagementView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Word.createdAt, ascending: true)], animation: .default)
    private var words: FetchedResults<Word>
    
    @State private var selectedGroup: WordGroup = .all
    @State private var showAddWordOptions = false
    
    var filteredWords: [Word] {
        switch selectedGroup {
        case .all:
            return Array(words)
        case .new:
            return words.filter { $0.srsStage == 0 }
        case .learning:
            return words.filter { $0.srsStage == 1 }
        case .reviewing:
            return words.filter { $0.srsStage >= 2 && $0.srsStage <= 4 }
        case .mastered:
            return words.filter { $0.isMastered }
        case .favorites:
            return words.filter { $0.isFavorite }
        }
    }
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // 좌측 그룹 선택 패널
                VStack(alignment: .leading, spacing: 8) {
                    Text("그룹")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    ForEach(WordGroup.allCases, id: \.self) { group in
                        Button {
                            selectedGroup = group
                        } label: {
                            HStack {
                                Image(systemName: group.systemImage)
                                    .foregroundColor(selectedGroup == group ? .white : Color("PrimaryGreen"))
                                Text(group.rawValue)
                                    .foregroundColor(selectedGroup == group ? .white : .primary)
                                Spacer()
                                Text("\(getWordCount(for: group))")
                                    .foregroundColor(selectedGroup == group ? .white : .secondary)
                                    .font(.caption)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(
                                selectedGroup == group ? 
                                Color("PrimaryGreen") : 
                                Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 8)
                    }
                    
                    Spacer()
                }
                .frame(width: 200)
                .background(.ultraThinMaterial)
                
                // 우측 단어 리스트 패널
                VStack {
                    HStack {
                        Text("\(selectedGroup.rawValue) (\(filteredWords.count))")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            showAddWordOptions = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color("PrimaryGreen"))
                        }
                    }
                    .padding()
                    
                    if filteredWords.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("단어가 없습니다")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(filteredWords, id: \.objectID) { word in
                            WordRowView(word: word)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("그룹 관리")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showAddWordOptions) {
            AddWordOptionsView()
        }
    }
    
    private func getWordCount(for group: WordGroup) -> Int {
        switch group {
        case .all:
            return words.count
        case .new:
            return words.filter { $0.srsStage == 0 }.count
        case .learning:
            return words.filter { $0.srsStage == 1 }.count
        case .reviewing:
            return words.filter { $0.srsStage >= 2 && $0.srsStage <= 4 }.count
        case .mastered:
            return words.filter { $0.isMastered }.count
        case .favorites:
            return words.filter { $0.isFavorite }.count
        }
    }
}

// MARK: - Word Row View
struct WordRowView: View {
    let word: Word
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.term ?? "")
                    .font(.headline)
                Text(word.meaning ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                // 중요도 표시
                if word.importanceCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("\(word.importanceCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.yellow.opacity(0.2))
                    .clipShape(Capsule())
                }
                
                // 즐겨찾기 표시
                if word.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // 마스터 상태 표시
                if word.isMastered {
                    HStack(spacing: 2) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("마스터")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.yellow.opacity(0.2))
                    .clipShape(Capsule())
                } else {
                    // 정확도 표시 (마스터가 아닌 경우에만)
                    if word.accuracyCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("\(word.accuracyCount)/15")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.2))
                        .clipShape(Capsule())
                    }
                    
                    // SRS 단계 표시
                    Text("Stage \(word.srsStage)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color("PrimaryGreen").opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

