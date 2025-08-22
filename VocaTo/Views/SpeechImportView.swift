import SwiftUI
import Speech
import AVFoundation
import CoreData

struct SpeechImportView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.managedObjectContext) private var context
	@State private var isRecording = false
	@State private var transcript: String = ""
	@State private var language: SpeechLanguage = .englishThenKorean
	@State private var parsedPairs: [(String,String)] = []
	@State private var selection: Set<Int> = []
	@State private var errorMessage = ""
	@State private var showError = false
	
    private let engine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer? { SFSpeechRecognizer(locale: language.locale) }
    @State private var request = SFSpeechAudioBufferRecognitionRequest()
    @State private var recognitionTask: SFSpeechRecognitionTask?
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 16) {
				Picker("언어", selection: $language) {
					ForEach(SpeechLanguage.allCases, id: \.self) { Text($0.display).tag($0) }
				}
				.pickerStyle(.segmented)
				
				VStack(alignment: .leading, spacing: 8) {
					HStack {
						Text("음성 인식 결과")
							.font(.headline)
						Spacer()
						Button(isRecording ? "정지" : "녹음") { toggleRecord() }
					}
					Text(transcript).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
						.padding()
						.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
					Text("예: 'apple - 사과', 'hello: 안녕하세요'").font(.caption).foregroundStyle(.secondary)
				}
				
				HStack { Button("파싱", action: parse).buttonStyle(.borderedProminent).disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty); Spacer() }
				
				if !parsedPairs.isEmpty {
					List {
						ForEach(parsedPairs.indices, id: \.self) { idx in
							let pair = parsedPairs[idx]
							HStack {
								VStack(alignment: .leading) {
									Text(pair.0).font(.headline)
									Text(pair.1).font(.subheadline).foregroundStyle(.secondary)
								}
								Spacer()
								Image(systemName: selection.contains(idx) ? "checkmark.circle.fill" : "circle")
									.foregroundStyle(selection.contains(idx) ? Color("PrimaryGreen") : .gray)
							}
							.contentShape(Rectangle())
							.onTapGesture { toggle(idx) }
						}
					}
				}
				Spacer()
				Button("선택 항목 추가") { saveSelected() }
					.buttonStyle(.borderedProminent)
					.disabled(selection.isEmpty)
			}
			.padding()
			.navigationTitle("음성 인식")
			.toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("취소") { dismiss() } } }
			.alert("오류", isPresented: $showError) { Button("확인", role: .cancel) {} } message: { Text(errorMessage) }
		}
	}
	
	private func toggle(_ idx: Int) { if selection.contains(idx) { selection.remove(idx) } else { selection.insert(idx) } }
	
	private func parse() {
		let lines = transcript.replacingOccurrences(of: "\r", with: "\n").components(separatedBy: .newlines)
			.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
		var result: [(String,String)] = []
		for line in lines {
			if let r = line.range(of: "-") ?? line.range(of: ":") ?? line.range(of: ",") {
				let a = line[..<r.lowerBound].trimmingCharacters(in: .whitespaces)
				let b = line[r.upperBound...].trimmingCharacters(in: .whitespaces)
				if !a.isEmpty && !b.isEmpty { result.append((String(a), String(b))) }
			}
		}
		parsedPairs = result
		selection = Set(result.indices)
	}
	
	private func saveSelected() {
		for idx in selection.sorted() {
			let pair = parsedPairs[idx]
			let w = Word(context: context)
			w.uuid = UUID().uuidString
			w.term = pair.0
			w.meaning = pair.1
			w.createdAt = Date()
			w.srsStage = 0
			w.correctCount = 0
			w.wrongCount = 0
			w.isFavorite = false
		}
		do { try context.save(); dismiss() } catch { errorMessage = error.localizedDescription; showError = true }
	}
	
	private func toggleRecord() {
		if isRecording { stopRecording() } else { startRecording() }
	}
	
	private func startRecording() {
		SFSpeechRecognizer.requestAuthorization { auth in
			dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
			guard auth == .authorized else { self.errorMessage = "음성 인식 권한이 필요합니다"; self.showError = true; return }
			AVAudioSession.sharedInstance().requestRecordPermission { granted in
				DispatchQueue.main.async {
					guard granted else { self.errorMessage = "마이크 권한이 필요합니다"; self.showError = true; return }
					self.beginSession()
				}
			}
		}
	}
	
    private func beginSession() {
		guard let recognizer else { self.errorMessage = "선택한 언어를 지원하지 않습니다"; self.showError = true; return }
		let node = engine.inputNode
        var newRequest = SFSpeechAudioBufferRecognitionRequest()
        newRequest.shouldReportPartialResults = true
        self.request = newRequest
        self.recognitionTask = recognizer.recognitionTask(with: newRequest) { result, error in
			if let result { self.transcript = result.bestTranscription.formattedString }
			if error != nil { self.stopRecording() }
		}
		let format = node.outputFormat(forBus: 0)
		node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            self.request.append(buffer)
		}
		do {
			try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
			try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
			engine.prepare()
			try engine.start()
			isRecording = true
		} catch {
			errorMessage = error.localizedDescription; showError = true
		}
	}
	
	private func stopRecording() {
		engine.stop(); engine.inputNode.removeTap(onBus: 0); request.endAudio(); recognitionTask?.cancel(); isRecording = false
		try? AVAudioSession.sharedInstance().setActive(false)
	}
}

enum SpeechLanguage: CaseIterable {
	case englishThenKorean, koreanThenEnglish
	var locale: Locale { switch self { case .englishThenKorean: return Locale(identifier: "en-US"); case .koreanThenEnglish: return Locale(identifier: "ko-KR") } }
	var display: String { switch self { case .englishThenKorean: return "영→한"; case .koreanThenEnglish: return "한→영" } }
}
