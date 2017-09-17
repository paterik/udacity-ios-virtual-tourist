//
//  RequestClient.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 29.08.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import SystemConfiguration

class RequestClient {
    
    //
    // MARK: Constants (Statics)
    //
    
    static let sharedInstance = RequestClient()
    
    //
    // MARK: Constants (Normal)
    //
    
    let debugMode: Bool = true
    let session = URLSession.shared
    let _httpVerbsWrite: [String] = ["POST", "PUT", "PATCH", "DELETE"]
    let _httpVerbsRead: [String] = ["OPTIONS", "GET", "HEAD", "TRACE"]
    
    //
    // MARK: Properties
    //
    
    var username: String?
    var password: String?
    var jsonBody: String = "{}"
    var errorDomain: String = ""
    var errorDomainPrefix: String = "APPClient"
    var errorUserInfo: [String: String] = ["" : ""]
    var isUdacityRequest: Bool! = false
    
    /**
     * check network reachability and connection state of current device
     */
    func requestPossible ()
        
        -> Bool {
            
            var zeroAddress = sockaddr_in()
            var flags = SCNetworkReachabilityFlags()
            
            zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
            zeroAddress.sin_family = sa_family_t(AF_INET)
            
            let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                    SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
                }
            }
            
            if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
                return false
            }
            
            let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
            let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
            
            return (isReachable && !needsConnection)
    }
    
    /*
     * prepare the main request for all api calls within this app, cache will be disabled,
     * standard cahrsat will be utf-8 and we'll always await json as response type. If any
     * none-idempotent http verb will found, application/json will be set as body/data-type
     */
    func requestPrepare (
       _ url: String,
       _ method: String,
       _ headers: [String : String],
       _ jsonDataParams: [String : AnyObject]?,
       _ jsonDataBody: [String : AnyObject]?) -> URLRequest {
        
        var request = NSMutableURLRequest(url: URL(string: url)!)
        
        request.addValue("UTF-8", forHTTPHeaderField: "Accept-Charset")
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        if _httpVerbsWrite.contains(method.uppercased()) {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        request.httpMethod = method
        
        // extend header by defined parametric values
        if !headers.isEmpty {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // get parameter dictionary data not empty? Handle this data as http get parametric data
        if !(jsonDataParams?.values.isEmpty)! {
            
            let parameterString = jsonDataParams!.stringFromHttpParameters()
            let requestURL = URL(string:"\(url)?\(parameterString)")!
            
            if (debugMode) { print (requestURL) }
            
            request = URLRequest(url: requestURL) as! NSMutableURLRequest
        }
        
        // body dictionary data not empty? Handle this data as json-compatible type
        if !(jsonDataBody?.values.isEmpty)! {
            
            if let requestBodyDictionary = jsonDataBody {
                
                // try serialize incoming dictionary body data, set body to nil on any exception during conversion
                let serializedData: Data?; do {
                    serializedData = try JSONSerialization.data(withJSONObject: requestBodyDictionary, options: [])
                } catch {
                    serializedData = nil
                }
                
                request.httpBody = serializedData
            }
        }
        
        return request as URLRequest
    }
    
    /*
     * execute the main request process and handle result using lambda completion handler.
     * we'll use another completionHandler (convertDataWithCompletionHandler) to convert json results
     */
    func requestExecute (
       _ request: URLRequest,
         completionHandlerForRequest: @escaping (_ data: AnyObject?, _ errorString: String?) -> Void) {
        
        // check connection availability and execute request process
        if false == requestPossible() {
            
            completionHandlerForRequest(nil, "Oops! Your device seems not connected to the internet, check your connection state!")
            
        } else {
            
            let task = session.dataTask(with: request as URLRequest) { data, response, error in
                
                var parsedResult: Any!
                var newData: Data!
                
                // our internal error logging method
                func sendError(error: String) {
                    
                    completionHandlerForRequest(nil, error)
                    if self.debugMode { print(error) }
                }
                
                // GUARD: Was there an error?
                guard error == nil else {
                    sendError(error: "Oops! There was a general error with your request: \(String(describing: error))")
                    return
                }
                
                // GUARD: Was there any data returned?
                guard let data = data else {
                    sendError(error: "Oops! No data returned after your request!")
                    return
                }
                
                // UNWRAP: http status code available?
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    
                    if statusCode == 403 {
                        sendError(error: "Oops! The API authantication failed may be invalid credentials provided!")
                        return
                    }
                    
                    // sometimes status code 400 returned, we've to check what kind of error this code is involved with
                    if (statusCode == 400 || statusCode == 404) || (statusCode >= 500 && statusCode <= 599) {
                        
                        sendError(error: "Oops! Your request returned a status code other than 2xx! A service downtime may possible - try later")
                        if self.debugMode {
                            print(NSString(data: data, encoding: String.Encoding.utf8.rawValue)!)
                        }
                        
                        return
                    }
                }
                
                do {
                    parsedResult = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments)
                } catch {
                    completionHandlerForRequest(nil, "Oops! Couldn't parse the API result data as JSON: '\(data)'")
                    if self.debugMode {
                        print(error)
                    }
                    
                    return
                }
                
                completionHandlerForRequest(parsedResult as AnyObject?, nil)
                
            }
            
            // Finaly start the corresponding request
            task.resume()
        }
    }
}
