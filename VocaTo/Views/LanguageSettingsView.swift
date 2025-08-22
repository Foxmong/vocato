import SwiftUI

struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var selectedSystemLanguage: SupportedLanguage
    @State private var selectedLearningLanguage: SupportedLanguage
    
    init() {
        let manager = LanguageManager.shared
        _selectedSystemLanguage = State(initialValue: manager.systemLanguage)
        _selectedLearningLanguage = State(initialValue: manager.learningLanguage)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("시스템 언어는 앱 인터페이스에서 사용되며, 학습 언어는 단어 학습과 TTS에서 사용됩니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("언어 설정")
                }
                
                Section("시스템 언어") {
                    ForEach(SupportedLanguage.allCases, id: \.self) { language in
                        Button {
                            selectedSystemLanguage = language
                        } label: {
                            HStack {
                                Text(language.flag)
                                    .font(.title2)
                                
                                Text(language.nativeName)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if selectedSystemLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("PrimaryGreen"))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Section("학습 언어") {
                    ForEach(SupportedLanguage.allCases, id: \.self) { language in
                        Button {
                            selectedLearningLanguage = language
                        } label: {
                            HStack {
                                Text(language.flag)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(language.nativeName)
                                        .foregroundStyle(.primary)
                                    Text("TTS: \(language.ttsLanguageCode)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedLearningLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("PrimaryGreen"))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("예시:")
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text("시스템 언어:")
                            Text("\(selectedSystemLanguage.flag) \(selectedSystemLanguage.nativeName)")
                                .foregroundStyle(Color("PrimaryGreen"))
                        }
                        .font(.caption)
                        
                        HStack {
                            Text("학습 언어:")
                            Text("\(selectedLearningLanguage.flag) \(selectedLearningLanguage.nativeName)")
                                .foregroundStyle(Color("PrimaryGreen"))
                        }
                        .font(.caption)
                        
                        Text("→ 앱은 \(selectedSystemLanguage.nativeName)로 표시되고, \(selectedLearningLanguage.nativeName) 단어를 학습합니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                } header: {
                    Text("미리보기")
                }
            }
            .navigationTitle("언어 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        saveLanguageSettings()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("PrimaryGreen"))
                }
            }
        }
    }
    
    private func saveLanguageSettings() {
        languageManager.setSystemLanguage(selectedSystemLanguage)
        languageManager.setLearningLanguage(selectedLearningLanguage)
        dismiss()
    }
}

#Preview {
    LanguageSettingsView()
        .environmentObject(LanguageManager.shared)
}
