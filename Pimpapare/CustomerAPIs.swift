//
//  CustomerAPIs.swift
//  CoreAPIs
//
//  Created by Thanakrit Weekhamchai on 7/18/16.
//  Copyright © 2016 CLBS Ltd. All rights reserved.
//

import UIKit

public typealias CustomerFetchGreetingTextCompletion = (_ success: Bool, _ greetingText: [String: AnyObject]?, _ error: Error?) -> ()
public typealias CustomerFetchRAVCompletion = (_ success: Bool, _ rav: String?, _ error: Error?) -> ()
public typealias CustomerFetchInfoCompletion = (_ success: Bool, _ customerInfo: [String: AnyObject]?, _ error: Error?) -> ()
public typealias CustomerUpdateGreetingTextCompletion = (_ success: Bool, _ error: Error?) -> ()

open class CustomerAPIs: NSObject, URLSessionDelegate {
    
    open static let sharedInstance = CustomerAPIs()
    
    fileprivate lazy var sharedSession: URLSession = {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()
    
    fileprivate lazy var serviceList: [[String: String]] = {
        let filePath = APIsConfig.productionMode ? APIsConfig.kCustomerServiceFileName : APIsConfig.kTestCustomerServiceFileName
        let servicePath = Bundle.main.path(forResource: filePath, ofType:"plist")!
        return NSArray(contentsOfFile: servicePath) as! [[String: String]]
    }()
    
    fileprivate func servicePath(atIndex index: Int) -> String {
        assert(self.serviceList.count > index, "Invalid service path index")
        return serviceList[index]["ServicePath"]!
    }
    
    // MARK: - Fetch
    
    open func fetchCurrentGreetingText(forUser user: UserCredentials, completion: CustomerFetchGreetingTextCompletion?) {
        
        let serviceURL = servicePath(atIndex: 1)
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.httpMethod = "GET"
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = (httpResponse?.statusCode)!
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let result: [String: AnyObject]!
                    do {
                        result = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: AnyObject]
                        if APIsConfig.printResponse {
                            print("JSON Response : '\(result)'")
                        }
                    } catch let error {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, result, nil)
                        }
                    }
                    
                } else if statusCode == 401 {
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        }else{
                            self.fetchCurrentGreetingText(forUser: userCredentials!, completion: completion)
                        }
                    })
                    
                }else {
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(false, nil, error?.localized)
                        }
                    }
                }
            }
        }) 
        task.resume()
    }
    
    
    open func fetchRAV(forUser user: UserCredentials, completion: CustomerFetchRAVCompletion?) {
        
        let serviceURL = servicePath(atIndex: 2)
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.httpMethod = "GET"
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = (httpResponse?.statusCode)!
                
                if APIsConfig.printResponse {
                    print("StatusCode : '\(statusCode)'")
                }
                
                if APIsConfig.debugHTTPResponse {
                    print("Response : '\(String(describing: response))'")
                }
                
                if statusCode / 100 == 2 {
                    
                    let result = String(data: data!, encoding: String.Encoding.utf8)
                    
                    if APIsConfig.printResponse {
                        print("JSON Response : '\(String(describing: result))'")
                    }
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, result, nil)
                        }
                    }
                    
                }else if statusCode == 401 {
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        }else{
                            self.fetchRAV(forUser: userCredentials!, completion: completion)
                        }
                    })
                    
                } else {
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(false, nil, error?.localized)
                        }
                    }
                }
            }
        })
        
        task.resume()
    }
    
    open func fetchCustomerInfo(forUser user: UserCredentials, completion: CustomerFetchInfoCompletion?) {
        
        let serviceURL = servicePath(atIndex: 3)
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if APIsConfig.debugURL { print("URL : '\(requestString)'") }
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.httpMethod = "GET"
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async(execute: {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = (httpResponse?.statusCode)!
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let result: [String: AnyObject]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: AnyObject]
                        if APIsConfig.printResponse {
                            print("JSON Response : '\(String(describing: result))'")
                        }
                    } catch let error {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let response = result, let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, response, nil)
                        }
                    }
                    
                }else if statusCode == 401 {
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        }else{
                            self.fetchCustomerInfo(forUser: userCredentials!, completion: completion)
                        }
                    })
                    
                } else {
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(false, nil, error?.localized)
                        }
                    }
                }
            }
        })
        
        task.resume()
    }
    
    // MARK: - Update
    
    open func updateGreeting(forUser user:UserCredentials, withInfo greetingInfo: [String: String], completion: CustomerUpdateGreetingTextCompletion?) {
        
        let serviceURL = servicePath(atIndex: 1)
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        let greetingData = try! JSONSerialization.data(withJSONObject: greetingInfo, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        // try to use greetingData directly
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        request.httpBody = greetingData
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = (httpResponse?.statusCode)!
                
                if APIsConfig.printResponse {
                    print("StatusCode : '\(statusCode)'")
                }
                
                if APIsConfig.debugHTTPResponse {
                    print("Response : '\(String(describing: response))'")
                }
                
                if statusCode / 100 == 2 {
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, nil)
                        }
                    }
                    
                } else if statusCode == 401 {
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, error?.localized)
                                }
                            }
                            
                        }else{
                            self.updateGreeting(forUser: userCredentials!, withInfo: greetingInfo, completion: completion)
                        }
                    })
                    
                } else {
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(false, error?.localized)
                        }
                    }
                }
            }
        }) 
        task.resume()
    }
}
