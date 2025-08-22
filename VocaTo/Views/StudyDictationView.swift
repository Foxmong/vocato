import SwiftUI
import CoreData

struct StudyDictationView: View {
    @EnvironmentObject private var vm: StudyViewModel
    @State private var userInput: String = ""
    @State private var showAnswer: Bool = false
    @State private var isCorrect: Bool = false
    @State private var feedback: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            if vm.todaysQueue.isEmpty {
                VStack(spacing: 12) {
                    Text("학습할 단어가 없습니다")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            } else {
                let word = vm.todaysQueue[vm.currentIndex]
                
                // 진행률 표시
                HStack {
                    Text("\(vm.currentIndex + 1) / \(vm.todaysQueue.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    
                    // 중요도 표시
                    ImportanceIndicator(importanceCount: word.importanceCount)
                }
                
                // 문제 표시 (단어 또는 뜻 중 하나만 표시)
                VStack(spacing: 16) {
                    Text("다음에 해당하는 것을 입력하세요:")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    if Bool.random() { // 랜덤하게 단어 또는 뜻 표시
                        Text(word.term ?? "")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("→ 뜻을 입력하세요")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(word.meaning ?? "")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("→ 단어를 입력하세요")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // 답안 입력
                VStack(spacing: 12) {
                    TextField("답을 입력하세요", text: $userInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .disabled(showAnswer)
                    
                    if !showAnswer {
                        HStack(spacing: 16) {
                            Button("정답 확인") {
                                checkAnswer()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            
                            Button("잘 모르겠어요") {
                                handleDontKnow()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // 정답 표시 및 피드백
                if showAnswer {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(isCorrect ? .green : .red)
                            
                            Text(feedback)
                                .font(.headline)
                                .foregroundStyle(isCorrect ? .green : .red)
                        }
                        
                        if !isCorrect {
                            VStack(spacing: 8) {
                                Text("정답:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                if Bool.random() { // 랜덤하게 단어 또는 뜻 표시했으므로 반대 표시
                                    Text(word.meaning ?? "")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                } else {
                                    Text(word.term ?? "")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button("다음") {
                            nextWord()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .navigationTitle("받아쓰기")
        .onAppear {
            resetState()
        }
    }
    
    private func checkAnswer() {
        let input = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let word = vm.todaysQueue[vm.currentIndex]
        
        // 정답 확인 (대소문자 무시, 공백 무시)
        let correctAnswer = Bool.random() ? word.meaning : word.term
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespaces)
        let normalizedAnswer = (correctAnswer ?? "").lowercased().trimmingCharacters(in: .whitespaces)
        
        isCorrect = normalizedInput == normalizedAnswer
        feedback = isCorrect ? "정답입니다!" : "틀렸습니다"
        
        if !isCorrect {
            vm.increaseImportanceCount(for: word)
        }
        
        showAnswer = true
    }
    
    private func handleDontKnow() {
        let word = vm.todaysQueue[vm.currentIndex]
        vm.increaseImportanceCount(for: word)
        
        isCorrect = false
        feedback = "잘 모르겠어요"
        showAnswer = true
    }
    
    private func nextWord() {
        vm.advance()
        resetState()
    }
    
    private func resetState() {
        userInput = ""
        showAnswer = false
        isCorrect = false
        feedback = ""
    }
}

#Preview {
    StudyDictationView()
        .environmentObject(StudyViewModel(context: PersistenceController.shared.container.viewContext))
}
