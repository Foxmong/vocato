import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry { let date: Date; let term: String; let meaning: String }

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: Date(), term: "VocaTo", meaning: "단어를 추가해보세요") }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) { completion(placeholder(in: context)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = SimpleEntry(date: Date(), term: "VocaTo", meaning: "오늘도 학습을 이어가요")
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct VocaToWidgetEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.term).font(.headline)
            Text(entry.meaning).font(.caption).foregroundStyle(.secondary)
        }
        .padding()
    }
}

@main
struct VocaToWidget: Widget {
    let kind: String = "VocaToWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VocaToWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("VocaTo")
        .description("Today's word to study")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

