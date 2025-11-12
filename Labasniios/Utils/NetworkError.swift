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
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .requestFailed(let status):
            return "Request failed (\(status))."
        case .decodingFailed:
            return "Invalid response."
        case .noData:
            return "No data received."
        case .serverMessage(let message):
            return message
        case .transport(let error):
            return error.localizedDescription
        case .invalidData:
            return "Invalid data."
        }
    }
}
