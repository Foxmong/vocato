import Foundation
import StoreKit

enum PremiumFeature {
    case unlimitedWords
    case importanceGroups
    case advancedStats
    case exportData
}

// 구독 상태 관리
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isSubscribed: Bool = false
    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published var remainingWordCount: Int = 200
    
    private let maxFreeWords = 200
    private let subscriptionProductID = "com.vocato.premium.monthly"
    
    private init() {
        loadSubscriptionStatus()
        updateRemainingWordCount()
    }
    
    enum SubscriptionStatus {
        case notSubscribed
        case subscribed
        case expired
        case pending
    }
    
    // 구독 상태 로드
    private func loadSubscriptionStatus() {
        // UserDefaults에서 구독 상태 로드 (실제로는 StoreKit으로 검증)
        isSubscribed = UserDefaults.standard.bool(forKey: "isSubscribed")
        updateSubscriptionStatus()
    }
    
    // 구독 상태 업데이트
    private func updateSubscriptionStatus() {
        subscriptionStatus = isSubscribed ? .subscribed : .notSubscribed
    }
    
    // 남은 단어 수 업데이트
    func updateRemainingWordCount() {
        if isSubscribed {
            remainingWordCount = -1 // 무제한
        } else {
            let currentWordCount = getCurrentWordCount()
            remainingWordCount = max(0, maxFreeWords - currentWordCount)
        }
    }
    
    // 현재 단어 수 가져오기
    private func getCurrentWordCount() -> Int {
        // Core Data에서 단어 수 조회
        return UserDefaults.standard.integer(forKey: "currentWordCount")
    }
    
    // 단어 추가 가능 여부 확인
    func canAddWord() -> Bool {
        return isSubscribed || remainingWordCount > 0
    }
    
    // 단어 추가 시 카운트 업데이트
    func addWordCount(_ count: Int = 1) {
        if !isSubscribed {
            let currentCount = getCurrentWordCount()
            let newCount = currentCount + count
            UserDefaults.standard.set(newCount, forKey: "currentWordCount")
            updateRemainingWordCount()
        }
    }
    
    // 구독 구매
    func purchaseSubscription() async throws {
        // StoreKit 구매 로직 (시뮬레이션)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2초 대기
        
        // 구매 성공
        isSubscribed = true
        UserDefaults.standard.set(true, forKey: "isSubscribed")
        updateSubscriptionStatus()
        updateRemainingWordCount()
    }
    
    // 구독 복원
    func restoreSubscription() async throws {
        // StoreKit 복원 로직 (시뮬레이션)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
        
        // 복원 확인
        let hasValidSubscription = UserDefaults.standard.bool(forKey: "isSubscribed")
        isSubscribed = hasValidSubscription
        updateSubscriptionStatus()
        updateRemainingWordCount()
    }
    
    // 프리미엄 기능 접근 가능 여부
    func hasAccessToFeature(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .unlimitedWords:
            return isSubscribed
        case .importanceGroups:
            return isSubscribed
        case .advancedStats:
            return isSubscribed
        case .exportData:
            return isSubscribed
        }
    }
}


