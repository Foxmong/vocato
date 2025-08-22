import SwiftUI

struct GlassCard: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Color("PrimaryGreen"))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

struct GlassCardLarge: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title)
                .foregroundStyle(Color("PrimaryGreen"))
            Text(title).font(.largeTitle.bold())
            Text(subtitle).font(.title3).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

