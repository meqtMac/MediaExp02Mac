// The Swift Programming Language
// https://docs.swift.org/swift-book

public struct HTTPRequest {
//    var path: String
//    var headers: [String: String]
    fileprivate class Storage {
        var path: String
        var headers: [String: String]
        init(path: String, headers: [String : String]) {
            self.path = path
            self.headers = headers
        }
    }
    
    private var storage: Storage
    
    init(path: String, headers: [String: String]) {
        storage = Storage(path: path, headers: headers)
    }
}



extension HTTPRequest.Storage {
    func copy() -> HTTPRequest.Storage {
        print("Making a copy...")
        return HTTPRequest.Storage(path: path, headers: headers)
    }
}


extension HTTPRequest {
    var path: String {
        get { storage.path }
        set {
            // TODO: implement
            storage = storage.copy()
            storage.path = newValue
        }
    }
    
    var headers: [String: String] {
        get { storage.headers }
        set {
            // TODO: implement
            storage = storage.copy()
            storage.headers = newValue
        }
    }
}
