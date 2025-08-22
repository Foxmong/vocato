import SwiftUI
import CoreData

struct AddOrEditWordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    
    // 편집 모드를 위한 옵셔널 Word 파라미터 추가
    let wordToEdit: Word?
    
    @State private var term: String = ""
    @State private var meaning: String = ""
    @State private var memo: String = ""
    @State private var synonyms: String = ""
    
    // 편집 모드인지 확인
    private var isEditMode: Bool { wordToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Term (EN)") { TextField("apple", text: $term) }
                Section("Meaning (KR)") { TextField("사과", text: $meaning) }
                Section("Memo") { TextField("메모", text: $memo) }
                Section("Synonyms") { TextField("동의어(콤마로 구분)", text: $synonyms) }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { 
                    Button(isEditMode ? "Update" : "Save", action: save) 
                        .disabled(term.isEmpty || meaning.isEmpty) 
                }
            }
            .navigationTitle(isEditMode ? "Edit Word" : "New Word")
            .onAppear {
                if let word = wordToEdit {
                    // 편집 모드일 때 기존 데이터 로드
                    term = word.term ?? ""
                    meaning = word.meaning ?? ""
                    memo = word.memo ?? ""
                    synonyms = word.synonyms ?? ""
                }
            }

        }
    }

    private func save() {
        if let word = wordToEdit {
            // 편집 모드: 기존 단어 업데이트
            word.term = term
            word.meaning = meaning
            word.memo = memo.isEmpty ? nil : memo
            word.synonyms = synonyms.isEmpty ? nil : synonyms
        } else {
            // 추가 모드: 새 단어 생성
            let word = Word(context: context)
            word.uuid = UUID().uuidString
            word.term = term
            word.meaning = meaning
            word.memo = memo.isEmpty ? nil : memo
            word.synonyms = synonyms.isEmpty ? nil : synonyms
            word.createdAt = Date()
            word.srsStage = 0
            word.correctCount = 0
            word.wrongCount = 0
            word.isFavorite = false
            word.importanceCount = 0
        }
        
        do { 
            try context.save()
            dismiss() 
        } catch { 
            print("Save error: \(error)") 
        }
    }
}

struct AddWordOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showManualAdd = false
    @State private var showRecommendedWords = false
    @State private var showCSVImport = false
    @State private var showScanImport = false
    @State private var showSpeechImport = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 헤더
                VStack(spacing: 8) {
                    Text("단어 추가")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("원하는 방법을 선택하세요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                // 옵션 버튼들
                VStack(spacing: 16) {
                    // 1. 추천 단어장
                    Button {
                        showRecommendedWords = true
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "lightbulb.fill")
                                .font(.title2)
                                .foregroundStyle(.yellow)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("추천 단어장")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("자주 사용되는 기본 단어들을 추가")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    
                    // 2. CSV 파일 불러오기
                    Button {
                        showCSVImport = true
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "doc.text.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CSV 파일 불러오기")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("기존 단어장을 CSV로 가져오기")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    
                    // 3. 문서 스캔(OCR)
                    Button {
                        showScanImport = true
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "camera.viewfinder")
                                .font(.title2)
                                .foregroundStyle(.purple)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("문서 스캔(OCR)")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("영↔한 텍스트를 스캔해 단어·뜻 자동 분리")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    
                    // 4. 음성 인식
                    Button {
                        showSpeechImport = true
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "waveform")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("음성 인식")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("영↔한 음성을 인식해 단어·뜻 자동 분리")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    
                    // 5. 수동으로 추가
                    Button {
                        showManualAdd = true
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color("PrimaryGreen"))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("수동으로 추가")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("직접 단어를 입력하여 추가")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("단어 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showManualAdd) {
                AddOrEditWordView(wordToEdit: nil)
            }
            .sheet(isPresented: $showRecommendedWords) {
                RecommendedWordsView()
            }
            .sheet(isPresented: $showCSVImport) {
                CSVImportView()
            }
            .sheet(isPresented: $showScanImport) {
                ScanImportView()
            }
            .sheet(isPresented: $showSpeechImport) {
                SpeechImportView()
            }
        }
    }
}

