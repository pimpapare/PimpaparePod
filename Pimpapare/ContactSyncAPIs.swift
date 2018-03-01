//
//  ContactSyncAPIs.swift
//  CoreAPIs
//
//  Created by Thanakrit Weekhamchai on 7/19/16.
//  Copyright © 2016 CLBS Ltd. All rights reserved.
//

import UIKit

public typealias ContactSyncUpdateCompletion = (_ success: Bool, _ error: Error?) -> Void
public typealias ContactSyncFetchVIPCompletion = (_ success: Bool, _ contacts: [String: AnyObject]?, _ error: Error?) -> Void
public typealias ContactSyncVIPUpdateCompletion = (_ success: Bool,_ error: Error?) -> Void

open class ContactSyncAPIs: NSObject, URLSessionDelegate {
    
    open static let sharedInstance = ContactSyncAPIs()
    
    fileprivate lazy var sharedSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 1
        config.timeoutIntervalForResource = (60 * 30) // 30  minutes
        config.timeoutIntervalForRequest = (60 * 10) // 10 minutes
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()
    
    fileprivate lazy var serviceList: [[String: String]] = {
        let filePath = APIsConfig.productionMode ? APIsConfig.kContactSyncServiceFileName : APIsConfig.kTestContactSyncServiceFileName
        let servicePath = Bundle.main.path(forResource: filePath, ofType:"plist")!
        return NSArray(contentsOfFile: servicePath) as! [[String: String]]
    }()
    
    fileprivate func servicePath(atIndex index: Int) -> String {
        assert(self.serviceList.count > index, "Invalid service path index")
        return serviceList[index]["ServicePath"]!
    }
    
    fileprivate func prettyPrint(with json: [String:Any]) -> String{
        let data = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        return string! as String
    }

    /* param users must already filtered before hand. Only send need sync contacts to this function
     */
    //    open func startSyncingContacts(withContactData data: [SyncContactData]) {
    //
    //        for datum in data {
    //            updateContacts(datum.contactsInfo, forUser: datum.user, completion: nil)
    //        }
    //    }
    
    open func updateContacts(_ contacts: [String: AnyObject], forUser user: UserCredentials, completion: ContactSyncUpdateCompletion?) {
        
        // notify of start
        let serviceURL = servicePath(atIndex: 4)
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let contactsData = try! JSONSerialization.data(withJSONObject: contacts, options: .prettyPrinted)
        
        let jsonString = prettyPrint(with: contacts)
        print("JSON : \(jsonString)")
        
        if  APIsConfig.debugURL { print("URL : '\(requestString)'") }
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        request.setValue(user.ticket!, forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = contactsData
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if let closure = completion {
                    if APIsConfig.printResponse { print("Error : '\(String(describing: error?.localizedDescription))'") }
                    DispatchQueue.main.async {
                        closure(false, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, nil)
                        }
                    }
                    
                } else if statusCode == 401 {
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) -> Void in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, error?.localized)
                                }
                            }
                        } else {
                            self.updateContacts(contacts, forUser: userCredentials!, completion: completion)
                        }
                    })
                    
                } else {
                    
                    if APIsConfig.printResponse { print("Error : '\(String(describing: error?.localizedDescription))'") }
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
    
    open func disableContactSync(for user: UserCredentials, onDevice deviceID: String, accountType type: String, completion: ContactSyncUpdateCompletion?) {
        
        let serviceURL = servicePath(atIndex: 3)
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        var request = URLRequest(url: URL(string: requestString)!.appendingPathComponent(type).appendingPathComponent(deviceID))
        request.httpMethod = "DELETE"
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        
        if APIsConfig.debugURL { print("URL : '\(requestString)'") }
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                if APIsConfig.printResponse { print("Error : '\(String(describing: error?.localizedDescription))'") }
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = (httpResponse?.statusCode)!
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, nil)
                        }
                    }
                    
                } else if statusCode == 401 {
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) -> Void in
                        if (error != nil) {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, error?.localized)
                                }
                            }
                        } else {
                            self.disableContactSync(for: userCredentials!, onDevice: deviceID, accountType: type, completion: completion)
                        }
                    })
                    
                } else {
                    
                    if APIsConfig.printResponse { print("Error : '\(String(describing: error?.localizedDescription))'") }
                    
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
    
    
    // MARK: - VIP
    
    open func fetchAllVIPContacts(for user: UserCredentials, on page: Int, completion: ContactSyncFetchVIPCompletion?) {
        
        let serviceURL = servicePath(atIndex: 5).appending("/\(page)/\(50)")
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.httpMethod = "GET"
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if APIsConfig.printResponse {
                    print("Error : '\(String(describing: error?.localizedDescription))'")
                    
                }
                
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
                            let jsonString = self.prettyPrint(with: result!)
                            print("JSON : \(jsonString)")
                        }

                        
                    } catch let error {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let response = result, let closure = completion {
                        
                        DispatchQueue.main.async {
                            closure(true, response, nil)
                        }
                    }else{
                        // 204 success with no response
                        if let closure = completion {
                            let response: [String: AnyObject] = [:]
                            DispatchQueue.main.async {
                                closure(true, response, nil)
                            }
                        }
                    }
                    
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
    
    open func updateVIPContacts(_ vipContacts: [String: AnyObject], for user: UserCredentials, completion: ContactSyncVIPUpdateCompletion?) {
        
        let serviceURL = servicePath(atIndex: 6)
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        let contactsData = try! JSONSerialization.data(withJSONObject: vipContacts, options: .prettyPrinted)
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.httpMethod = "POST"
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        request.httpBody = contactsData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
//        let jsonString = prettyPrint(with: vipContacts)
//        print("JSON : \(jsonString)")
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async(execute: {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = (httpResponse?.statusCode)!
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, nil)
                        }
                    }
                    
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


