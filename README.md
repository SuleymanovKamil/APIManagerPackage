# APIManager

Native URLSession with async/await and errors handling.

To use, add SPM to your project.
Add extension with your API url:

import APIManager

extension Endpoint {
    var url: URL? {
        let url = API.baseURL
        return URL(string: url + path)
    }
}
