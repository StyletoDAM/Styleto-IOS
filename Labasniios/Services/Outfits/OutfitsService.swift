// Services/Outfits/OutfitsService.swift
import Foundation
import Combine

class OutfitsService {
    static let shared = OutfitsService()
    private init() {}

    private let baseURL = APIConstants.baseURL
    private let tokenManager = TokenManager.shared

    func fetchMyOutfits() -> AnyPublisher<[Outfit], NetworkError> {
        guard let url = URL(string: APIConstants.outfitsMyPath, relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .handleEvents(receiveOutput: { data in
                if let json = try? JSONSerialization.jsonObject(with: data) {
                    print("Outfits response:", json)
                }
            })
            .decode(type: [Outfit].self, decoder: JSONDecoder().withISO8601())
            .mapError { error -> NetworkError in
                if let urlError = error as? URLError {
                    return .transport(urlError)
                } else if let decodingError = error as? DecodingError {
                    print("Decoding error:", decodingError)
                    return .decodingFailed
                }
                return .serverError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    func generateRandomOutfit() -> AnyPublisher<Outfit, NetworkError> {
        guard let url = URL(string: APIConstants.outfitsGeneratePath, relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: Outfit.self, decoder: JSONDecoder().withISO8601())
            .mapError { error -> NetworkError in
                if let urlError = error as? URLError { return .transport(urlError) }
                return .serverError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    func updateOutfitStatus(_ outfitId: String, status: String) -> AnyPublisher<Void, NetworkError> {
        guard let url = URL(string: "\(APIConstants.outfitsPath)/\(outfitId)", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")

        let body = ["status": status]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return URLSession.shared.dataTaskPublisher(for: request)
            .map { _ in () }
            .mapError { error -> NetworkError in
                if let urlError = error as? URLError { return .transport(urlError) }
                return .serverError
            }
            .eraseToAnyPublisher()
    }

    func deleteOutfit(_ outfitId: String) -> AnyPublisher<Void, NetworkError> {
        guard let url = URL(string: "\(APIConstants.outfitsPath)/\(outfitId)", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")

        return URLSession.shared.dataTaskPublisher(for: request)
            .map { _ in () }
            .mapError { error -> NetworkError in
                if let urlError = error as? URLError { return .transport(urlError) }
                return .serverError
            }
            .eraseToAnyPublisher()
    }
    

    
}

// Extension pour ISO8601
extension JSONDecoder {
    func withISO8601() -> JSONDecoder {
        self.dateDecodingStrategy = .iso8601
        return self
    }
}
