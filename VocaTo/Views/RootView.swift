import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppViewModel
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            TabView {
                HomeView()
                    .tabItem { 
                        Label("단어", systemImage: "book.fill") 
                    }

                StudyHubView()
                    .tabItem { 
                        Label("학습", systemImage: "brain.head.profile") 
                    }

                StatsView()
                    .tabItem { 
                        Label("통계", systemImage: "chart.bar.fill") 
                    }
            }
            .environment(\.managedObjectContext, app.persistence.container.viewContext)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .environmentObject(app)
                        .navigationTitle("설정")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("완료") {
                                    showSettings = false
                                }
                            }
                        }
                }
            }
        }
    }
}

struct StudyHubView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var studyVM: StudyViewModel
    
    init() {
        let ctx = PersistenceController.shared.container.viewContext
        _studyVM = StateObject(wrappedValue: StudyViewModel(context: ctx))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                NavigationLink(destination: StudySettingsView(initialQuizMode: .flashcards, studyVM: studyVM)) {
                    GlassCard(title: "Flashcards", subtitle: "Swipe to review", systemImage: "rectangle.on.rectangle.angled")
                }
                NavigationLink(destination: StudySettingsView(initialQuizMode: .multipleChoice, studyVM: studyVM)) {
                    GlassCard(title: "Multiple Choice", subtitle: "Pick the meaning", systemImage: "checkmark.circle")
                }
                NavigationLink(destination: StudySettingsView(initialQuizMode: .dictation, studyVM: studyVM)) {
                    GlassCard(title: "받아쓰기", subtitle: "Type the answer", systemImage: "pencil.and.outline")
                }
                NavigationLink(destination: StudySettingsView(initialQuizMode: .autoPlay, studyVM: studyVM)) {
                    GlassCard(title: "자동재생", subtitle: "Auto play with TTS", systemImage: "play.circle")
                }
            }
            .padding()
            .navigationTitle("학습")
        }
    }
}

// MARK: - Study Settings View
struct StudySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var studyVM: StudyViewModel
    @State private var settings: StudySettings
    @State private var navigateToStudy = false
    
    init(initialQuizMode: QuizMode = .flashcards, studyVM: StudyViewModel) {
        self.studyVM = studyVM
        var initialSettings = StudySettings()
        initialSettings.quizMode = initialQuizMode
        _settings = State(initialValue: initialSettings)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    WordGroupSelectionView(selectedGroup: $settings.wordGroup)
                    QuizModeSelectionView(selectedMode: $settings.quizMode)
                    
                    if settings.quizMode == .autoPlay {
                        AutoPlaySettingsSection(
                            autoPlayMode: $settings.autoPlayMode,
                            autoPlayInterval: $settings.autoPlayInterval
                        )
                    }
                    
                    QuestionCountSection(questionCount: $settings.questionCount)
                    DifficultySelectionView(selectedDifficulty: $settings.difficulty)
                    FavoritesToggleView(includeFavorites: $settings.includeFavorites)
                    
                    StartStudyButton {
                        startStudy()
                    }
                }
                .padding()
            }
            .navigationTitle("학습 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .background(
                NavigationLink(
                    destination: destinationView,
                    isActive: $navigateToStudy
                ) { EmptyView() }
            )
        }
    }
    
    @ViewBuilder
    private var destinationView: some View {
        switch settings.quizMode {
        case .flashcards:
            StudyFlashcardsView()
                .environmentObject(studyVM)
        case .multipleChoice:
            StudyMCQView()
                .environmentObject(studyVM)
        case .dictation:
            StudyDictationView()
                .environmentObject(studyVM)
        case .autoPlay:
            StudyAutoPlayView()
                .environmentObject(studyVM)
        }
    }
    
    private func startStudy() {
        // 설정을 StudyViewModel에 적용
        studyVM.studySettings = settings
        studyVM.autoPlayMode = settings.autoPlayMode
        studyVM.autoPlayInterval = settings.autoPlayInterval
        studyVM.loadStudyQueue(with: settings)
        
        // 학습 화면으로 이동
        navigateToStudy = true
    }
}

// MARK: - Study Dictation View
struct StudyDictationView: View {
    @EnvironmentObject var vm: StudyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var userInput = ""
    @State private var showAnswer = false
    @State private var isShowingTerm = Bool.random() // 랜덤으로 단어 또는 뜻 표시
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                if !vm.todaysQueue.isEmpty {
                    // 진행률
                    HStack {
                        Text("\(vm.currentIndex + 1) / \(vm.todaysQueue.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        
                        // 중요도 표시
                        let word = vm.todaysQueue[vm.currentIndex]
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
                    }
                    .padding(.horizontal)
                    
                    let word = vm.todaysQueue[vm.currentIndex]
                    
                    // 문제 표시
                    VStack(spacing: 16) {
                        Text(isShowingTerm ? (word.term ?? "") : (word.meaning ?? ""))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        Text(isShowingTerm ? "뜻을 입력하세요" : "단어를 입력하세요")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // 입력 필드
                    VStack(spacing: 16) {
                        TextField("답을 입력하세요", text: $userInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.title2)
                            .padding(.horizontal)
                        
                        if showAnswer {
                            Text("정답: \(isShowingTerm ? (word.meaning ?? "") : (word.term ?? ""))")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                                .padding()
                                .background(.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                    
                    // 버튼들
                    VStack(spacing: 16) {
                        if !showAnswer {
                            Button("정답 확인") {
                                checkAnswer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("PrimaryGreen"))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                        
                        Button(showAnswer ? "다음" : "잘 모르겠어요") {
                            if showAnswer {
                                nextWord()
                            } else {
                                dontKnow()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(showAnswer ? Color("PrimaryGreen") : .gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        Text("학습 완료!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationTitle("받아쓰기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("종료") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func checkAnswer() {
        let word = vm.todaysQueue[vm.currentIndex]
        let correctAnswer = isShowingTerm ? (word.meaning ?? "") : (word.term ?? "")
        
        if userInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) != 
           correctAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
            vm.increaseImportanceCount(for: word)
        }
        
        showAnswer = true
    }
    
    private func dontKnow() {
        let word = vm.todaysQueue[vm.currentIndex]
        vm.increaseImportanceCount(for: word)
        showAnswer = true
    }
    
    private func nextWord() {
        userInput = ""
        showAnswer = false
        isShowingTerm = Bool.random()
        vm.advance()
    }
}

// MARK: - Study Auto Play View
struct StudyAutoPlayView: View {
    @EnvironmentObject var vm: StudyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                if !vm.todaysQueue.isEmpty {
                    // 진행률
                    HStack {
                        Text("\(vm.currentIndex + 1) / \(vm.todaysQueue.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        
                        // 중요도 표시
                        let word = vm.todaysQueue[vm.currentIndex]
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
                    }
                    .padding(.horizontal)
                    
                    let word = vm.todaysQueue[vm.currentIndex]
                    
                    // 단어 카드
                    VStack(spacing: 20) {
                        Text(word.term ?? "")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Divider()
                        
                        Text(word.meaning ?? "")
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal)
                    .onTapGesture {
                        if vm.isAutoPlaying {
                            vm.pauseAutoPlay()
                        } else {
                            vm.resumeAutoPlay()
                        }
                    }
                    
                    // 자동재생 상태
                    HStack {
                        Image(systemName: vm.isAutoPlaying ? "play.fill" : "pause.fill")
                            .foregroundColor(Color("PrimaryGreen"))
                        Text(vm.isAutoPlaying ? "자동재생 중" : "일시정지")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryGreen"))
                    }
                    .padding()
                    .background(Color("PrimaryGreen").opacity(0.1))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    // 컨트롤 버튼들
                    HStack(spacing: 20) {
                        Button {
                            if vm.isAutoPlaying {
                                vm.pauseAutoPlay()
                            } else {
                                vm.resumeAutoPlay()
                            }
                        } label: {
                            Image(systemName: vm.isAutoPlaying ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color("PrimaryGreen"))
                                .clipShape(Circle())
                        }
                        
                        Button("중지") {
                            vm.stopAutoPlay()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.gray)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        
                        Button("알아요") {
                            vm.advance()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color("PrimaryGreen"))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        
                        Button("설정") {
                            showSettings = true
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.secondary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        Text("학습 완료!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationTitle("자동재생")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("종료") {
                        vm.stopAutoPlay()
                        dismiss()
                    }
                }
            }
            .onAppear {
                vm.startAutoPlay()
            }
            .onDisappear {
                vm.stopAutoPlay()
            }
        }
        .sheet(isPresented: $showSettings) {
            AutoPlaySettingsView(vm: vm)
        }
    }
}

// MARK: - Auto Play Settings View
struct AutoPlaySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: StudyViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 재생 모드 선택
                VStack(alignment: .leading, spacing: 16) {
                    Text("재생 모드")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        ForEach(AutoPlayMode.allCases, id: \.self) { mode in
                            Button {
                                vm.autoPlayMode = mode
                            } label: {
                                HStack {
                                    Image(systemName: mode.systemImage)
                                        .foregroundColor(vm.autoPlayMode == mode ? Color("PrimaryGreen") : .gray)
                                    Text(mode.rawValue)
                                        .foregroundColor(vm.autoPlayMode == mode ? .primary : .secondary)
                                    Spacer()
                                    if vm.autoPlayMode == mode {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color("PrimaryGreen"))
                                    }
                                }
                                .padding()
                                .background(
                                    vm.autoPlayMode == mode ? 
                                    Color("PrimaryGreen").opacity(0.1) : 
                                    .clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // 재생 간격 설정
                VStack(alignment: .leading, spacing: 16) {
                    Text("재생 간격")
                        .font(.headline)
                    
                    HStack {
                        Text("\(Int(vm.autoPlayInterval))초")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color("PrimaryGreen"))
                            .frame(width: 80)
                        
                        Slider(value: $vm.autoPlayInterval, in: 1...10, step: 1)
                            .tint(Color("PrimaryGreen"))
                    }
                    
                    Text("1초에서 10초까지 설정 가능합니다")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("자동재생 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}

