//
//  AppUtilitiyAPIs.swift
//  CoreAPIs
//
//  Created by Thanakrit Weekhamchai on 7/15/16.
//  Copyright © 2016 CLBS Ltd. All rights reserved.
//

import UIKit

public enum FeedbackType: Int {
    case serviceRequest = 0, productRequest = 1, improvement = 2, bugReport = 3
}

public typealias FeedbackClosure = (_ success: Bool, _ error: NSError?) -> ()

open class AppFeedbackAPIs: NSObject, URLSessionDelegate {

    open static let sharedInstance = AppFeedbackAPIs()
    
    fileprivate lazy var sharedSession: URLSession = {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()

    fileprivate lazy var serviceList: [[String: String]] = {
        let filePath = APIsConfig.productionMode ? APIsConfig.kFeedbackServiceFileName : APIsConfig.kTestFeedbackServiceFileName
        let servicePath = Bundle.main.path(forResource: filePath, ofType:"plist")!
        return NSArray(contentsOfFile: servicePath) as! [[String: String]]
    }()
    
    fileprivate func servicePath(atIndex index: Int) -> String {
        assert(self.serviceList.count > index, "Invalid service path index")
        return serviceList[index]["ServicePath"]!
    }
    
    // MARK: - Send Feedback
    
    open func sendFeedback(type feedbackType: FeedbackType, withMessage message: String?, forUser user: UserCredentials, completion: FeedbackClosure?) {
        
        let serviceURL = servicePath(atIndex: feedbackType.rawValue)
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!

        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }

        var request = URLRequest(url: URL(string: requestString)!)
        request.setValue(user.ticket, forHTTPHeaderField: "Cookie")
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        if let mess = message {
            let paramData = mess.data(using: String.Encoding.utf8)
            request.httpBody = paramData
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in

            DispatchQueue.main.async(execute: {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async(execute: {
                        closure(false, error?.localized)
                    })
                }
                
            }else{
                
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = (httpResponse?.statusCode) ?? 403
                
                if APIsConfig.printResponse {
                    print("StatusCode : '\(statusCode)'")
                }
                
                if APIsConfig.debugHTTPResponse {
                    print("Response : '\(String(describing: response))'")
                }
                
                if statusCode / 100 == 2 {
                    
                    if let closure = completion {
                        DispatchQueue.main.async(execute: {
                            closure(true, nil)
                        })
                    }
                    
                } else if statusCode == 401 || statusCode == 403 {
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) in
                        
                        if (error != nil) {
                            if let closure = completion {
                                DispatchQueue.main.async(execute: {
                                    closure(false, error)
                                })
                            }
                        }else{
                            self.sendFeedback(type: feedbackType, withMessage: message, forUser: user, completion: completion)
                        }
                    })
                    
                } else {
                    if let closure = completion {
                        DispatchQueue.main.async(execute: {
                            closure(false, error?.localized)
                        })
                    }
                }
                
            }

        }) 
        task.resume()
    }
}
