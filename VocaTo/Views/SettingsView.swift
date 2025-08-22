import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        Form {
            Section("알림") {
                Toggle("일일 알림", isOn: Binding(get: { app.notificationsEnabled }, set: app.setNotifications))
                HStack {
                    Text("시간")
                    Spacer()
                    DatePicker("", selection: Binding(get: {
                        Calendar.current.date(from: DateComponents(hour: app.notificationHour, minute: app.notificationMinute)) ?? Date()
                    }, set: { date in
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                        app.updateNotificationTime(hour: comps.hour ?? 20, minute: comps.minute ?? 0)
                    }), displayedComponents: .hourAndMinute)
                    .disabled(!app.notificationsEnabled)
                }
            }

            Section("학습") {
                Toggle("플래시카드 자동 넘김", isOn: .constant(true))
                HStack {
                    Text("속도")
                    Slider(value: Binding(get: { app.studyAutoAdvanceSpeed }, set: app.updateAutoAdvanceSpeed), in: 1...5, step: 0.5)
                }
            }

            Section("데이터") {
                CSVServiceView()
            }
            
            // 앱 정보 섹션
            Section("앱 정보") {
                HStack {
                    Text("버전")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                
                Link("개인정보처리방침", destination: URL(string: "https://example.com/privacy")!)
                    .foregroundStyle(Color("PrimaryGreen"))
                
                Link("이용약관", destination: URL(string: "https://example.com/terms")!)
                    .foregroundStyle(Color("PrimaryGreen"))
            }
        }
        .navigationTitle("설정")
    }
}

struct CSVServiceView: View {
    @State private var isImporterPresented = false
    @State private var isExporterPresented = false
    @State private var exportUrl: URL?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Import CSV") { isImporterPresented = true }
            Button("Export CSV") {
                do {
                    exportUrl = try CSVService.shared.exportCSV()
                    isExporterPresented = true
                } catch { 
                    showError("Export Failed", "Failed to export CSV: \(error.localizedDescription)")
                }
            }
        }
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.commaSeparatedText]) { result in
            switch result {
            case .success(let url):
                do {
                    try CSVService.shared.importCSV(from: url)
                    showSuccess("Import Successful", "CSV file imported successfully!")
                } catch {
                    showError("Import Failed", "Failed to import CSV: \(error.localizedDescription)")
                }
            case .failure(let error):
                showError("Import Failed", "Failed to access file: \(error.localizedDescription)")
            }
        }
        .fileExporter(isPresented: $isExporterPresented, document: exportUrl.map { CSVDocument(url: $0) }, contentType: .commaSeparatedText, defaultFilename: "VocaTo_Export.csv") { result in
            switch result {
            case .success:
                showSuccess("Export Successful", "CSV file exported successfully!")
            case .failure(let error):
                showError("Export Failed", "Failed to export file: \(error.localizedDescription)")
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func showSuccess(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    private func showError(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

