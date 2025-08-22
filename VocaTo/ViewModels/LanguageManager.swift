import Foundation

// 지원 언어 정의
enum SupportedLanguage: String, CaseIterable {
    case korean = "ko"
    case english = "en" 
    case japanese = "ja"
    case chinese = "zh"
    
    var displayName: String {
        switch self {
        case .korean: return "한국어"
        case .english: return "English"
        case .japanese: return "日本語"
        case .chinese: return "中文"
        }
    }
    
    var nativeName: String {
        switch self {
        case .korean: return "한국어"
        case .english: return "English"
        case .japanese: return "日本語" 
        case .chinese: return "中文"
        }
    }
    
    var flag: String {
        switch self {
        case .korean: return "🇰🇷"
        case .english: return "🇺🇸"
        case .japanese: return "🇯🇵"
        case .chinese: return "🇨🇳"
        }
    }
    
    var ttsLanguageCode: String {
        switch self {
        case .korean: return "ko-KR"
        case .english: return "en-US"
        case .japanese: return "ja-JP"
        case .chinese: return "zh-CN"
        }
    }
}

enum WordType {
    case term    // 학습할 단어
    case meaning // 뜻 (시스템 언어)
}

// 언어 설정 관리
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var systemLanguage: SupportedLanguage = .korean
    @Published var learningLanguage: SupportedLanguage = .english
    @Published var isOnboardingCompleted: Bool = false
    
    private let systemLanguageKey = "systemLanguage"
    private let learningLanguageKey = "learningLanguage" 
    private let onboardingCompletedKey = "onboardingCompleted"
    
    private init() {
        loadLanguageSettings()
    }
    
    // 언어 설정 로드
    private func loadLanguageSettings() {
        // 시스템 언어 로드
        if let systemLangRaw = UserDefaults.standard.string(forKey: systemLanguageKey),
           let systemLang = SupportedLanguage(rawValue: systemLangRaw) {
            systemLanguage = systemLang
        } else {
            // 기본값: 디바이스 언어에 따라 설정
            systemLanguage = detectSystemLanguage()
        }
        
        // 학습 언어 로드
        if let learningLangRaw = UserDefaults.standard.string(forKey: learningLanguageKey),
           let learningLang = SupportedLanguage(rawValue: learningLangRaw) {
            learningLanguage = learningLang
        }
        
        // 온보딩 완료 여부 로드
        isOnboardingCompleted = UserDefaults.standard.bool(forKey: onboardingCompletedKey)
    }
    
    // 시스템 언어 자동 감지
    private func detectSystemLanguage() -> SupportedLanguage {
        let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        
        switch deviceLanguage {
        case "ko": return .korean
        case "ja": return .japanese
        case "zh": return .chinese
        default: return .english
        }
    }
    
    // 시스템 언어 설정
    func setSystemLanguage(_ language: SupportedLanguage) {
        systemLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: systemLanguageKey)
    }
    
    // 학습 언어 설정
    func setLearningLanguage(_ language: SupportedLanguage) {
        learningLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: learningLanguageKey)
    }
    
    // 온보딩 완료 처리
    func completeOnboarding() {
        isOnboardingCompleted = true
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
    }
    
    // 현지화된 문자열 가져오기
    func localizedString(_ key: String) -> String {
        // 실제로는 각 언어별 번역 파일에서 가져옴
        return getLocalizedString(key, for: systemLanguage)
    }
    
    // 언어별 번역 (간단한 구현)
    private func getLocalizedString(_ key: String, for language: SupportedLanguage) -> String {
        let translations: [String: [SupportedLanguage: String]] = [
            "welcome": [
                .korean: "VocaTo에 오신 것을 환영합니다!",
                .english: "Welcome to VocaTo!",
                .japanese: "VocaToへようこそ！",
                .chinese: "欢迎使用VocaTo！"
            ],
            "select_system_language": [
                .korean: "시스템 언어를 선택하세요",
                .english: "Select System Language",
                .japanese: "システム言語を選択してください",
                .chinese: "选择系统语言"
            ],
            "select_learning_language": [
                .korean: "학습할 언어를 선택하세요",
                .english: "Select Learning Language", 
                .japanese: "学習言語を選択してください",
                .chinese: "选择学习语言"
            ],
            "continue": [
                .korean: "계속",
                .english: "Continue",
                .japanese: "続行",
                .chinese: "继续"
            ],
            "premium_features": [
                .korean: "프리미엄 기능",
                .english: "Premium Features",
                .japanese: "プレミアム機能", 
                .chinese: "高级功能"
            ],
            "unlimited_words": [
                .korean: "무제한 단어 등록",
                .english: "Unlimited Words",
                .japanese: "無制限の単語登録",
                .chinese: "无限制单词注册"
            ],
            "importance_groups": [
                .korean: "중요도별 오답노트",
                .english: "Importance-based Error Notes",
                .japanese: "重要度別間違いノート",
                .chinese: "重要性错题笔记"
            ]
        ]
        
        return translations[key]?[language] ?? key
    }
    
    // TTS 언어 코드 가져오기 (단어용)
    func getTTSLanguageCode(for wordType: WordType) -> String {
        switch wordType {
        case .term:
            return learningLanguage.ttsLanguageCode
        case .meaning:
            return systemLanguage.ttsLanguageCode
        }
    }
}


