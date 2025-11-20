import Foundation

class ClothesService {
    static let shared = ClothesService()
    
    private let baseURL = APIConstants.baseURL
    
    func fetchMyClothes(completion: @escaping (Result<[Clothe], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/cloth/my") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                //completion(.failure(URLError(.noData)))
                return
            }
            
            do {
                let clothes = try JSONDecoder().decode([Clothe].self, from: data)
                completion(.success(clothes))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    func deleteClothe(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = TokenManager.shared.getToken() else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: nil)))
            return
        }

        let url = URL(string: "\(baseURL)/cloth/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
            }
        }.resume()
    }
    func addClothe(
        imageURL: String,
        category: String,
        color: String,
        style: String,
        season: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/cloth") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        guard let token = TokenManager.shared.getToken() else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non connecté"])))
            return
        }
        
        let body = [
            "imageURL": imageURL,
            "category": category,
            "color": color,
            "style": style,
            "season": season
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 201 {
                completion(.success(()))
            } else {
                let msg = String(data: data ?? Data(), encoding: .utf8)  ?? "Erreur inconnue"
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])))
            }
        }.resume()
    }
}
