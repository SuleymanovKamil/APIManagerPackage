import Foundation

public extension Data {
    mutating func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}

public extension Data {
    func decode<T: Codable>(model: T.Type) -> T? {
         return try? JSONDecoder().decode(model.self, from: self)
    }
}

public extension Data {
    // NSString gives us a nice sanitized debugDescription
    // How to use:
    // let str = "{\"foo\": \"bar\"}".data(using: .utf8)!.prettyPrintedJSONString!
    // debugPrint(str)
    var prettyPrintedJSONString: NSString? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        else {
            return nil
        }

        return prettyPrintedString
    }
}
