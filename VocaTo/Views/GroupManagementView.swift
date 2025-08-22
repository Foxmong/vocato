import SwiftUI
import CoreData

struct GroupManagementView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Word.createdAt, ascending: true)], animation: .default)
    private var words: FetchedResults<Word>
    
    @State private var selectedGroup: WordGroup = .all
    @State private var showAddWordOptions = false
    @State private var showScanImport = false
    @State private var showManualInput = false
    @State private var showCSVImport = false
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // 좌측: 그룹 목록
                VStack(spacing: 0) {
                    Text("그룹")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(WordGroup.allCases, id: \.self) { group in
                                Button {
                                    selectedGroup = group
                                } label: {
                                    HStack {
                                        Image(systemName: group.systemImage)
                                            .foregroundStyle(selectedGroup == group ? .white : Color("PrimaryGreen"))
                                            .frame(width: 24)
                                        
                                        Text(group.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(selectedGroup == group ? .white : .primary)
                                        
                                        Spacer()
                                        
                                        Text("\(getWordCount(for: group))")
                                            .font(.caption)
                                            .foregroundStyle(selectedGroup == group ? .white.opacity(0.8) : .secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedGroup == group ? 
                                        Color("PrimaryGreen") : 
                                        .clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .frame(width: 200)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // 우측: 선택된 그룹의 단어 목록
                VStack(spacing: 16) {
                    // 헤더
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedGroup.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(getWordCount(for: selectedGroup))개 단어")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // + 버튼
                        Button {
                            showAddWordOptions = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color("PrimaryGreen"))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    
                    // 단어 목록
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(getWords(for: selectedGroup), id: \.uuid) { word in
                                WordRowView(word: word)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .navigationTitle("그룹 관리")
            .sheet(isPresented: $showAddWordOptions) {
                AddWordOptionsView(
                    showScanImport: $showScanImport,
                    showManualInput: $showManualInput,
                    showCSVImport: $showCSVImport
                )
            }
            .sheet(isPresented: $showScanImport) {
                ScanImportView()
            }
            .sheet(isPresented: $showManualInput) {
                AddOrEditWordView(wordToEdit: nil)
            }
            .sheet(isPresented: $showCSVImport) {
                CSVImportView()
            }
        }
    }
    
    private func getWordCount(for group: WordGroup) -> Int {
        return getWords(for: group).count
    }
    
    private func getWords(for group: WordGroup) -> [Word] {
        switch group {
        case .all:
            return Array(words)
        case .new:
            return words.filter { $0.srsStage == 0 }
        case .learning:
            return words.filter { $0.srsStage == 1 }
        case .reviewing:
            return words.filter { $0.srsStage == 2 }
        case .mastered:
            return words.filter { $0.srsStage == 3 }
        case .favorites:
            return words.filter { $0.isFavorite }
        }
    }
}

// 단어 행 뷰
struct WordRowView: View {
    let word: Word
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.term ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(word.meaning ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                // 중요도 표시
                if word.importanceCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption2)
                        Text("\(word.importanceCount)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
                
                // 즐겨찾기 표시
                if word.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                
                // SRS 단계 표시
                Text("S\(word.srsStage)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(getSRSColor(for: word.srsStage), in: RoundedRectangle(cornerRadius: 6))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func getSRSColor(for stage: Int16) -> Color {
        switch stage {
        case 0: return .red
        case 1: return .orange
        case 2: return .blue
        case 3: return .green
        default: return .gray
        }
    }
}

// 단어 추가 옵션 뷰
struct AddWordOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showScanImport: Bool
    @Binding var showManualInput: Bool
    @Binding var showCSVImport: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("단어 추가 방법을 선택하세요")
                    .font(.headline)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    Button {
                        dismiss()
                        showScanImport = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("문서 스캔")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("카메라로 문서를 스캔하여 단어 추가")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        dismiss()
                        showManualInput = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil.and.outline")
                                .font(.title2)
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("수동 입력")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("직접 단어와 뜻을 입력하여 추가")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        dismiss()
                        showCSVImport = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CSV 파일 불러오기")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("CSV 파일에서 단어 목록을 일괄 추가")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("단어 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    GroupManagementView()
}
