//
//  PhoneServiceAPIs.swift
//  CoreAPIs
//
//  Created by Thanakrit Weekhamchai on 10/31/16.
//  Copyright © 2016 CLBS Ltd. All rights reserved.
//

import UIKit

public typealias PhoneServiceFetchInfoCompletion = (_ success: Bool, _ result: [String: AnyObject]?, _ error: Error?) -> ()
public typealias PhoneServiceFetchReachabilitiesCompletion = (_ success: Bool, _ reachabilityInfo: [[String: AnyObject]]?, _ error: Error?) -> ()
public typealias PhoneServiceFetchForwardingsCompletion = (_ success: Bool, _ forwardingInfo: [[String: AnyObject]]?, _ error: Error?) -> ()
public typealias PhoneServiceAssignForwardingCompletion = (_ success: Bool, _ count: String?, _ error: Error?) -> ()

public struct ForwardingNumbersUpdateOptions: OptionSet {

    public let rawValue: UInt

    public init(rawValue value: UInt) {
        self.rawValue = value
    }

    public static let all = ForwardingNumbersUpdateOptions(rawValue: 0)
    public static let reorder = ForwardingNumbersUpdateOptions(rawValue: 1 << 0)
    public static let title = ForwardingNumbersUpdateOptions(rawValue: 1 << 1)
    public static let number = ForwardingNumbersUpdateOptions(rawValue: 1 << 2)
    public static let privacy = ForwardingNumbersUpdateOptions(rawValue: 1 << 3)
    public static let none = ForwardingNumbersUpdateOptions(rawValue: 1 << 4)
}

public enum ReachabilityFetchMode: Int {
    case assignedToThisSecretaryNumber = 0, notAssignedToThisSecretaryNumber = 1
}

public enum ForwardingNumberPriorityUpdateMode {
    case raise, lower
}


public class PhoneServiceAPIs: NSObject {
    
    open static let shared = PhoneServiceAPIs()
    
    fileprivate var priorityUpdateSuccessfullyCount: Int = 0
    fileprivate var priorityRequest:[URLRequest] = []

    fileprivate lazy var sharedSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 1
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()
    
    fileprivate lazy var priorityUpdateSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 1
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()
    
    fileprivate lazy var serviceList: [[String: String]] = {
        let filePath = APIsConfig.productionMode ? APIsConfig.kPhoneServiceFileName : APIsConfig.kTestPhoneServiceFileName
        let servicePath = Bundle.main.path(forResource: filePath, ofType:"plist")!
        return NSArray(contentsOfFile: servicePath) as! [[String: String]]
    }()
    
    fileprivate func servicePath(atIndex index: Int) -> String {
        assert(self.serviceList.count > index, "Invalid service path index")
        return serviceList[index]["ServicePath"]!
    }
}

extension PhoneServiceAPIs: URLSessionDelegate {
    
    /*
     needs to check for customer ID before calling this method
     if user object doesn't have an customer ID 
     feth using method in CustomerAPI
     */
    public func fetchPhoneServiceInfo(for user: UserCredentials, completion: PhoneServiceFetchInfoCompletion?) {
        
        let serviceURL = servicePath(atIndex: 0)
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.httpMethod = "GET"
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async{
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async{
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = (httpResponse?.statusCode) ?? 0
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let result: [[String: AnyObject]]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments) as? [[String: AnyObject]]
                        if APIsConfig.printResponse {
                            print("JSON Response : '\(String(describing: result))'")
                        }
                    } catch let error {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let response = result?.first, let closure = completion {
                        DispatchQueue.main.async{
                            closure(true, response, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async{
                                    closure(false, nil, error?.localized)
                                }
                            }
                        }else{
                            self.fetchPhoneServiceInfo(for: userCredentials!, completion: completion)
                        }
                    })
                    
                } else {
                    if let closure = completion {
                        DispatchQueue.main.async{
                            closure(false, nil, error?.localized)
                        }
                    }
                }
            }
        })
        
        task.resume()
    }
    
    
    
    // MARK: - Reachability
    
    /*
     needs to check for customer ID and phone service ID before calling this method
     if user object doesn't have an customer ID
     feth using method in CustomerAPI
     */
    public func fetchAllReachabilities(for user: UserCredentials, with phoneServiceID: String, completion: PhoneServiceFetchReachabilitiesCompletion?) {
        
        let serviceURL = servicePath(atIndex: 1).replacingOccurrences(of: "{phoneServiceId}", with: phoneServiceID)
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.httpMethod = "GET"
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async{
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async{
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = (httpResponse?.statusCode) ?? 404
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let results: [[String: AnyObject]]?
                    do {
                        results = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [[String: AnyObject]]
                        if APIsConfig.printResponse {
                            print("JSON Response : '\(results!)'")
                        }
                    } catch let error {
                        results = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let response = results, let closure = completion {
                        DispatchQueue.main.async{
                            closure(true, response, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async{
                                    closure(false, nil, error?.localized)
                                }
                            }
                        }else{
                            self.fetchAllReachabilities(for: userCredentials!, with: phoneServiceID, completion: completion)
                        }
                    })
                    
                } else {
                    if let closure = completion {
                        DispatchQueue.main.async{
                            closure(false, nil, error?.localized)
                        }
                    }
                }
            }
        })
        task.resume()
    }
    
    public func createOrUpdateReachability(_ reachabilityInfo: [String: AnyObject],_ originalName: String? ,for user: UserCredentials, with phoneServiceID: String, options flags: Bool, completion: PhoneServiceFetchInfoCompletion?) {
        //    public func createOrUpdateReachability(_ reachabilityInfo: [String: AnyObject], for user: UserCredentials, with phoneServiceID: String, options flags: ForwardingNumbersUpdateOptions, completion: PhoneServiceFetchInfoCompletion?) {
        
        let serviceURL = servicePath(atIndex: 1).replacingOccurrences(of: "{phoneServiceId}", with: phoneServiceID)
        var requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        var request = URLRequest(url: URL(string: requestString)!)
        
        if flags{
            //        if flags.contains(.all) {
            request.httpMethod = "POST"
        } else {
            request.httpMethod = "PUT"
            var reachabilityName = ""
            if let name = originalName{
                reachabilityName = name
            }else{
                reachabilityName = reachabilityInfo["name"] as! String
            }
            
            let originalNameData = reachabilityName.data(using: String.Encoding.utf8)
            let encodedName = originalNameData!.base64EncodedString()
            requestString = requestString.stringByAppendingPathComponent(encodedName)
            request.url = URL(string: requestString)!
        }
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        
        do {
            let contactData = try JSONSerialization.data(withJSONObject: reachabilityInfo, options: JSONSerialization.WritingOptions.prettyPrinted)
            
            request.httpBody = contactData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
        } catch let error {
            print(error.localizedDescription)
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async{
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async{
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = (httpResponse?.statusCode)!
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 || statusCode == 204{ // 204 success but no content
                    
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
                    
                    //                if let ret = result,
                    if let closure = completion {
                        DispatchQueue.main.async{
                            closure(true, result, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async{
                                    closure(false, nil, error?.localized)
                                }
                            }
                        }else{
                            self.createOrUpdateReachability(reachabilityInfo, originalName, for: userCredentials!, with: phoneServiceID, options: flags, completion: completion)
                        }
                    })
                    
                } else {
                    if let closure = completion {
                        DispatchQueue.main.async{
                            closure(false, nil, error?.localized)
                        }
                    }
                }
            }
        })
        task.resume()
        
    }
    
    public func deleteReachability(_ reachabilityInfo: [String: AnyObject], for user: UserCredentials, with phoneServiceID: String, completion: PhoneServiceFetchInfoCompletion?) {
        
        let originalNameData = (reachabilityInfo["name"] as! String).data(using: String.Encoding.utf8)
        let encodedName = originalNameData?.base64EncodedString()
        
        var serviceURL = servicePath(atIndex: 2).replacingOccurrences(of: "{phoneServiceId}", with: phoneServiceID)
        serviceURL = serviceURL.replacingOccurrences(of: "{name}", with: encodedName!)
        
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.httpMethod = "DELETE"
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async{
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async{
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = (httpResponse?.statusCode)!
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    if let closure = completion {
                        DispatchQueue.main.async{
                            closure(true, nil, nil)
                        }
                    }
                    
                } else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async{
                                    closure(false, nil, error?.localized)
                                }
                            }
                        }else{
                            self.deleteReachability(reachabilityInfo, for: userCredentials!, with: phoneServiceID, completion: completion)
                        }
                    })
                    
                } else {
                    if let closure = completion {
                        DispatchQueue.main.async{
                            closure(false, nil, error?.localized)
                        }
                    }
                }
            }
        })
        task.resume()
        
    }
    
    // MARK: - Forwarding
    
    public func fetchForwardings(with secretaryInfo: [String: String], using mode: ReachabilityFetchMode, for user: UserCredentials, completion: PhoneServiceFetchForwardingsCompletion?) {
        
        var serviceURL = servicePath(atIndex: 3)
        serviceURL = serviceURL.replacingOccurrences(of: "{vorwahl}", with: secretaryInfo["vorwahl"]!)
        serviceURL = serviceURL.replacingOccurrences(of: "{prefix}", with: secretaryInfo["prefix"]!)
        serviceURL = serviceURL.replacingOccurrences(of: "{suffix}", with: secretaryInfo["suffix"]!)
        
        if mode == .assignedToThisSecretaryNumber {
            serviceURL.append("?used=true")
        } else {
            serviceURL.append("?used=false")
        }
        
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.httpMethod = "GET"
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async{
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async{
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = (httpResponse?.statusCode)!
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let results: [[String: AnyObject]]?
                    do {
                        results = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [[String: AnyObject]]
                        if APIsConfig.printResponse {
                            print("JSON Response : '\(String(describing: results))'")
                        }
                    } catch let error {
                        results = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let response = results, let closure = completion {
                        DispatchQueue.main.async{
                            closure(true, response, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async{
                                    closure(false, nil, error?.localized)
                                }
                            }
                        }else{
                            self.fetchForwardings(with: secretaryInfo, using: mode, for: userCredentials!, completion: completion)
                        }
                    })
                    
                }  else {
                    if let closure = completion {
                        DispatchQueue.main.async{
                            closure(false, nil, error?.localized)
                        }
                    }
                }
            }
            
        })
        
        task.resume()
    }
    
    public func assignForwarding(with reachabilityInfo: [String: AnyObject], to secretaryInfo: [String: String], for user: UserCredentials, completion: PhoneServiceAssignForwardingCompletion?) {
        
        var serviceURL = servicePath(atIndex: 3)
        serviceURL = serviceURL.replacingOccurrences(of: "{vorwahl}", with: secretaryInfo["vorwahl"]!)
        serviceURL = serviceURL.replacingOccurrences(of: "{prefix}", with: secretaryInfo["prefix"]!)
        serviceURL = serviceURL.replacingOccurrences(of: "{suffix}", with: secretaryInfo["suffix"]!)
        
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.httpMethod = "POST"
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        do {
            let contactData = try JSONSerialization.data(withJSONObject: reachabilityInfo, options: JSONSerialization.WritingOptions.prettyPrinted)
            
            request.httpBody = contactData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
        } catch let error {
            print(error.localizedDescription)
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async{
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async{
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = (httpResponse?.statusCode)!
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let count = String(data: data!, encoding: String.Encoding.utf8)
                    
                    print("assigned forwarding has ID: \(String(describing: count))")
                    
                    if let response = count, let closure = completion {
                        DispatchQueue.main.async{
                            closure(true, response, nil)
                        }
                        return
                    }
                } else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async{
                                    closure(false, nil, error?.localized)
                                }
                            }
                        }else{
                            self.assignForwarding(with: reachabilityInfo, to: secretaryInfo, for: userCredentials!, completion: completion)
                        }
                    })
                    
                } else{
                    
                    if let closure = completion {
                        DispatchQueue.main.async{
                            closure(false, nil, error?.localized)
                        }
                    }
                }
            }
        })
        
        task.resume()
        
    }
    
    public func unassignForwarding(_ forwardingInfo: [String: AnyObject]?, from secretaryInfo: [String: String], for user: UserCredentials, completion: PhoneServiceFetchInfoCompletion?) {
        
        var serviceURL = servicePath(atIndex: 3)
        serviceURL = serviceURL.replacingOccurrences(of: "{vorwahl}", with: secretaryInfo["vorwahl"]!)
        serviceURL = serviceURL.replacingOccurrences(of: "{prefix}", with: secretaryInfo["prefix"]!)
        serviceURL = serviceURL.replacingOccurrences(of: "{suffix}", with: secretaryInfo["suffix"]!)
        
        // if there is no forwarding, it will delete all
        if let forwarding = forwardingInfo, let count = forwarding["count"] as? String {
            serviceURL = serviceURL.stringByAppendingPathComponent(count)
        }
        
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.httpMethod = "DELETE"
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async{
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async{
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = (httpResponse?.statusCode)!
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    if let closure = completion {
                        DispatchQueue.main.async{
                            closure(true, nil, nil)
                        }
                        return
                    }
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async{
                                    closure(false, nil, error?.localized)
                                }
                            }
                        }else{
                            self.unassignForwarding(forwardingInfo, from: secretaryInfo, for: userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
                    if let closure = completion {
                        DispatchQueue.main.async{
                            closure(false, nil, error?.localized)
                        }
                    }
                }
            }
        })
        
        task.resume()
        
    }
    
    public func unassignAllForwardings(from secretaryInfo: [String: String], for user: UserCredentials, completion: PhoneServiceFetchInfoCompletion?) {
        
        unassignForwarding(nil, from: secretaryInfo, for: user, completion: completion)
    }
    
    public func updateForwardingAvailableTime(_ forwardingInfo: [String: AnyObject], from secretaryInfo: [String: String], for user: UserCredentials, completion: PhoneServiceFetchInfoCompletion?) {
        
        var serviceURL = servicePath(atIndex: 2)
        serviceURL = serviceURL.replacingOccurrences(of: "{vorwahl}", with: secretaryInfo["vorwahl"]!)
        serviceURL = serviceURL.replacingOccurrences(of: "{prefix}", with: secretaryInfo["prefix"]!)
        serviceURL = serviceURL.replacingOccurrences(of: "{suffix}", with: secretaryInfo["suffix"]!)
        
        // if there is no forwarding, it will delete all
        if let count = forwardingInfo["count"] as? String {
            serviceURL = serviceURL.stringByAppendingPathComponent(count)
        }
        
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.httpMethod = "PUT"
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        
        do {
            let contactData = try JSONSerialization.data(withJSONObject: forwardingInfo, options: JSONSerialization.WritingOptions.prettyPrinted)
            
            request.httpBody = contactData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
        } catch let error {
            print(error.localizedDescription)
        }
        
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async{
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async{
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
                        DispatchQueue.main.async{
                            closure(true, response, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async{
                                    closure(false, nil, error?.localized)
                                }
                            }
                        }else{
                            self.updateForwardingAvailableTime(forwardingInfo, from: secretaryInfo, for: userCredentials!, completion: completion)
                        }
                    })
                    
                } else {
                    if let closure = completion {
                        DispatchQueue.main.async{
                            closure(false, nil, error?.localized)
                        }
                    }
                }
            }
        })
        task.resume()
    }
    
    // MARK: - Priority
    
    public func updatePriority(for forwardingInfo: [String: AnyObject], from secretaryInfo: [String: String], using mode: ForwardingNumberPriorityUpdateMode, updateSteps steps: Int, with user: UserCredentials, completion: PhoneServiceFetchInfoCompletion?) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        self.priorityRequest.removeAll()
        
        for _ in 0..<steps {
            
            var serviceURL = servicePath(atIndex: 4)
            serviceURL = serviceURL.replacingOccurrences(of: "{vorwahl}", with: secretaryInfo["vorwahl"]!)
            serviceURL = serviceURL.replacingOccurrences(of: "{prefix}", with: secretaryInfo["prefix"]!)
            serviceURL = serviceURL.replacingOccurrences(of: "{suffix}", with: secretaryInfo["suffix"]!)
            serviceURL = serviceURL.replacingOccurrences(of: "{count}", with: forwardingInfo["count"] as! String)
            
            if mode == .raise {
                serviceURL = serviceURL.replacingOccurrences(of: "{direction}", with: "up")
            } else if mode == .lower {
                serviceURL = serviceURL.replacingOccurrences(of: "{direction}", with: "down")
            }
            
            let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            
            var request = URLRequest(url: URL(string: requestString)!)
            request.httpMethod = "PUT"
            request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
            
            self.priorityRequest.append(request)
        }
        
        doUpdatePriority(completion: completion)
    }
    
    func doUpdatePriority(completion: PhoneServiceFetchInfoCompletion?) {
        
        if self.priorityRequest.count > 0 {
            
            if let request = self.priorityRequest.first {
                
                let task = URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
                    
                    if error != nil {
                        
                        if let closure = completion {
                            DispatchQueue.main.async {
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                closure(false, nil, error?.localized)
                            }
                        }
                        
                    }else{
                        
                        let httpResponse = response as? HTTPURLResponse
                        let statusCode = (httpResponse?.statusCode) ?? 0
                        
                        if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                        if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                        
                        if statusCode / 100 == 2 {
                            
                            print("UpdatePriority Successfully at : \(self.priorityRequest.count)")
                            self.priorityRequest.remove(at: 0)
                            self.doUpdatePriority(completion: completion)
                            
                        } else {
                            
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                    closure(false, nil, error?.localized)
                                }
                            }
                        }
                    }
                })
                task.resume()
            }
            
        }else{
            
            if let closure = completion {
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    closure(true, nil, nil)
                }
            }
        }
    }
}
