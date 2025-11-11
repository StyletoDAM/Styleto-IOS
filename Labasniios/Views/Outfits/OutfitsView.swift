import SwiftUI

private struct StaticTenue: Identifiable {
    let id = UUID()
    let title: String
    let itemsCount: Int
    let dateLabel: String
    let isFavorite: Bool
    let emojis: [String]

    static let list: [StaticTenue] = [
        .init(title: "Look Casual", itemsCount: 3, dateLabel: "Aujourd'hui", isFavorite: true, emojis: ["👕", "👖", "👟"]),
        .init(title: "Tenue Bureau", itemsCount: 4, dateLabel: "Hier", isFavorite: false, emojis: ["👔", "👖", "🥿"]),
        .init(title: "Sport", itemsCount: 2, dateLabel: "Mar.", isFavorite: true, emojis: ["👕", "👟"])
    ]
}

struct TenuesView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    private let tenues = StaticTenue.list

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                suggestionCard
                sectionHeader
                tenueList
                floatingButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        Text("Mes Tenues")
            .font(.system(size: 36, weight: .bold))
            .foregroundColor(.themePrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var suggestionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggestion du jour")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Text("Il fait beau aujourd'hui ! Pourquoi ne pas essayer une tenue légère et colorée ?")
                .foregroundColor(.white.opacity(0.95))
            Button(action: {}) {
                Text("Voir la suggestion")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundColor(.themePrimary)
                    .clipShape(Capsule())
            }
            .padding(.top, 2)
        }
        .padding(20)
        .background(
            LinearGradient(colors: [.themeSecondary, .themePrimary], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 10)
    }

    private var sectionHeader: some View {
        Text("Tenues récentes")
            .font(.system(size: 22, weight: .semibold))
            .foregroundColor(.themeTeal)
    }

    private var tenueList: some View {
        VStack(spacing: 18) {
            ForEach(tenues) { tenue in
                TenueCard(tenue: tenue)
            }
        }
    }

    private var floatingButton: some View {
        HStack {
            Spacer()
            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Color.themeTeal)
                            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
                    )
            }
            .accessibilityIdentifier("add-tenue-button")
        }
        .padding(.top, 12)
    }
}

private struct TenueCard: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let tenue: StaticTenue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tenue.title)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.themeTeal)
                    Text("\(tenue.itemsCount) articles")
                        .font(.subheadline)
                        .foregroundColor(.themeSecondaryText)
                }
                Spacer()
                Image(systemName: tenue.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(tenue.isFavorite ? .themePrimary : .themeSecondary)
            }

            HStack(spacing: 14) {
                ForEach(tenue.emojis.prefix(3), id: \.self) { emoji in
                    Text(emoji)
                        .font(.system(size: 22))
                        .frame(width: 56, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(emoji == "👖" ? Color.themeAqua.opacity(0.25) : Color.themeSoftPink.opacity(0.45))
                        )
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(.themeTeal.opacity(0.7))
                Text(tenue.dateLabel)
                    .font(.subheadline)
                    .foregroundColor(.themeTeal.opacity(0.7))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.themeCard)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
    }
}

#Preview {
    TenuesView()
}
