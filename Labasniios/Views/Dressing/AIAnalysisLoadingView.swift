// AIAnalysisLoadingView.swift
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
                
                // Gros cercle animé avec vêtement au centre
                ZStack {
                    // Cercle de progression animé
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
                    
                    // Icône vêtement
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color.themePrimary)
                }
                .onAppear {
                    rotation = 360
                }
                
                // Texte principal
                Text("Analysing...")
                    .font(.title2.bold())
                    .foregroundColor(Color.themePrimary)
                
                // Texte secondaire animé avec points
                Text(analysisText + String(repeating: ".", count: dotCount))
                    .font(.subheadline)
                    .foregroundColor(.themeSecondaryText)
                    .onReceive(timer) { _ in
                        dotCount = (dotCount + 1) % 4
                    }
                
                Spacer()
                
                // Petites vignettes aléatoires en bas
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
    
    private func performAIAnalysis() {
        guard let image = image,
              let imageData = image.jpegData(compressionQuality: 0.85) else {
            onAnalysisComplete("Erreur: Image invalide", nil)
            return
        }
        
        let url = URL(string: "\(APIConstants.baseURL.absoluteString)/detect")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    onAnalysisComplete("Erreur réseau: \(error.localizedDescription)", nil)
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let result = json["detection_result"] as? String else {
                    onAnalysisComplete("Erreur du serveur", nil)
                    return
                }
                
                // Récupérer imageUrl comme Android
                let imageUrl = json["image_url"] as? String
                
                // Validation comme Android - vérifier les données de base
                if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onAnalysisComplete("Résultat de détection vide", nil)
                    return
                }
                
                if let imageUrl = imageUrl, imageUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onAnalysisComplete("URL d'image manquante dans la réponse", nil)
                    return
                }
                
                // Passer les données brutes - validation détaillée dans DressingView
                onAnalysisComplete(result, imageUrl)
            }
        }.resume()
    }
}



