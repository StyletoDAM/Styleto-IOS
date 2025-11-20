// DetectionResultView.swift
import SwiftUI

struct DetectionResultView: View {
    let image: UIImage?
    let resultText: String
    @Binding var isShowing: Bool
    @Binding var isUploading: Bool
    
    // MARK: - Editable States
    @State private var selectedCategory: Category = .top
    @State private var selectedStyle: Style = .casual
    @State private var selectedSeason: Season = .all
    @State private var detectedColorName = "Pink"
    @State private var detectedColor: Color = .pink
    
    // MARK: - Enums (English)
    enum Category: String, CaseIterable, Identifiable {
        case top = "Top", bottom = "Bottom", dress = "Dress", shoes = "Shoes",
             accessory = "Accessory", jacket = "Jacket"
        var id: Self { self }
    }
    
    enum Style: String, CaseIterable, Identifiable {
        case casual = "Casual", elegant = "Elegant", sport = "Sport",
             vintage = "Vintage", modern = "Modern", boho = "Bohemian"
        var id: Self { self }
    }
    
    enum Season: String, CaseIterable, Identifiable {
        case summer = "Summer", winter = "Winter", fall = "Fall",
             spring = "Spring", all = "All seasons"
        var id: Self { self }
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // MARK: Header
                HStack {
                    Text("Clothing Details")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color.themePrimary)   // ← corrigé
                    
                    Spacer()
                    
                    Button { isShowing = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(Color.themePrimary) // ← corrigé
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                
                // MARK: Image + AI Badge
                ZStack(alignment: .topTrailing) {
                    if let uiImage = image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 340)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Color.themePrimary.opacity(0.3), Color.themeTeal.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .overlay(
                                Text("Demo Item")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.8))
                            )
                    }
                    
                    Button {
                        // Re-run AI analysis
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("AI Analyzed")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Color.themePrimary.opacity(0.95)) // ← corrigé
                        .cornerRadius(20)
                    }
                    .padding(16)
                }
                .cornerRadius(28)
                .padding(.horizontal, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // MARK: Clothing Type
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Clothing Type")
                                .font(.headline)
                                .foregroundColor(Color.themePrimary) // ← corrigé
                            
                            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 12) {
                                ForEach(Category.allCases) { cat in
                                    Text(cat.rawValue)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(selectedCategory == cat ? .white : Color.themePrimary) // ← corrigé
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            selectedCategory == cat
                                                ? Color.themePrimary
                                                : Color.themePrimary.opacity(0.12)
                                        )
                                        .cornerRadius(20)
                                        .onTapGesture { selectedCategory = cat }
                                }
                            }
                        }
                        
                        // MARK: Detected Color
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Detected Color")
                                .font(.headline)
                                .foregroundColor(Color.themePrimary) // ← corrigé
                            
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(detectedColor)
                                    .frame(width: 68, height: 68)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.themePrimary.opacity(0.4), lineWidth: 4)
                                    )
                                    .shadow(radius: 8)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(detectedColorName)
                                        .font(.title3.bold())
                                        .foregroundColor(Color.themeText)
                                    
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(Color.themePrimary) // ← corrigé
                                        Text("Automatically detected by AI")
                                            .font(.footnote)
                                            .foregroundColor(Color.themeSecondaryText)
                                    }
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.themePrimary.opacity(0.08)) // ← corrigé
                            .cornerRadius(18)
                        }
                        
                        // MARK: Style
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Style")
                                .font(.headline)
                                .foregroundColor(Color.themePrimary) // ← corrigé
                            
                            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 12) {
                                ForEach(Style.allCases) { style in
                                    Text(style.rawValue)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(selectedStyle == style ? .white : Color.themeTeal) // ← corrigé
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            selectedStyle == style
                                                ? Color.themeTeal
                                                : Color.themeTeal.opacity(0.12)
                                        )
                                        .cornerRadius(20)
                                        .onTapGesture { selectedStyle = style }
                                }
                            }
                        }
                        
                        // MARK: Season
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Season")
                                .font(.headline)
                                .foregroundColor(Color.themePrimary) // ← corrigé
                            
                            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 14) {
                                ForEach(Season.allCases) { season in
                                    Text(season.rawValue)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(selectedSeason == season ? .white : Color.themeTeal) // ← corrigé
                                        .padding(.vertical, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            selectedSeason == season
                                                ? Color.themeTeal
                                                : Color.themeTeal.opacity(0.12)
                                        )
                                        .cornerRadius(20)
                                        .onTapGesture { selectedSeason = season }
                                }
                            }
                        }
                        
                        // MARK: AI Suggestion Note
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(Color.themePrimary) // ← corrigé
                            Text("The information above was pre-filled by our AI. Feel free to edit as you like!")
                                .font(.footnote)
                                .foregroundColor(Color.themeSecondaryText)
                            Spacer()
                        }
                        .padding()
                        .background(Color.themeTeal.opacity(0.08)) // ← corrigé
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                }
                
                // MARK: Add Button
                Button {
                    isShowing = false
                } label: {
                    Text("Add to Wardrobe")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            LinearGradient(
                                colors: [Color.themePrimary, Color.themePrimary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(22)
                        .shadow(color: Color.themePrimary.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                parseResult()
            }
        }
    }
    
    // MARK: - Parsing (inchangé)
    private func parseResult() {
        print("Raw AI result:\n\(resultText)")
        
        let lines = resultText.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  let colonIndex = trimmed.firstIndex(of: ":")
            else { continue }
            
            let key = trimmed[..<colonIndex].lowercased()
            let value = trimmed[trimmed.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
            
            if key.contains("type") || key.contains("clothing") || key.contains("vêtement") {
                let v = value.lowercased()
                if v.contains("top") || v.contains("shirt") || v.contains("haut") { selectedCategory = .top }
                else if v.contains("bottom") || v.contains("pant") || v.contains("jean") { selectedCategory = .bottom }
                else if v.contains("dress") || v.contains("robe") { selectedCategory = .dress }
                else if v.contains("shoe") || v.contains("chaussure") { selectedCategory = .shoes }
                else if v.contains("jacket") || v.contains("veste") { selectedCategory = .jacket }
                else if v.contains("accessory") { selectedCategory = .accessory }
            }
            else if key.contains("color") || key.contains("couleur") {
                detectedColorName = value.capitalized
                if let hexColor = extractHex(from: value) {
                    detectedColor = Color(hex: hexColor) ?? .pink
                } else {
                    detectedColor = colorFromName(value) ?? .pink
                }
            }
            else if key.contains("style") {
                let v = value.lowercased()
                if v.contains("casual") { selectedStyle = .casual }
                else if v.contains("elegant") || v.contains("chic") { selectedStyle = .elegant }
                else if v.contains("sport") { selectedStyle = .sport }
                else if v.contains("vintage") { selectedStyle = .vintage }
                else if v.contains("modern") || v.contains("moderne") { selectedStyle = .modern }
                else if v.contains("boho") || v.contains("boheme") { selectedStyle = .boho }
            }
            else if key.contains("season") || key.contains("saison") {
                let v = value.lowercased()
                if v.contains("summer") || v.contains("été") { selectedSeason = .summer }
                else if v.contains("winter") || v.contains("hiver") { selectedSeason = .winter }
                else if v.contains("fall") || v.contains("autumn") || v.contains("automne") { selectedSeason = .fall }
                else if v.contains("spring") || v.contains("printemps") { selectedSeason = .spring }
                else { selectedSeason = .all }
            }
        }
    }
    
    private func extractHex(from text: String) -> String? {
        let pattern = "#?[A-Fa-f0-9]{6}"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            return String(text[range]).replacingOccurrences(of: "#", with: "")
        }
        return nil
    }
    
    private func colorFromName(_ name: String) -> Color? {
        let n = name.lowercased()
        switch n {
        case _ where n.contains("pink"): return .pink
        case _ where n.contains("red"): return .red
        case _ where n.contains("blue"): return .blue
        case _ where n.contains("black"): return .black
        case _ where n.contains("white"): return .white
        case _ where n.contains("green"): return .green
        case _ where n.contains("yellow"): return .yellow
        case _ where n.contains("purple"): return .purple
        default: return nil
        }
    }
}
