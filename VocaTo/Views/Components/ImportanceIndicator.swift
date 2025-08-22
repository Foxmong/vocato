import SwiftUI

struct ImportanceIndicator: View {
    let importanceCount: Int32
    
    var body: some View {
        if importanceCount > 0 {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                
                Text("\(importanceCount)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ImportanceIndicator(importanceCount: 0)
        ImportanceIndicator(importanceCount: 1)
        ImportanceIndicator(importanceCount: 5)
        ImportanceIndicator(importanceCount: 10)
    }
    .padding()
}
