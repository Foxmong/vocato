import SwiftUI
import CoreData

struct StudyMCQView: View {
    @EnvironmentObject private var app: AppViewModel
    @EnvironmentObject private var vm: StudyViewModel
    @State private var selected: String? = nil
    @State private var feedback: String = ""

    var body: some View {
        VStack(spacing: 16) {
            if vm.todaysQueue.isEmpty {
                Text("No questions today")
            } else {
                let word = vm.todaysQueue[vm.currentIndex]
                Text(word.term ?? "")
                    .font(.largeTitle.bold())
                let options = vm.multipleChoiceOptions(for: word)
                ForEach(options, id: \.self) { opt in
                    Button {
                        selected = opt
                        let isCorrect = opt == word.meaning
                        
                        if isCorrect {
                            // 맞췄을 때 정확도 카운트 증가
                            vm.increaseAccuracyCount(for: word)
                        } else {
                            // 틀렸을 때 중요도 카운트 증가
                            vm.increaseImportanceCount(for: word)
                        }
                        
                        vm.answerCurrent(correct: isCorrect)
                        feedback = isCorrect ? "Correct" : "Wrong: \(word.meaning ?? "")"
                    } label: {
                        HStack { Text(opt); Spacer() }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                if !feedback.isEmpty { Text(feedback).foregroundStyle(.secondary) }
            }
        }
        .padding()
        .navigationTitle("Multiple Choice")
    }
}

