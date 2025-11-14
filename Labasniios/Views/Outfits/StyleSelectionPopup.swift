import SwiftUI

struct StyleSelectionPopup: View {
    @Binding var isPresented: Bool
    @Binding var selectedStyle: String?

    let styles = ["Casual", "Formal", "Sporty", "Elegant", "Party"]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // MARK: - Titre
                Text("Which style are you looking for today?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                // MARK: - Liste des styles
                ForEach(styles, id: \.self) { style in
                    Button(action: {
                        selectedStyle = style
                        isPresented = false
                        print("User selected style:", style)
                    }) {
                        Text(style)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.themePrimary, .themeSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                // MARK: - Bouton Cancel
                Button("Cancel") {
                    isPresented = false
                }
                .font(.subheadline.bold())
                .foregroundColor(.red)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
            .navigationTitle("Pick a Style")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
