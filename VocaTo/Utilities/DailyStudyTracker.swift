import Foundation

final class DailyStudyTracker {
	static let shared = DailyStudyTracker()
	private let defaults = UserDefaults.standard
	private let keyPrefix = "studySeconds_"
	private var sessionStart: Date?
	private init() {}
	
	func startSession() {
		sessionStart = Date()
	}
	
	func endSession() {
		guard let start = sessionStart else { return }
		let elapsed = max(0, Date().timeIntervalSince(start))
		addToday(seconds: Int(elapsed))
		sessionStart = nil
	}
	
	func addToday(seconds: Int) {
		let key = keyForToday()
		let current = defaults.integer(forKey: key)
		defaults.set(current + max(0, seconds), forKey: key)
	}
	
	func todaySeconds() -> Int {
		defaults.integer(forKey: keyForToday())
	}
	
	private func keyForToday() -> String {
		let df = DateFormatter()
		df.dateFormat = "yyyy-MM-dd"
		return keyPrefix + df.string(from: Date())
	}
}
