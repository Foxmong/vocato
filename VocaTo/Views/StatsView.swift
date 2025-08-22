import SwiftUI
import CoreData

struct StatsView: View {
    @StateObject private var vm: StatsViewModel
    @State private var selectedTimeRange: TimeRange = .week

    init() {
        let ctx = PersistenceController.shared.container.viewContext
        _vm = StateObject(wrappedValue: StatsViewModel(context: ctx))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 시간 범위 선택
                    Picker("시간 범위", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // 핵심 지표 3개 강조
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        GlassCard(title: "오늘 복습", subtitle: "\(vm.todayCount)", systemImage: "calendar")
                        GlassCard(title: "정확도", subtitle: String(format: "%.0f%%", vm.accuracy * 100), systemImage: "target")
                        GlassCard(title: "학습 시간", subtitle: timeString(vm.studySecondsToday), systemImage: "clock")
                    }
                    .padding(.horizontal)
                    
                    // 보조 지표
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        GlassCard(title: "총 단어", subtitle: "\(vm.totalWords)", systemImage: "book.fill")
                        GlassCard(title: "즐겨찾기", subtitle: "\(vm.favoriteWords)", systemImage: "star.fill")
                    }
                    .padding(.horizontal)
                    
                    // 학습 진행률
                    VStack(alignment: .leading, spacing: 12) {
                        Text("학습 진행률")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            ProgressRow(label: "새로운 (Stage 0)", value: vm.stage0Count, total: vm.totalWords, color: .red)
                            ProgressRow(label: "학습 중 (Stage 1)", value: vm.stage1Count, total: vm.totalWords, color: .orange)
                            ProgressRow(label: "복습 중 (Stage 2)", value: vm.stage2Count, total: vm.totalWords, color: .blue)
                            ProgressRow(label: "완성 (Stage 3)", value: vm.stage3Count, total: vm.totalWords, color: .green)
                        }
                        .padding(.horizontal)
                    }
                    
                    // 최근 학습 활동
                    VStack(alignment: .leading, spacing: 12) {
                        Text("최근 활동")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if vm.recentWords.isEmpty {
                            Text("최근 활동이 없습니다")
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            ForEach(vm.recentWords.prefix(5), id: \.uuid) { word in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(word.term ?? "")
                                            .font(.subheadline)
                                        Text("마지막 복습: \(word.nextReviewDate?.formatted(date: .abbreviated, time: .omitted) ?? "없음")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("Stage \(word.srsStage)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(stageColor(for: word.srsStage).opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("통계")
            .onChange(of: selectedTimeRange) { _ in
                vm.updateTimeRange(selectedTimeRange)
            }
        }
    }
    
    private func stageColor(for stage: Int16) -> Color {
        switch stage {
        case 0: return .red
        case 1: return .orange
        case 2: return .blue
        case 3: return .green
        default: return .gray
        }
    }
    
    private func timeString(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return h > 0 ? String(format: "%d시간 %d분", h, m) : String(format: "%d분", m)
    }
}

struct ProgressRow: View {
    let label: String
    let value: Int
    let total: Int
    let color: Color
    
    private var progress: Double {
        total > 0 ? Double(value) / Double(total) : 0
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("\(value)")
                .font(.subheadline)
                .foregroundStyle(color)
        }
        
        ProgressView(value: progress)
            .tint(color)
            .scaleEffect(y: 0.5)
    }
}

enum TimeRange: CaseIterable {
    case week, month, year, all
    
    var displayName: String {
        switch self {
        case .week: return "주"
        case .month: return "월"
        case .year: return "년"
        case .all: return "전체"
        }
    }
}

