import SwiftUI
import CoreData

struct StudyAutoPlayView: View {
    @EnvironmentObject private var vm: StudyViewModel
    @State private var showSettings = false
    @State private var isPaused = false
    
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
                
                // 진행률 및 중요도 표시
                HStack {
                    Text("\(vm.currentIndex + 1) / \(vm.todaysQueue.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    
                    // 중요도 표시
                    ImportanceIndicator(importanceCount: word.importanceCount)
                }
                
                // 단어 카드
                VStack(spacing: 16) {
                    Text(word.term ?? "")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(word.meaning ?? "")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .onTapGesture {
                    togglePause()
                }
                
                // 자동재생 상태 표시
                HStack(spacing: 16) {
                    Image(systemName: vm.isAutoPlaying ? "play.circle.fill" : "pause.circle.fill")
                        .font(.title2)
                        .foregroundStyle(vm.isAutoPlaying ? .green : .orange)
                    
                    Text(vm.isAutoPlaying ? "자동재생 중" : "일시정지")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if vm.isAutoPlaying {
                        Text("\(Int(vm.autoPlayInterval))초 간격")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // 컨트롤 버튼들
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        Button(vm.isAutoPlaying ? "일시정지" : "재생") {
                            togglePause()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("중지") {
                            vm.stopAutoPlay()
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.red)
                    }
                    
                    HStack(spacing: 16) {
                        Button("알아요") {
                            vm.advance()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("설정") {
                            showSettings = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .navigationTitle("자동재생")
        .onAppear {
            if !vm.isAutoPlaying {
                vm.startAutoPlay()
            }
        }
        .onDisappear {
            vm.stopAutoPlay()
        }
        .sheet(isPresented: $showSettings) {
            AutoPlaySettingsView()
                .environmentObject(vm)
        }
    }
    
    private func togglePause() {
        if vm.isAutoPlaying {
            vm.pauseAutoPlay()
        } else {
            vm.resumeAutoPlay()
        }
    }
}

// 자동재생 설정 뷰
struct AutoPlaySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: StudyViewModel
    @State private var selectedMode: AutoPlayMode
    @State private var selectedInterval: Double
    
    init() {
        _selectedMode = State(initialValue: .both)
        _selectedInterval = State(initialValue: 3.0)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 재생 모드 선택
                VStack(alignment: .leading, spacing: 16) {
                    Text("재생 모드")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(AutoPlayMode.allCases, id: \.self) { mode in
                            Button {
                                selectedMode = mode
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: mode.systemImage)
                                        .font(.title2)
                                        .foregroundStyle(selectedMode == mode ? .white : Color("PrimaryGreen"))
                                    Text(mode.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    selectedMode == mode ? 
                                    Color("PrimaryGreen") : 
                                    .ultraThinMaterial
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // 재생 간격 설정
                VStack(alignment: .leading, spacing: 16) {
                    Text("재생 간격")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    HStack {
                        Text("\(Int(selectedInterval))초")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color("PrimaryGreen"))
                            .frame(width: 80)
                        
                        Slider(value: $selectedInterval, in: 1...10, step: 1)
                            .tint(Color("PrimaryGreen"))
                    }
                    
                    Text("1초에서 10초까지 설정 가능합니다")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // 적용 버튼
                Button("설정 적용") {
                    applySettings()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("PrimaryGreen"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.top, 16)
                
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
    
    private func applySettings() {
        vm.autoPlayMode = selectedMode
        vm.autoPlayInterval = selectedInterval
        
        // 현재 재생 중이면 재시작
        if vm.isAutoPlaying {
            vm.stopAutoPlay()
            vm.startAutoPlay()
        }
        
        dismiss()
    }
}

#Preview {
    StudyAutoPlayView()
        .environmentObject(StudyViewModel(context: PersistenceController.shared.container.viewContext))
}
