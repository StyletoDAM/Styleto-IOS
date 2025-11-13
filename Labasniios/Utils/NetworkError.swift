import Foundation

struct ErrorResponse: Decodable {
    let statusCode: Int
    let message: String
}

enum NetworkError: LocalizedError {
    case invalidURL
    case unauthorized
    case requestFailed(Int)
    case decodingFailed
    case noData
    case serverError           
    case serverMessage(String)
    case transport(Error)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide."
        case .unauthorized:
            return "Non autorisé. Veuillez vous reconnecter."
        case .requestFailed(let status):
            return "Échec de la requête (\(status))."
        case .decodingFailed:
            return "Réponse invalide."
        case .noData:
            return "Aucune donnée reçue."
        case .serverError:
            return "Erreur du serveur. Réessayez plus tard."
        case .serverMessage(let message):
            return message
        case .transport(let error):
            return error.localizedDescription
        case .invalidData:
            return "Données invalides."
        }
    }
}
