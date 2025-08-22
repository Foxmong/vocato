import SwiftUI

struct OnboardingView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedSystemLanguage: SupportedLanguage = .korean
    @State private var selectedLearningLanguage: SupportedLanguage = .english
    
    enum OnboardingStep {
        case welcome
        case systemLanguage
        case learningLanguage
        case completed
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 진행 표시기
                ProgressView(value: progressValue)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color("PrimaryGreen")))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .padding(.horizontal)
                
                // 메인 콘텐츠
                VStack(spacing: 40) {
                    switch currentStep {
                    case .welcome:
                        WelcomeStepView()
                    case .systemLanguage:
                        SystemLanguageStepView(selectedLanguage: $selectedSystemLanguage)
                    case .learningLanguage:
                        LearningLanguageStepView(selectedLanguage: $selectedLearningLanguage)
                    case .completed:
                        CompletedStepView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
                
                // 하단 버튼
                VStack(spacing: 16) {
                    Button {
                        nextStep()
                    } label: {
                        Text(buttonTitle)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("PrimaryGreen"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    
                    if currentStep != .welcome {
                        Button {
                            previousStep()
                        } label: {
                            Text("이전")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private var progressValue: Double {
        switch currentStep {
        case .welcome: return 0.25
        case .systemLanguage: return 0.5
        case .learningLanguage: return 0.75
        case .completed: return 1.0
        }
    }
    
    private var buttonTitle: String {
        switch currentStep {
        case .welcome: return "시작하기"
        case .systemLanguage: return "다음"
        case .learningLanguage: return "완료"
        case .completed: return "VocaTo 시작하기"
        }
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                currentStep = .systemLanguage
            case .systemLanguage:
                languageManager.setSystemLanguage(selectedSystemLanguage)
                currentStep = .learningLanguage
            case .learningLanguage:
                languageManager.setLearningLanguage(selectedLearningLanguage)
                currentStep = .completed
            case .completed:
                languageManager.completeOnboarding()
            }
        }
    }
    
    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .systemLanguage:
                currentStep = .welcome
            case .learningLanguage:
                currentStep = .systemLanguage
            case .completed:
                currentStep = .learningLanguage
            default:
                break
            }
        }
    }
}

// 환영 단계
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 32) {
            // 앱 아이콘
            Image(systemName: "book.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color("PrimaryGreen"))
            
            VStack(spacing: 16) {
                Text("VocaTo에 오신 것을\n환영합니다!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("효과적인 단어 학습을 위한\n스마트한 동반자")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                FeatureRow(icon: "brain.head.profile", title: "스마트 학습", description: "AI 기반 맞춤형 학습")
                FeatureRow(icon: "speaker.wave.2", title: "음성 지원", description: "정확한 발음 학습")
                FeatureRow(icon: "chart.bar.fill", title: "진도 추적", description: "상세한 학습 통계")
            }
            .padding(.top, 20)
        }
    }
}

// 시스템 언어 선택 단계
struct SystemLanguageStepView: View {
    @Binding var selectedLanguage: SupportedLanguage
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("시스템 언어 선택")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("앱 인터페이스에서 사용할 언어를 선택하세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(SupportedLanguage.allCases, id: \.self) { language in
                    Button {
                        selectedLanguage = language
                    } label: {
                        VStack(spacing: 12) {
                            Text(language.flag)
                                .font(.system(size: 40))
                            
                            Text(language.nativeName)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            selectedLanguage == language ?
                            Color("PrimaryGreen") :
                            .ultraThinMaterial
                        )
                        .foregroundStyle(
                            selectedLanguage == language ?
                            .white :
                            .primary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// 학습 언어 선택 단계
struct LearningLanguageStepView: View {
    @Binding var selectedLanguage: SupportedLanguage
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("학습 언어 선택")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("배우고 싶은 언어를 선택하세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(SupportedLanguage.allCases, id: \.self) { language in
                    Button {
                        selectedLanguage = language
                    } label: {
                        VStack(spacing: 12) {
                            Text(language.flag)
                                .font(.system(size: 40))
                            
                            Text(language.nativeName)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            selectedLanguage == language ?
                            Color("PrimaryGreen") :
                            .ultraThinMaterial
                        )
                        .foregroundStyle(
                            selectedLanguage == language ?
                            .white :
                            .primary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// 완료 단계
struct CompletedStepView: View {
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color("PrimaryGreen"))
            
            VStack(spacing: 16) {
                Text("설정 완료!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("이제 VocaTo와 함께\n효과적인 단어 학습을 시작하세요")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundStyle(Color("PrimaryGreen"))
                    Text("무료로 200개 단어까지 등록 가능")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("프리미엄으로 무제한 단어 + 추가 기능")
                        .font(.subheadline)
                }
            }
            .padding(.top, 20)
        }
    }
}

// 기능 행 뷰
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color("PrimaryGreen"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OnboardingView()
}
