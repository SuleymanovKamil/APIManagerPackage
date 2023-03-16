import Foundation

public enum RequestError: Error {
    case statusNotOk
    case decodingError(DecodingError)
    case invalidURL
    case noResponse
    case unexpectedStatusCode
    case unknown(Data)

    var statusCode: Int {
        switch self {
        case .noResponse:
            return 400
        default:
            return 403
        }
    }
}
