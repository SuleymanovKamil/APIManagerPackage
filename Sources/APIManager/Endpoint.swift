import Foundation

enum Server {
    case takeclass(String)
    case slack
}

protocol Endpoint {
    var path: String { get }
    var requestType: RequestType { get }
    var header: [String: String]? { get }
    var parameters: [String: Any]? { get }
    var url: URL? { get }
    var server: Server { get }
}
