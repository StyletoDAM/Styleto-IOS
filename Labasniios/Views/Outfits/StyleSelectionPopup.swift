import SwiftUI
 
struct StyleSelectionPopup: View {
    @Binding var isPresented: Bool
    var onStyleSelected: (String) -> Void
    
    //  6 styles avec icônes appropriées
    let styles: [(name: String, icon: String, description: String)] = [
        ("Casual", "tshirt.fill", "Relaxed everyday style"),
        ("Elegant", "sparkles", "Sophisticated and refined"),
        ("Sport", "figure.run", "Active and athletic"),
        ("Vintage", "clock.fill", "Classic retro vibes"),
        ("Modern", "square.stack.3d.up.fill", "Contemporary and sleek"),
        ("Bohemian", "leaf.fill", "Free-spirited and artistic")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Titre
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundColor(.themePrimary)
                        
                        Text("Choose Your Style")
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                        
                        Text("Our AI will create the perfect outfit based on current weather and your style preference")
                            .font(.subheadline)
                            .foregroundColor(.themeSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    // MARK: - Grille des styles (2 colonnes)
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(styles, id: \.name) { style in
                            Button {
                                // Convertir en lowercase pour correspondre au backend
                                let backendStyle = style.name.lowercased()
                                onStyleSelected(backendStyle)
                                isPresented = false
                                print("🎨 User selected style:", backendStyle)
                            } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: style.icon)
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                        .frame(width: 60, height: 60)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                        )
                                    
                                    VStack(spacing: 4) {
                                        Text(style.name)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text(style.description)
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    LinearGradient(
                                        colors: [.themePrimary, .themeSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: - Bouton Cancel
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
                    .padding(.vertical, 20)
                }
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("AI Style Selection")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
