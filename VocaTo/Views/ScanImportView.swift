import SwiftUI
import VisionKit
import Vision
import PhotosUI
import CoreData

struct ScanImportView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.managedObjectContext) private var context
	@State private var recognizedText: String = ""
	@State private var parsedPairs: [(String, String)] = []
	@State private var selection: Set<Int> = []
	@State private var showError = false
	@State private var errorMessage = ""
	@State private var showPhotoPicker = false
	@State private var selectedImage: UIImage?
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 12) {
				if DataScannerView.isSupported {
					DataScannerView(text: $recognizedText)
						.frame(height: 320)
						.background(Color.black.opacity(0.05))
						.clipShape(RoundedRectangle(cornerRadius: 12))
				} else {
					VStack(spacing: 8) {
						Text("이 기기에서는 실시간 스캔이 지원되지 않습니다")
							.font(.subheadline)
							.foregroundStyle(.secondary)
						Button("이미지에서 텍스트 인식") { showPhotoPicker = true }
					}
					.frame(height: 320)
					.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
				}
				
				// 인식 결과 미리보기
				VStack(alignment: .leading, spacing: 8) {
					HStack {
						Text("인식된 텍스트")
							.font(.headline)
						Spacer()
						Button("파싱") { parseText() }
							.disabled(recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
					}
					ScrollView { Text(recognizedText).font(.caption) }
				}
				.padding()
				.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
				
				// 파싱 결과
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
			.navigationTitle("문서 스캔")
			.toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("취소") { dismiss() } } }
			.alert("오류", isPresented: $showError) { Button("확인", role: .cancel) {} } message: { Text(errorMessage) }
			.photosPicker(isPresented: $showPhotoPicker, selection: .constant(nil)) // 트리거용
		}
	}
	
	private func toggle(_ idx: Int) { if selection.contains(idx) { selection.remove(idx) } else { selection.insert(idx) } }
	
	private func parseText() {
		let lines = recognizedText
			.replacingOccurrences(of: "\r", with: "\n")
			.components(separatedBy: .newlines)
			.map { $0.trimmingCharacters(in: .whitespaces) }
			.filter { !$0.isEmpty }
		var result: [(String,String)] = []
		for line in lines {
			if let range = line.range(of: "-") ?? line.range(of: ":") ?? line.range(of: ",") {
				let term = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
				let meaning = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
				if !term.isEmpty && !meaning.isEmpty { result.append((term, meaning)) }
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
}

// DataScanner Wrapper (iOS 16.2+)
struct DataScannerView: UIViewControllerRepresentable {
	@Binding var text: String
	
	static var isSupported: Bool {
		if #available(iOS 16.2, *), DataScannerViewController.isSupported { return true }
		return false
	}
	
	func makeUIViewController(context: Context) -> UIViewController {
		guard #available(iOS 16.2, *), DataScannerViewController.isSupported else { return UIViewController() }
		let vc = DataScannerViewController(recognizedDataTypes: [.text()], qualityLevel: .accurate, recognizesMultipleItems: true, isHighFrameRateTrackingEnabled: false, isPinchToZoomEnabled: true, isGuidanceEnabled: true)
		vc.delegate = context.coordinator
		try? vc.startScanning()
		return vc
	}
	
	func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
	
	func makeCoordinator() -> Coordinator { Coordinator(self) }
	
	class Coordinator: NSObject, DataScannerViewControllerDelegate {
		var parent: DataScannerView
		init(_ parent: DataScannerView) { self.parent = parent }
		@available(iOS 16.2, *)
		func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
			parent.text = extract(allItems)
		}
		@available(iOS 16.2, *)
		func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
			parent.text = extract(allItems)
		}
		@available(iOS 16.2, *)
		private func extract(_ items: [RecognizedItem]) -> String {
			items.compactMap { item in
				if case let .text(t) = item { return t.transcript }
				return nil
			}.joined(separator: "\n")
		}
	}
}
