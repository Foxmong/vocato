import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // 헤더
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.yellow)
                        
                        Text("VocaTo Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("무제한 학습의 힘을 경험하세요")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 현재 상태
                    if !subscriptionManager.isSubscribed {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("무료 사용자")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            
                            HStack {
                                Text("남은 단어 등록 가능 수:")
                                Spacer()
                                Text("\(subscriptionManager.remainingWordCount)개")
                                    .fontWeight(.bold)
                                    .foregroundStyle(subscriptionManager.remainingWordCount < 50 ? .red : .primary)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 프리미엄 기능들
                    VStack(spacing: 16) {
                        Text("프리미엄 기능")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            PremiumFeatureRow(
                                icon: "infinity",
                                title: "무제한 단어 등록",
                                description: "제한 없이 원하는 만큼 단어를 추가하세요",
                                isUnlocked: subscriptionManager.isSubscribed
                            )
                            
                            PremiumFeatureRow(
                                icon: "star.fill",
                                title: "중요도별 오답노트",
                                description: "틀린 단어들을 중요도별로 자동 분류",
                                isUnlocked: subscriptionManager.isSubscribed
                            )
                            
                            PremiumFeatureRow(
                                icon: "chart.bar.fill",
                                title: "고급 통계",
                                description: "상세한 학습 분석과 진도 리포트",
                                isUnlocked: subscriptionManager.isSubscribed
                            )
                            
                            PremiumFeatureRow(
                                icon: "square.and.arrow.up",
                                title: "데이터 내보내기",
                                description: "학습 데이터를 CSV로 내보내기",
                                isUnlocked: subscriptionManager.isSubscribed
                            )
                        }
                    }
                    
                    // 가격 정보
                    VStack(spacing: 16) {
                        Text("구독 요금")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("월간 구독")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                HStack(alignment: .bottom, spacing: 4) {
                                    Text("₩2,900")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color("PrimaryGreen"))
                                    
                                    Text("/ 월")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Text("$3.00 / month")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Text("💎")
                                    .font(.system(size: 30))
                                Text("최고의 가치")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color("PrimaryGreen"))
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 구독 버튼들
                    if !subscriptionManager.isSubscribed {
                        VStack(spacing: 12) {
                            Button {
                                purchaseSubscription()
                            } label: {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "crown.fill")
                                    }
                                    
                                    Text(isPurchasing ? "구매 중..." : "프리미엄 구독하기")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("PrimaryGreen"))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                            .disabled(isPurchasing)
                            
                            Button {
                                restoreSubscription()
                            } label: {
                                HStack {
                                    if isRestoring {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color("PrimaryGreen")))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    
                                    Text(isRestoring ? "복원 중..." : "구매 복원")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.clear)
                                .foregroundStyle(Color("PrimaryGreen"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color("PrimaryGreen"), lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isRestoring)
                        }
                    } else {
                        // 이미 구독 중인 경우
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("프리미엄 구독 중")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding()
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                            
                            Text("모든 프리미엄 기능을 무제한으로 이용하실 수 있습니다!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // 약관
                    VStack(spacing: 8) {
                        Text("구독을 진행하면 이용약관과 개인정보처리방침에 동의하는 것으로 간주됩니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("구독은 언제든지 취소할 수 있습니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("프리미엄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
            .alert("오류", isPresented: $showError) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func purchaseSubscription() {
        isPurchasing = true
        
        Task {
            do {
                try await subscriptionManager.purchaseSubscription()
                await MainActor.run {
                    isPurchasing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = "구매 중 오류가 발생했습니다: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func restoreSubscription() {
        isRestoring = true
        
        Task {
            do {
                try await subscriptionManager.restoreSubscription()
                await MainActor.run {
                    isRestoring = false
                    if subscriptionManager.isSubscribed {
                        dismiss()
                    } else {
                        errorMessage = "복원할 구매 내역이 없습니다."
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    errorMessage = "복원 중 오류가 발생했습니다: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// 프리미엄 기능 행
struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isUnlocked: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isUnlocked ? Color("PrimaryGreen") : .gray)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.circle.fill")
                .foregroundStyle(isUnlocked ? .green : .gray)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SubscriptionView()
}
