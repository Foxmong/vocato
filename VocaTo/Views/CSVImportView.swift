import SwiftUI
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isImporterPresented = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    // CSV 템플릿 다운로드
    @State private var showTemplateDownload = false
    @State private var exportUrl: URL?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 헤더
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("CSV 파일 불러오기")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("기존 단어장을 CSV 형식으로 가져올 수 있습니다")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // CSV 형식 안내
                VStack(alignment: .leading, spacing: 16) {
                    Text("CSV 파일 형식")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• 첫 번째 줄: term,meaning,memo,synonyms")
                        Text("• 두 번째 줄부터: 실제 단어 데이터")
                        Text("• 쉼표(,)로 각 필드를 구분")
                        Text("• 메모와 동의어는 선택사항")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    // CSV 템플릿 다운로드
                    Button {
                        downloadTemplate()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("CSV 템플릿 다운로드")
                        }
                        .font(.subheadline)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                // 예시 데이터
                VStack(alignment: .leading, spacing: 12) {
                    Text("예시 데이터")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("term,meaning,memo,synonyms")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("hello,안녕하세요,기본 인사말,hi,hey")
                            .font(.caption)
                        Text("goodbye,안녕히 가세요,작별 인사,bye,see you")
                            .font(.caption)
                        Text("thank you,감사합니다,고마움 표현,thanks,thx")
                            .font(.caption)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                Spacer()
                
                // CSV 파일 선택 버튼
                Button {
                    isImporterPresented = true
                } label: {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("CSV 파일 선택")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("PrimaryGreen"), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("CSV 가져오기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.commaSeparatedText]) { result in
                switch result {
                case .success(let url):
                    do {
                        try CSVService.shared.importCSV(from: url)
                        showSuccess("가져오기 성공", "CSV 파일이 성공적으로 가져와졌습니다!")
                    } catch {
                        showError("가져오기 실패", "CSV 파일 가져오기에 실패했습니다: \(error.localizedDescription)")
                    }
                case .failure(let error):
                    showError("파일 접근 실패", "파일에 접근할 수 없습니다: \(error.localizedDescription)")
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button(isSuccess ? "확인" : "다시 시도") {
                    if isSuccess {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .fileExporter(isPresented: $showTemplateDownload, document: exportUrl.map { CSVDocument(url: $0) }, contentType: .commaSeparatedText, defaultFilename: "VocaTo_Template.csv") { result in
                switch result {
                case .success:
                    showSuccess("템플릿 다운로드", "CSV 템플릿이 성공적으로 다운로드되었습니다!")
                case .failure(let error):
                    showError("다운로드 실패", "템플릿 다운로드에 실패했습니다: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func downloadTemplate() {
        let templateContent = """
term,meaning,memo,synonyms
hello,안녕하세요,기본 인사말,hi,hey
goodbye,안녕히 가세요,작별 인사,bye,see you
thank you,감사합니다,고마움 표현,thanks,thx
please,제발,정중한 요청,kindly,if you would
sorry,죄송합니다,사과 표현,apologize,excuse me
yes,네,긍정 응답,yeah,sure,okay
no,아니요,부정 응답,nope,not really
water,물,기본 음료,H2O,aqua
food,음식,먹는 것,meal,cuisine
house,집,거주 공간,home,residence
"""
        
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("VocaTo_Template.csv")
        do {
            try templateContent.data(using: .utf8)?.write(to: tmp, options: .atomic)
            exportUrl = tmp
            showTemplateDownload = true
        } catch {
            showError("템플릿 생성 실패", "CSV 템플릿을 생성할 수 없습니다: \(error.localizedDescription)")
        }
    }
    
    private func showSuccess(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        isSuccess = true
        showAlert = true
    }
    
    private func showError(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        isSuccess = false
        showAlert = true
    }
}
