## This networking class has 2 different ways of sending network requests


## 1. NetworkRequest

```

// Basic HTTP GET request

let request = NetworkRequest(endpoint: "https://www.google.com")
request.getData { result in
    
}

```

Network request supports `GET, DELETE, PUT, POST, MULTIFORM`

## Easy AF network response parsing.
```

let request = NetworkRequest(endpoint: "https://www.google.com")

request.getData { result in
    switch result {
    case .success(let response):
        let data: Data? = response.data
        
        let lines: [String] = response.dataAsCSV()
        
        let json: [String: Any] = response.dataAsJSON()
        
        let foo: Foo = responseDataAsDecodable(Foo.self)
        
        let httpResponse: HTTPURLResponse = response.httpResponse
        
        let url: URL? = response.url
        
    case .failure(let error):
        
        let httpResponse: HTTPURLResponse = error.httpResponse
        
        let error: Error = error.httpError
        
        // Local enum for simple http status viewing
        let status: HTTPStatus = error.httpStatus
        
    }
}


// Simple Multipart example

let req = NetworkRequest(endpoint: "www.google.com")

let values: [MultipartValues] = [MultipartValues(keyName: "file", 
                                                 fileName: "myImage", 
                                                 data: Data(),
                                                 mimetype: .png)]
req.postMultipart(multipartValues: values) { result in
    
}


```



## 2. NetworkOperation
```

// Create request to pass into your operation
let request = NetworkRequest(endpoint: "www.github.com")

let operation = NetworkOperation(httpMethod: .POST(payload), request: request) { result in
  print(result)
}

operation.execute()

```



####  `NetworkOperation` is built on top of  `OperationQueue`


## Benefits
1. Implicitly ignores duplicate entries
2. Queue ( handles not overloading the system )
3. Quality of service ( Range of UserInitiated vs utility )
4. Dependency chaining ( ie other operations )
5. Will retry failed operation 3 times
6. If subclassed, will attempt to restore if http status code is 401
  
  
  
  #### Here is an example of dependencies with operations 
  
  ```
    
    func specialOperation1() -> NetworkOperation {}
    func sweetOperation2() -> NetworkOperation {}
    
    // Create a DoneOperation with any dependent operations you want linked.
    let doneOperation = DoneOperation(dependentOperations: [
      specialOperation1(),
      sweetOperation2()
    ])
    

    // This "execute" begins all "dependent" operations and wait for a response 
    doneOperation.execute { success in
      print(success)
    }

  ```
  

#### Handling Authentication

Want the operation class to handle restoring your Authentication session if a 401 is received?
Great, then subclass NetworkOperation and override this method.

```
  class AuthNetworkOperation: NetworkOperation {
  
    override func restoreSession(error: NetworkError, 
                                 completion: @escaping (Bool) -> Void) {

      // Go try and re-authenticate
      YourAuthClass.Authenticate() { // Or whatever you name it
      
        // Call the closure passing a success or failure
        completion(success)
        
      }

      // Now every `AuthNetworkOperation` will try 3 times to restore the session for you AND complete the original network call
      
      // Yay!

    }
  }
  
```




