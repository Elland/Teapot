import Foundation

/// A subclass of Teapot to be used for mocking
open class MockTeapot: Teapot {

    open var currentBundle: Bundle

    public enum MockError: Error {
        case missingMockFile(String)
        case invalidMockFile(String)
    }
    
    /// Initialiser.
    ///
    /// - Parameters:
    ///   - bundle: the bundle of your test target. When you add a json file with the name of the endpoint to your test target it will return this data.
    public init(bundle: Bundle) {
        self.currentBundle = bundle

        super.init(baseURL: URL(string: "https://mock.base.url.com")!)
    }

    override func execute(verb _: Verb, path: String, parameters _: RequestParameter? = nil, headerFields _: [String: String]? = nil, timeoutInterval _: TimeInterval = 5.0, allowsCellular _: Bool = true, completion: @escaping ((NetworkResult) -> Void)) {
        self.getMockedData(forPath: path) { json, error in
            let response = HTTPURLResponse(url: URL(string: path)!, statusCode: 200, httpVersion: nil, headerFields: nil)
            let requestParameter = json != nil ? RequestParameter(json!) : nil

            let networkResult = NetworkResult(requestParameter, response!, error)

            completion(networkResult)
        }
    }

    func getMockedData(forPath path: String, completion: @escaping (([String: Any]?, Error?) -> Void)) {
        let resource = (path as NSString).lastPathComponent

        if let url = currentBundle.url(forResource: resource, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(json, nil)
                } else {
                    completion(nil, MockError.invalidMockFile("\(resource).json"))
                }
            } catch let error {
                completion(nil, MockError.invalidMockFile("error: \(error.localizedDescription) In file: '\(resource).json'"))
            }
        } else {
            completion(nil, MockError.missingMockFile("\(resource).json"))
        }
    }
}