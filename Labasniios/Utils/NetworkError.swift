import Foundation
struct ErrorResponse: Decodable {
    let statusCode: Int
    let message: String
}

enum NetworkError: LocalizedError {
    case invalidURL
    case requestFailed(Int)
    case decodingFailed
    case noData
    case serverMessage(String)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide."
        case .requestFailed(let status):
            return "La requête a échoué (\(status))."
        case .decodingFailed:
            return "Réponse invalide."
        case .noData:
            return "Aucune donnée reçue."
        case .serverMessage(let message):
            return message
        case .transport(let error):
            return error.localizedDescription
        }
    }
}
