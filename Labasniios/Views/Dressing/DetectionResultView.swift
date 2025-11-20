// DetectionResultView.swift
import SwiftUI

struct DetectionResultView: View {
    let image: UIImage?
    let resultText: String
    @Binding var isShowing: Bool
    @Binding var isUploading: Bool
    
    // Champs éditables
    @State private var itemType = ""
    @State private var itemColorHex = ""
    @State private var itemStyle = ""
    @State private var selectedSeason: Season = .summer
    
    enum Season: String, CaseIterable, Identifiable {
        case summer = "Summer"
        case winter = "Winter"
        case spring = "Spring"
        case fall = "Fall"
        var id: Self { self }
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header + Close
                HStack {
                    Text("New Item Detected")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.themePrimary)
                    
                    Spacer()
                    
                    Button { isShowing = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                
                // Photo
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 340)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.themePrimary, lineWidth: 4)
                        )
                        .shadow(color: .themePrimary.opacity(0.4), radius: 20)
                        .padding(.horizontal, 20)
                }
                
                // Champs éditables
                VStack(spacing: 22) {
                    editableField(title: "Type", text: $itemType, placeholder: "e.g. Dress, T-Shirt, Pants...")
                    colorField()
                    editableField(title: "Style", text: $itemStyle, placeholder: "e.g. Casual, Chic, Sporty...")
                    seasonField()
                }
                .padding(.horizontal, 20)
                
                // Bouton final
                Button {
                    // TODO: Sauvegarde dans MongoDB
                    isShowing = false
                } label: {
                    Text("Add to Dressing")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.themePrimary)
                        .cornerRadius(16)
                        .shadow(color: .themePrimary.opacity(0.6), radius: 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .padding(.top, 30)
        }
        .onAppear {
            // On attend un tout petit peu que le texte soit bien mis à jour
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                parseResult()
            }
        }
    }
    
    // Champ texte classique
    private func editableField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.themeText)
            
            TextField(placeholder, text: text)
                .padding(14)
                .background(Color.themeCard)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.themePrimary.opacity(0.3), lineWidth: 1.5)
                )
        }
    }
    
    // Champ couleur avec carré
    private func colorField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
                .font(.headline)
                .foregroundColor(.themeText)
            
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(safeColor(from: itemColorHex))
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.themePrimary.opacity(0.5), lineWidth: 2)
                    )
                
                TextField("e.g. #FF5733", text: $itemColorHex)
                    .autocapitalization(.none)
                    .keyboardType(.webSearch)
                    .padding(14)
                    .background(Color.themeCard)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.themePrimary.opacity(0.3), lineWidth: 1.5)
                    )
            }
        }
    }
    
    // Dropdown saison
    private func seasonField() -> some View {
        HStack {
            Text("Season")
                .font(.headline)
                .foregroundColor(.themeText)
            
            Spacer()
            
            Picker("Season", selection: $selectedSeason) {
                ForEach(Season.allCases) { season in
                    Text(season.rawValue).tag(season)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 180)
            .padding(10)
            .background(Color.themeCard)
            .cornerRadius(14)
        }
    }
    
    // Couleur sécurisée (jamais nil)
    private func safeColor(from hex: String) -> Color {
        let cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                          .replacingOccurrences(of: "#", with: "")
        
        guard !cleanHex.isEmpty,
              (cleanHex.count == 6 || cleanHex.count == 8),
              let value = UInt64(cleanHex, radix: 16) else {
            return Color.gray.opacity(0.4)
        }
        
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        
        return Color(red: r, green: g, blue: b)
    }
    
    // Parsing du texte Python
    private func parseResult() {
        print(" Texte brut reçu du Python :\n\(resultText)") // DEBUG – tu verras tout dans la console
        
        let lines = resultText.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            // Extraire avec ":"
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let value = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                
                let key = trimmed[..<colonIndex].lowercased()
                
                if key.contains("type") || key.contains("vêtement") {
                    itemType = cleanValue(value)
                }
                else if key.contains("couleur") || key.contains("color") {
                    itemColorHex = value.replacingOccurrences(of: "#", with: "")
                }
                else if key.contains("style") {
                    itemStyle = cleanValue(value)
                }
                else if key.contains("saison") || key.contains("season") {
                    let seasonLower = value.lowercased()
                    if seasonLower.contains("summer") { selectedSeason = .summer }
                    else if seasonLower.contains("winter") { selectedSeason = .winter }
                    else if seasonLower.contains("spring") || seasonLower.contains("printemps") { selectedSeason = .spring }
                    else if seasonLower.contains("fall") || seasonLower.contains("autumn") || seasonLower.contains("automne") { selectedSeason = .fall }
                }
            }
        }
        
        // Si rien n'a été trouvé → fallback simple
        if itemType.isEmpty {
            if resultText.lowercased().contains("tshirt") || resultText.lowercased().contains("top") { itemType = "T-Shirt" }
            else if resultText.lowercased().contains("robe") || resultText.lowercased().contains("dress") { itemType = "Dress" }
            else if resultText.lowercased().contains("pantalon") || resultText.lowercased().contains("pants") { itemType = "Pants" }
        }
        
        print(" Rempli → Type: \(itemType), Color: #\(itemColorHex), Style: \(itemStyle), Season: \(selectedSeason.rawValue)")
    }

    // Nettoie les valeurs (supprime les tirets, etc.)
    private func cleanValue(_ str: String) -> String {
        return str.components(separatedBy: .whitespaces).joined(separator: " ").capitalized
    }
}
