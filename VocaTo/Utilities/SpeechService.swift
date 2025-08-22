import Foundation
import AVFoundation

final class SpeechService {
	static let shared = SpeechService()
	private let synthesizer = AVSpeechSynthesizer()
	private init() {}
	
	// 기본 TTS 메서드
	func speak(_ text: String, languageCode: String) {
		guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
		let utterance = AVSpeechUtterance(string: text)
		utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
		utterance.rate = AVSpeechUtteranceDefaultSpeechRate
		synthesizer.speak(utterance)
	}
	
	// 언어 설정에 따른 TTS (단어용)
	func speakTerm(_ text: String) {
		let learningLangRaw = UserDefaults.standard.string(forKey: "learningLanguage") ?? "en"
		let languageCode: String
		
		switch learningLangRaw {
		case "ko": languageCode = "ko-KR"
		case "ja": languageCode = "ja-JP"
		case "zh": languageCode = "zh-CN"
		default: languageCode = "en-US"
		}
		
		speak(text, languageCode: languageCode)
	}
	
	// 언어 설정에 따른 TTS (뜻용)
	func speakMeaning(_ text: String) {
		let systemLangRaw = UserDefaults.standard.string(forKey: "systemLanguage") ?? "ko"
		let languageCode: String
		
		switch systemLangRaw {
		case "en": languageCode = "en-US"
		case "ja": languageCode = "ja-JP"
		case "zh": languageCode = "zh-CN"
		default: languageCode = "ko-KR"
		}
		
		speak(text, languageCode: languageCode)
	}
	
	func stop() {
		synthesizer.stopSpeaking(at: .immediate)
	}
}
