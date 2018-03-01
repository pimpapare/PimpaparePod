//
//  NotificationAPIs.swift
//  CoreAPIs
//
//  Created by Thiti Sununta on 9/9/2559 BE.
//  Copyright © 2559 CLBS Ltd. All rights reserved.
//

import Foundation

open class NotificationAPIs: NSObject,URLSessionDelegate {
    
    open static let sharedInstance = NotificationAPIs()

    fileprivate lazy var sharedSession: URLSession = {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()
    
    lazy var serviceList: [[String: String]] = {
        let filePath = APIsConfig.productionMode ? APIsConfig.kNotificationServiceFileName : APIsConfig.kTestNotificationServiceFileName
        let servicePath = Bundle.main.path(forResource: filePath, ofType:"plist")!
        return NSArray(contentsOfFile: servicePath) as! [[String: String]]
    }()
    
    func servicePath(atIndex index: Int) -> String {
        assert(self.serviceList.count > index, "Invalid service path index")
        return self.serviceList[index]["ServicePath"]!
    }
    public override init() {
        super.init()
    }
    
    open func registerRemoteNotification(_ pushService:PushService,
                                           userCredentials:UserCredentials,
                                           completion:((_ success:Bool?,_ error:NSError?) -> Void)?)
    {
        
        let serviceURL = servicePath(atIndex:0)
        var requestString = String(format: "%@%@?silent=%@&location=%@&eventReminder=%@&faxAndVoice=%@",
                                   serviceURL,
                                   pushService.deviceToken,
                                   pushService.isReceiveSilentBadge! ? "true":"false",
                                   pushService.isReceiveLocationAwarenss! ? "true":"false",
                                   pushService.isReceiveEventReminder! ? "true":"false",
                                   pushService.isSupportMessageEntry! ? "true":"false")
        
        requestString = requestString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        if let ticket = userCredentials.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        request.httpMethod = "PUT"
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
            
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
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let responseString = String(data: data!, encoding: String.Encoding.utf8)

                    if APIsConfig.printResponse { print("Response : '\(String(describing: responseString))'") }
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(userCredentials, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, error?.localized)
                                }
                            }
                            
                        }else{
                            self.registerRemoteNotification(pushService, userCredentials: userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
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
    
    
    
    open func unregisterRemoteNotification(_ pushService:PushService,
                                           userCredentials:UserCredentials,
                                           completion:((_ success:Bool?,_ error:NSError?) -> Void)?)
    {
        
        let serviceURL = servicePath(atIndex:1)
        var requestString = String(format: "%@%@",
                                   serviceURL,
                                   pushService.deviceToken)
        
        requestString = requestString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        if let ticket = userCredentials.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        request.httpMethod = "DELETE"
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
            
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
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let responseString = String(data: data!, encoding: String.Encoding.utf8)
                    
                    if APIsConfig.printResponse { print("Response : '\(String(describing: responseString))'") }
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(userCredentials, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, error?.localized)
                                }
                            }
                        }else{
                            self.unregisterRemoteNotification(pushService, userCredentials: userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
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
