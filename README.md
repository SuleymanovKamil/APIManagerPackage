# APIManager

APIManager is a SPM tool, that provides a convenient interface for executing HTTP requests to APIs. It is based on URLSession and supports the new async/await mechanism, which allows making request execution more efficient and convenient.

APIManager provides various methods for executing requests according to the type of HTTP method (GET, POST, PUT, DELETE), and also allows configuring various request parameters such as headers, request body, etc.

Through the use of asynchronous programming and support for async/await, APIManager enables the execution of requests without blocking the main thread, which improves application responsiveness and enhances the user experience.

APIManager is a reliable and convenient package for working with APIs in Swift-based applications.

To use, add this SPM to your project, and add extension with your API url:

```
import APIManager

extension Endpoint {
    var url: URL? {
        let url = API.baseURL
        return URL(string: url + path)
    }
}
```

Example of usage:

Store:
```
 func getData() async throws -> Model {
        guard let result = await APIManager().sendRequest(
            model: Model.self,
            endpoint: Endpoint
        ) else {
            throw RequestError.statusNotOk
        }

        switch result {
        case .success(let response):
            return response
        case .failure:
            throw RequestError.statusNotOk
        }
    }
```

Fetch data

```
 @MainActor func fetchData() async throws -> Model? {
        do {
            let result = try await store.getData()
            return result
        } catch {
            print(#function, error.localizedDescription)
            return nil
        }
    }
```

