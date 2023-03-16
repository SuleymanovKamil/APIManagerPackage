import Foundation

@available(iOS 15.0, *)
public class APIManager {
    private var boundaryString: String {
        return "Boundary-\(NSUUID().uuidString)"
    }

    private let acceptLanguage: String = {
        let acceptLanguage = Locale.current.acceptLanguage
        return acceptLanguage
    }()
    
    public func sendRequest<T: Codable> (
        model: T.Type,
        endpoint: Endpoint,
        file: UploadData? = nil,
        isDebug: Bool = true
    ) async -> Result<T, RequestError>? {
        guard await NetworkMonitor.checkConnection() else {
            return .failure(.noResponse)
        }

        do {
            guard let url = endpoint.url,
                  let urlRequest = createRequest(with: url, endpoint: endpoint, file: file)
            else {
                return .failure(.invalidURL)
            }

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            return parseResponse(response: response as? HTTPURLResponse, data: data, model: model)
        } catch {
            return .failure(.statusNotOk)
        }
    }

    func sendRequest (
        endpoint: Endpoint,
        isDebug: Bool = false
    ) async throws -> (Data, URLResponse) {
        guard let url = endpoint.url,
              let urlRequest = createRequest(with: url, endpoint: endpoint, file: nil)
        else {
            throw RequestError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        return (data, response)
    }

    private func parseResponse<T: Codable> (
        response: HTTPURLResponse?,
        data: Data,
        model: T.Type
    ) -> Result<T, RequestError>? {
        guard let response = response else {
            return .failure(.noResponse)
        }

        switch response.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            do {
                let parsedData = try decoder.decode(model, from: data)
                return .success(parsedData)
            } catch let error as DecodingError {
                return .failure(.decodingError(error))
            } catch {
                return .failure(.statusNotOk)
            }
        case 400...499:
            return .failure(.unknown(data))
        default:
            return .failure(.unexpectedStatusCode)
        }
    }
}

// MARK: - Private

@available(iOS 15.0, *)
private extension APIManager {
    func createGetRequestWithURLComponents(
        url: URL,
        endpoint: Endpoint
    ) -> URLRequest? {
        var components = URLComponents(string: url.absoluteString)!
        components.queryItems = endpoint.parameters?.compactMap { (key, value) in
            URLQueryItem(name: key, value: "\(value)")
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        var request = URLRequest(url: components.url ?? url)
        request.httpMethod = endpoint.requestType.rawValue

        var header = endpoint.header ?? [:]
        header["Accept-Language"] = acceptLanguage

        request.allHTTPHeaderFields = header

        return request
    }

    func createPostRequestWithBody(
        url: URL,
        endpoint: Endpoint,
        file: UploadData? = nil
    ) -> URLRequest? {
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.requestType.rawValue
        request.allHTTPHeaderFields = endpoint.header

        if let file {
            let boundary = boundaryString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = getParameterBody(with: endpoint.parameters, file: file, boundary: boundary)
        } else if let requestBody = getParameterBody(with: endpoint.parameters) {
            request.httpBody = requestBody
        }

        request.httpMethod = endpoint.requestType.rawValue
        return request
    }

    func getParameterBody(with parameters: [String: Any]?, file: UploadData? = nil, boundary: String? = nil) -> Data? {
        if let file {
            var httpBody = Data()
            if let parameters {
                for (key, value) in parameters {
                    httpBody.appendString(string: "--\(boundaryString)\r\n")
                    httpBody.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                    httpBody.appendString(string: "\(value)\r\n")
                    httpBody.appendString(string: "--\(boundaryString)--\r\n")
                }
            }

            let mimetype = file.mimetype ?? "someType"
            let filename = String(Int(Date().timeIntervalSince1970)) + mimetype
            httpBody.appendString(string: "--\(boundary ?? "")\r\n")
            httpBody.appendString(string: "Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
            httpBody.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
            httpBody.append(file.file)
            httpBody.appendString(string: "\r\n")
            httpBody.appendString(string: "--\(boundary ?? "")--\r\n")
            return httpBody
        } else {
            guard let parameters,
                  let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
                return nil
            }
            return httpBody
        }
    }

    func createRequest(with url: URL,
                       endpoint: Endpoint,
                       file: UploadData? = nil) -> URLRequest? {
        switch endpoint.requestType {
        case .get:
            return createGetRequestWithURLComponents(
                url: url,
                endpoint: endpoint
            )
        case .post, .put, .patch, .delete:
            return createPostRequestWithBody(
                url: url,
                endpoint: endpoint,
                file: file
            )
        }
    }
}
