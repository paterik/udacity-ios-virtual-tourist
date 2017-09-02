//
//  RequestClient.swift
//  VirtualTourist
//
//  Created by Patrick Paechnatz on 02.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation

extension RequestClient {
    
    /*
     * base "GET" method for our request base client
     */
    func get (
       _ url: String,
         headers: [String:String],
         parameters: [String : AnyObject]?,
         bodyParameters: [String : AnyObject]?,
         completionHandlerForGet: @escaping (_ data: AnyObject?, _ errorString: String?)
        
         -> Void) {
        
        requestExecute(
            requestPrepare(url, "GET", headers, parameters, bodyParameters),
            completionHandlerForRequest: completionHandlerForGet
        )
    }
    
    /*
     * base "DELETE" method for our request base client
     */
    func delete (
       _ url: String,
         headers: [String:String],
         completionHandlerForDelete: @escaping (_ data: AnyObject?, _ errorString: String?)
        
         -> Void) {
        
        requestExecute(
            requestPrepare(url, "DELETE", headers, [:], [:]),
            completionHandlerForRequest: completionHandlerForDelete
        )
    }
    
    /*
     * base "POST" method for our request base client
     */
    func post (
       _ url: String,
         headers: [String:String],
         parameters: [String : AnyObject]?,
         bodyParameters: [String : AnyObject]?,
         completionHandlerForPost: @escaping (_ data: AnyObject?, _ errorString: String?)
        
         -> Void) {
        
        requestExecute(
            requestPrepare(url, "POST", headers, parameters, bodyParameters),
            completionHandlerForRequest: completionHandlerForPost
        )
    }
    
    /*
     * base "PUT" method for our request base client
     */
    func put (
       _ url: String,
         headers: [String:String],
         parameters: [String : AnyObject]?,
         bodyParameters: [String : AnyObject]?,
         completionHandlerForPut: @escaping (_ data: AnyObject?, _ errorString: String?)
        
         -> Void) {
        
        requestExecute(
            requestPrepare(url, "PUT", headers, parameters, bodyParameters),
            completionHandlerForRequest: completionHandlerForPut
        )
    }
    
    /*
     * base "PATCH" method for our request base client
     */
    func patch (
       _ url: String,
         headers: [String:String],
         parameters: [String : AnyObject]?,
         bodyParameters: [String : AnyObject]?,
         completionHandlerForPatch: @escaping (_ data: AnyObject?, _ errorString: String?)
        
         -> Void) {
        
        requestExecute(
            requestPrepare(url, "PATCH", headers, parameters, bodyParameters),
            completionHandlerForRequest: completionHandlerForPatch
        )
    }
}
