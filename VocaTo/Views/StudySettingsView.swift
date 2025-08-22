import SwiftUI
import CoreData

struct StudySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: StudyViewModel
    @State private var settings: StudySettings
    @State private var navigateToStudy = false
    
    init(initialQuizMode: QuizMode = .flashcards) {
        let ctx = PersistenceController.shared.container.viewContext
        _vm = StateObject(wrappedValue: StudyViewModel(context: ctx))
        var initialSettings = StudySettings()
        initialSettings.quizMode = initialQuizMode
        _settings = State(initialValue: initialSettings)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 단어 그룹 선택
                    VStack(alignment: .leading, spacing: 16) {
                        Text("학습할 단어 그룹")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(WordGroup.allCases, id: \.self) { group in
                                Button {
                                    settings.wordGroup = group
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: group.systemImage)
                                            .font(.title2)
                                            .foregroundStyle(settings.wordGroup == group ? .white : Color("PrimaryGreen"))
                                        Text(group.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        settings.wordGroup == group ? 
                                        Color("PrimaryGreen") : 
                                        .ultraThinMaterial
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 퀴즈 방식 선택
                    VStack(alignment: .leading, spacing: 16) {
                        Text("퀴즈 방식")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(QuizMode.allCases, id: \.self) { mode in
                                Button {
                                    settings.quizMode = mode
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: mode.systemImage)
                                            .font(.title2)
                                            .foregroundStyle(settings.quizMode == mode ? .white : Color("PrimaryGreen"))
                                        Text(mode.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        settings.quizMode == mode ? 
                                        Color("PrimaryGreen") : 
                                        .ultraThinMaterial
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 자동재생 설정 (자동재생 모드일 때만 표시)
                    if settings.quizMode == .autoPlay {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("자동재생 설정")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            // 재생 모드 선택
                            VStack(alignment: .leading, spacing: 12) {
                                Text("재생 모드")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                HStack(spacing: 12) {
                                    ForEach(AutoPlayMode.allCases, id: \.self) { mode in
                                        Button {
                                            settings.autoPlayMode = mode
                                        } label: {
                                            VStack(spacing: 4) {
                                                Image(systemName: mode.systemImage)
                                                    .font(.title3)
                                                    .foregroundStyle(settings.autoPlayMode == mode ? Color("PrimaryGreen") : .gray)
                                                Text(mode.rawValue)
                                                    .font(.caption2)
                                                    .foregroundStyle(settings.autoPlayMode == mode ? .primary : .secondary)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                settings.autoPlayMode == mode ? 
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
                            VStack(alignment: .leading, spacing: 12) {
                                Text("재생 간격")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                HStack {
                                    Text("\(Int(settings.autoPlayInterval))초")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color("PrimaryGreen"))
                                        .frame(width: 80)
                                    
                                    Slider(value: Binding(
                                        get: { settings.autoPlayInterval },
                                        set: { settings.autoPlayInterval = $0 }
                                    ), in: 1...10, step: 1)
                                    .tint(Color("PrimaryGreen"))
                                }
                                
                                Text("1초에서 10초까지 설정 가능합니다")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // 문제 수 설정
                    VStack(alignment: .leading, spacing: 16) {
                        Text("문제 수")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        HStack {
                            Text("\(settings.questionCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color("PrimaryGreen"))
                                .frame(width: 60)
                            
                            Slider(value: Binding(
                                get: { Double(settings.questionCount) },
                                set: { settings.questionCount = Int($0) }
                            ), in: 5...50, step: 5)
                            .tint(Color("PrimaryGreen"))
                        }
                        
                        Text("5개에서 50개까지 선택 가능합니다")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // 난이도 설정
                    VStack(alignment: .leading, spacing: 16) {
                        Text("난이도")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 12) {
                            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                                Button {
                                    settings.difficulty = difficulty
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: difficulty.systemImage)
                                            .font(.title3)
                                            .foregroundStyle(settings.difficulty == difficulty ? Color("PrimaryGreen") : .gray)
                                        Text(difficulty.rawValue)
                                            .font(.caption2)
                                            .foregroundStyle(settings.difficulty == difficulty ? .primary : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        settings.difficulty == difficulty ? 
                                        Color("PrimaryGreen").opacity(0.1) : 
                                        .clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 즐겨찾기 포함 여부
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("즐겨찾기 단어 포함")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("선택한 그룹 외에도 즐겨찾기된 단어를 포함합니다")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $settings.includeFavorites)
                                .tint(Color("PrimaryGreen"))
                        }
                    }
                    
                    // 학습 시작 버튼
                    Button {
                        startStudy()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("학습 시작")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("PrimaryGreen"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)
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
                    destination: Group {
                        switch settings.quizMode {
                        case .flashcards:
                            StudyFlashcardsView()
                                .environmentObject(vm)
                        case .multipleChoice:
                            StudyMCQView()
                                .environmentObject(vm)
                        case .dictation:
                            StudyDictationView()
                                .environmentObject(vm)
                        case .autoPlay:
                            StudyAutoPlayView()
                                .environmentObject(vm)
                        }
                    },
                    isActive: $navigateToStudy
                ) { EmptyView() }
            )
        }
    }
    
    private func startStudy() {
        // 설정을 StudyViewModel에 적용
        vm.studySettings = settings
        vm.autoPlayMode = settings.autoPlayMode
        vm.autoPlayInterval = settings.autoPlayInterval
        vm.loadStudyQueue(with: settings)
        
        // 학습 화면으로 이동
        navigateToStudy = true
    }
}

#Preview {
    StudySettingsView()
}
