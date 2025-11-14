
import Foundation
import Combine

class StoreService {
    static let shared = StoreService()
    private init() {}

    private let baseURL = APIConstants.baseURL
    private let tokenManager = TokenManager.shared

    // MARK: - Fetch My Store Items
    func fetchMyStore() -> AnyPublisher<[Store], NetworkError> {
        guard let url = URL(string: "/store/my", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [Store].self, decoder: JSONDecoder().withISO8601())
            .mapError { error -> NetworkError in
                if let urlError = error as? URLError { return .transport(urlError) }
                if let decodingError = error as? DecodingError {
                    print("Decoding error:", decodingError)
                    return .decodingFailed
                }
                return .serverError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Create Store Item
    func createStore(_ store: Store) -> AnyPublisher<Store, NetworkError> {
        guard let url = URL(string: "/store", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "clothesId": store.clothesId.id,
            "price": store.price,
            "status": store.status
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: Store.self, decoder: JSONDecoder().withISO8601())
            .mapError { _ in .serverError }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Update Store Item
    func updateStore(_ storeId: String, status: String) -> AnyPublisher<Void, NetworkError> {
        guard let url = URL(string: "/store/\(storeId)", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["status": status])

        return URLSession.shared.dataTaskPublisher(for: request)
            .map { _ in () }
            .mapError { _ in .serverError }
            .eraseToAnyPublisher()
    }

    // MARK: - Delete Store Item
    func deleteStoreItem(_ storeId: String) -> AnyPublisher<Void, NetworkError> {
        guard let url = URL(string: "/store/\(storeId)", relativeTo: baseURL) else {
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
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    // MARK: - Create Store Item (avec body brut)
    func createStoreItem(body: [String: Any]) -> AnyPublisher<Store, NetworkError> {
        guard let url = URL(string: "/store", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue(APIConstants.jsonContentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: Store.self, decoder: JSONDecoder().withISO8601())
            .mapError { error -> NetworkError in
                if let urlError = error as? URLError { return .transport(urlError) }
                if let decodingError = error as? DecodingError {
                    print("Decoding error:", decodingError)
                    return .decodingFailed
                }
                return .serverError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    func fetchAllStoreItems() -> AnyPublisher<[Store], NetworkError> {
        guard let url = URL(string: "/store", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [Store].self, decoder: JSONDecoder().withISO8601())
            .mapError { error -> NetworkError in
                if let urlError = error as? URLError { return .transport(urlError) }
                if let decodingError = error as? DecodingError {
                    print("Decoding error:", decodingError)
                    return .decodingFailed
                }
                return .serverError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    func updateStorePrice(_ storeId: String, price: Double) -> AnyPublisher<Store, NetworkError> {
      guard let url = URL(string: "/store/\(storeId)", relativeTo: baseURL) else {
        return Fail(error: .invalidURL).eraseToAnyPublisher()
      }

      var request = URLRequest(url: url)
      request.httpMethod = "PATCH"
      request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")

      let body = ["price": price]
      request.httpBody = try? JSONSerialization.data(withJSONObject: body)

      return URLSession.shared.dataTaskPublisher(for: request)
        .map(\.data)
        .decode(type: Store.self, decoder: JSONDecoder())
        .mapError { _ in .serverError }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // StoreService.swift

    func markAsSold(_ storeId: String) -> AnyPublisher<Store, NetworkError> {
        guard let url = URL(string: "/store/\(storeId)", relativeTo: baseURL) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(tokenManager.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Envoyer le body avec le status
        let body = ["status": "sold"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw NetworkError.serverError
                }
                
                // Log pour debug
                print("Status code:", httpResponse.statusCode)
                
                guard httpResponse.statusCode == 200 else {
                    throw NetworkError.serverError
                }
                return output.data
            }
            .decode(type: Store.self, decoder: JSONDecoder().withISO8601())
            .mapError { error -> NetworkError in
                print("Error marking as sold:", error)
                if let urlError = error as? URLError { return .transport(urlError) }
                if let decodingError = error as? DecodingError {
                    print("Decoding error:", decodingError)
                    return .decodingFailed
                }
                return .serverError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
