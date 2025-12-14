// AIAnalysisLoadingView.swift - VERSION FINALE (pour nouveau backend)
import SwiftUI

struct AIAnalysisLoadingView: View {
    let image: UIImage?
    let onAnalysisComplete: (String, String?) -> Void
    
    @State private var rotation: Double = 0
    @State private var analysisText = "AI is analysing your clothe"
    @State private var dotCount = 0
    
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            AngularGradient(
                                colors: [Color.themePrimary.opacity(0.6), Color.themeTeal],
                                center: .center
                            ),
                            lineWidth: 8
                        )
                        .rotationEffect(.degrees(rotation))
                        .frame(width: 140, height: 140)
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: rotation)
                    
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color.themePrimary)
                }
                .onAppear {
                    rotation = 360
                }
                
                Text("Analysing...")
                    .font(.title2.bold())
                    .foregroundColor(Color.themePrimary)
                
                Text(analysisText + String(repeating: ".", count: dotCount))
                    .font(.subheadline)
                    .foregroundColor(.themeSecondaryText)
                    .onReceive(timer) { _ in
                        dotCount = (dotCount + 1) % 4
                    }
                
                Spacer()
                
                HStack(spacing: 32) {
                    miniClothItem(color: .pink.opacity(0.4))
                    miniClothItem(color: .teal.opacity(0.4))
                    miniClothItem(color: .purple.opacity(0.4))
                    miniClothItem(color: .blue.opacity(0.4))
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            performAIAnalysis()
        }
    }
    
    private func miniClothItem(color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tshirt")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.gradient)
                )
            
            Circle()
                .fill(Color.themePrimary)
                .frame(width: 6, height: 6)
        }
    }
    
    // ✅ VERSION FINALE (pour nouveau backend sans sauvegarde BD)
    private func performAIAnalysis() {
        guard let image = image,
              let imageData = image.jpegData(compressionQuality: 0.85) else {
            onAnalysisComplete("Erreur: Image invalide", nil)
            return
        }
        
        let url = URL(string: "\(APIConstants.baseURL.absoluteString)/detect")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Token JWT
        if let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ Token JWT manquant")
            onAnalysisComplete("Erreur: Non authentifié", nil)
            return
        }
        
        // Multipart form-data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        print("📤 [AIAnalysisLoadingView] Envoi détection...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur réseau: \(error.localizedDescription)")
                    onAnalysisComplete("Erreur réseau: \(error.localizedDescription)", nil)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Code HTTP: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 401 {
                        onAnalysisComplete("Erreur: Non authentifié", nil)
                        return
                    }
                    
                    if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
                        onAnalysisComplete("Erreur serveur (\(httpResponse.statusCode))", nil)
                        return
                    }
                }
                
                guard let data = data else {
                    onAnalysisComplete("Erreur: Pas de données", nil)
                    return
                }
                
                // Debug
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Réponse: \(responseString)")
                }
                
                do {
                    // ✅ NOUVEAU FORMAT BACKEND
                    // {
                    //   "detection": { type, color, style, season },
                    //   "confidence": { detection, style, season },
                    //   "image_url": "https://..."
                    // }
                    
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    guard let detection = json?["detection"] as? [String: Any],
                          let imageUrl = json?["image_url"] as? String else {
                        onAnalysisComplete("Erreur: Format invalide", nil)
                        return
                    }
                    
                    // Extraire les infos
                    let type = detection["type"] as? String ?? "unknown"
                    let color = detection["color"] as? String ?? "#808080"
                    let style = detection["style"] as? String ?? "casual"
                    let season = detection["season"] as? String ?? "all"
                    
                    // Formater pour DetectionResultView
                    let result = """
                    Type du vêtement : \(type)
                    Couleur dominante : \(color)
                    Style : \(style)
                    Saison : \(season)
                    """
                    
                    print("✅ Détection OK: \(type) | \(color)")
                    print("☁️  Image URL: \(imageUrl)")
                    
                    // ✅ Passer imageUrl pour DetectionResultView
                    onAnalysisComplete(result, imageUrl)
                    
                } catch {
                    print("❌ Erreur parsing: \(error)")
                    onAnalysisComplete("Erreur de parsing", nil)
                }
            }
        }.resume()
    }
}
