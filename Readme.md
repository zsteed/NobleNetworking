## Are you an iOS Dev who loves networking libraries more than you should?


## How does this networking library work! Lets see a simple example


  ```
  // Make request object
  let req = NetworkRequest(endpoint: "www.google.com")
  
  // Call `getData`
  req.getData { result in
  
  // Response is either a success if httpStatusCode in range 200...299
  // Or a failure with enum cases to handle different scenarios
    switch result {
    case .success(let response):
        // Raw data
        print(response.data)

        // CSV
        print(response.dataAsCsv()!)

        // JSON
        print(response.dataAsJson()!)

        // Decodable
        print(response.dataAsDecodable(FooObject.self)!)

        // HTTPURLResponse object
        print(response.httpResponse)

    case .failure(let error):
        // error is an enum that returns different error reasons.
        print(error.localizedDescription)

    }
  }
  ````


### More simple examples

#### DELETE, GET, POST, PUT, MULTIFORM

```
  let req = NetworkRequest(endpoint: "www.google.com")
  
  req.getData
  req.deleteAtEndpoint
  req.deletePayload
  req.getDownloadUrl
  req.postMultipart
  req.postPayload
  req.putPayload
```


  #### Now this is not all, this library supports networking with operations


```
  // Make a new Request
  let request = NetworkRequest(endpoint: "www.github.com")

  // Add your request to a Network Operation
  let operation = NetworkOperation(uniqueId: "LoginOpV2_\(username)", httpMethod: .POST(payload), request: request) { result in
    print(result)
  }
  
  operation.execute()
  
  ```

#### So `NetworkOperation` is built on top of `OperationQueue`


  ///  ** Benefits **
  ///  1. Handles duplicate entries
  ///  2. Queue ( handles not overloading the system )
  ///  3. Quality of service ( Range of UserInitiated vs utility )
  ///  4. Dependency chaining ( ie other operations )
  ///  5. Will retry failed operation 3 times
  ///  6. If subclassed, will attempt to restore if http status code is 401
  
  
  
  #### Here is an example of dependencies with operations 
  
  ```
    // Wait, what about dependency chaining, that's what operation's are all about.
    // Great, glad you asked.
    
    ...Behold...
    
    func specialOperation1() -> NetworkOperation {}
    func sweetOperation2() -> NetworkOperation {}
    
    // Create a DoneOperation with any dependent operations you want linked.
    let doneOperation = DoneOperation(dependentOperations: [
      specialOperation1(),
      sweetOperation2()
    ])
    

    // This "execute" begins all "dependent" operations and the "done" operation. 
    doneOperation.execute { success in
      print("Was successful == \(success)"
    }
    
    
    // Now the done operation won't execute until both 'dependentOperations' finish.
    // Special note, if any of those operations "fail", you will receive an result.error  

  ```
  

#### Handling Authentication

Want the operation class to handle restoring your Authentication session if a 401 is received?
Great, then subclass NetworkOperation and override this method.

```
  class AuthNetworkOperation: NetworkOperation {
  
    override func restoreSession(error: NetworkError, 
                                 completion: @escaping (Bool) -> Void) {

      // Go try and re-authenticate
      Auth.AuthenticateMe() { // Or whatever you name it
      
        // Call the closure passing a success or failure
        completion(success)
        
      }

      // Now every `AuthNetworkOperation` will try 3 times to restore the session for you & complete the original network call
      
      // Yay!

    }
  }
  
```




