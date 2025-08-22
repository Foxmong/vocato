import SwiftUI
import CoreData

struct StudyFlashcardsView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var app: AppViewModel
    @EnvironmentObject private var vm: StudyViewModel
    @State private var isShowingMeaning: Bool = false
    @State private var timer: Timer?
    @State private var showSessionAlert = false
    @State private var sessionStartTime: Date = Date()

    var body: some View {
        VStack(spacing: 16) {
            if vm.todaysQueue.isEmpty {
                VStack(spacing: 12) {
                    Text("No cards to study today")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    if vm.hasUnfinishedSession {
                        Button("Continue Previous Session") {
                            vm.loadUnfinishedSession()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                // 학습 진행률 표시
                HStack {
                    Text("\(vm.currentIndex + 1) / \(vm.todaysQueue.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    
                    // 중요도 표시
                    let word = vm.todaysQueue[vm.currentIndex]
                    if word.importanceCount > 0 {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text("\(word.importanceCount)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                }
                
                let word = vm.todaysQueue[vm.currentIndex]
                GlassCardLarge(title: word.term ?? "", subtitle: isShowingMeaning ? (word.meaning ?? "") : "Tap to reveal", systemImage: "rectangle.portrait.on.rectangle.portrait.angled")
                    .onTapGesture { withAnimation { isShowingMeaning.toggle() } }
                
                // TTS 버튼
                HStack(spacing: 16) {
                    Button {
                        SpeechService.shared.speakTerm(word.term ?? "")
                    } label: {
                        Label("단어 읽기", systemImage: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        SpeechService.shared.speakMeaning(word.meaning ?? "")
                    } label: {
                        Label("뜻 읽기", systemImage: "speaker.wave.2")
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 16) {
                    Button(role: .destructive) {
                        answer(false)
                    } label: {
                        Label("틀렸어요", systemImage: "xmark")
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        answer(true)
                    } label: {
                        Label("맞았어요", systemImage: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                }

                Toggle("Auto advance", isOn: $vm.isAutoAdvanceEnabled)
                HStack {
                    Image(systemName: "tortoise")
                    Slider(value: Binding(get: { app.studyAutoAdvanceSpeed }, set: app.updateAutoAdvanceSpeed), in: 1...5, step: 0.5)
                    Image(systemName: "hare")
                }
                .tint(Color("PrimaryGreen"))
                
                // 세션 관리 버튼
                HStack {
                    Button("Pause Session") {
                        showSessionAlert = true
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("End Session") {
                        endSession()
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .navigationTitle("Flashcards")
        .onAppear {
            sessionStartTime = Date()
            DailyStudyTracker.shared.startSession()
        }
        .onChange(of: vm.isAutoAdvanceEnabled) { enabled in
            timer?.invalidate(); timer = nil
            if enabled {
                timer = Timer.scheduledTimer(withTimeInterval: app.studyAutoAdvanceSpeed, repeats: true) { _ in
                    withAnimation { vm.advance() }
                }
            }
        }
        .onDisappear { 
            timer?.invalidate()
            // 세션 중단 시 저장
            if !vm.todaysQueue.isEmpty && vm.currentIndex < vm.todaysQueue.count {
                vm.saveSessionProgress()
            }
            DailyStudyTracker.shared.endSession()
        }
        .alert("Pause Session", isPresented: $showSessionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Pause") {
                pauseSession()
            }
        } message: {
            Text("Your progress will be saved. You can continue later from where you left off.")
        }
    }

    private func answer(_ correct: Bool) {
        let word = vm.todaysQueue[vm.currentIndex]
        
        if correct {
            // 맞췄을 때 정확도 카운트 증가 (1일 최대 1회)
            vm.increaseAccuracyCount(for: word)
        } else {
            // 틀렸을 때 중요도 카운트 증가
            vm.increaseImportanceCount(for: word)
        }
        
        withAnimation { vm.answerCurrent(correct: correct); isShowingMeaning = false }
    }
    
    private func pauseSession() {
        vm.saveSessionProgress()
        // 홈 화면으로 돌아가기
        // 이는 NavigationStack을 통해 처리됩니다
    }
    
    private func endSession() {
        vm.completeSession()
        // 세션 완료 후 통계 업데이트
    }
    
    private var sessionDuration: String {
        let duration = Date().timeIntervalSince(sessionStartTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

