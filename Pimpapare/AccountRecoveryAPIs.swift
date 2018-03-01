//
//  AccountRecoveryAPIs.swift
//  CoreAPIs
//
//  Created by Thiti Sununta on 9/20/2559 BE.
//  Copyright © 2559 CLBS Ltd. All rights reserved.
//

import Foundation

open class AccountRecoveryAPIs: NSObject,URLSessionDelegate {
    
    open static let sharedInstance = AccountRecoveryAPIs()
    
    fileprivate lazy var sharedSession: URLSession = {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()
    
    lazy var serviceList: [[String: String]] = {
        let filePath = APIsConfig.productionMode ? APIsConfig.kAccountRecoveryServiceFileName : APIsConfig.kTestAccountRecoveryServiceFileName
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
    
    open func recoveryPasswordViaEmailWithUsername(_ username:String,completion:((_ success:Bool,_ error:NSError?) -> Void)?)
    {
        
        let serviceURL = servicePath(atIndex:0)
        var requestString = String(format: "%@%@",
                                   serviceURL,
                                   username)
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        requestString = requestString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let request = URLRequest(url: URL(string: requestString as String)!)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }

            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, error as NSError?)
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
                            if responseString == "ERROR" {
                                closure(false, nil)
                            }else{
                                closure(true, nil)
                            }
                        }
                    }
                    
                }else{
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(false, error as NSError?)
                        }
                    }
                }
            }
        })
        task.resume()
    }
    
    open func recoveryPasswordViaEmailWithUsernameWeb(_ username:String, appTargetURL:String,completion:((_ success:Bool,_ error:NSError?) -> Void)?)
    {
        
        let serviceURL = servicePath(atIndex:5)
        var requestString = String(format: "%@%@&targetURL=%@",
                                   serviceURL,
                                   username,appTargetURL)
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        requestString = requestString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let request = URLRequest(url: URL(string: requestString as String)!)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, error as NSError?)
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
                            if responseString == "ERROR" {
                                closure(false, nil)
                            }else{
                                closure(true, nil)
                            }
                        }
                    }
                    
                }else{
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(false, error as NSError?)
                        }
                    }
                }
            }
        })
        task.resume()
    }

    open func recoveryPasswordViaSmsWithAccountUsername(_ username:String,completion:((_ success:Bool,_ error:NSError?) -> Void)?)
    {
        let serviceURL = servicePath(atIndex:1)
        var requestString = String(format: "%@%@",
                                   serviceURL,
                                   username)
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        requestString = requestString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let request = URLRequest(url: URL(string: requestString as String)!)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, error as NSError?)
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
                            if responseString == "ERROR" {
                                closure(false, nil)
                            }else{
                                closure(true, nil)
                            }
                        }
                    }
                    
                }else{
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(false, error as NSError?)
                        }
                    }
                }
            }
        })
        task.resume()
    }
    
    open func recoveryUsernameViaEmail(_ email:String,completion:((_ success:Bool,_ error:NSError?) -> Void)?)
    {
        let serviceURL = servicePath(atIndex:2)
        var requestString = String(format: "%@%@",
                                   serviceURL,
                                   email)
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        requestString = requestString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let request = URLRequest(url: URL(string: requestString as String)!)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }

            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, error as NSError?)
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
                            if responseString == "ERROR" {
                                closure(false, nil)
                            }else{
                                closure(true, nil)
                            }
                        }
                    }
                    
                }else{
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(false, error as NSError?)
                        }
                    }
                }
            }
        })
        task.resume()
    }
    
    open func recoveryUsernameViaSMS(_ phoneNumber:String,completion:((_ success:Bool,_ error:NSError?) -> Void)?){
        
        let serviceURL = servicePath(atIndex:3)
        var requestString = String(format: "%@%@",
                                   serviceURL,
                                   phoneNumber)
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        requestString = requestString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let request = URLRequest(url: URL(string: requestString as String)!)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }

            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, error as NSError?)
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
                            if responseString == "ERROR" {
                                closure(false, nil)
                            }else{
                                closure(true, nil)
                            }
                        }
                    }
                    
                }else{
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(false, error as NSError?)
                        }
                    }
                }
            }
        })
        task.resume()
    }
    
    open func changePassword(_ password:String,recoveryCode:String,completion:((_ success:Bool,_ result:AnyObject?,_ error:NSError?) -> Void)?)
    {
        let serviceURL = servicePath(atIndex: 4)
        let requestString =  String(format: "%@", serviceURL)
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var params = [String:AnyObject]()
        params["code"] = recoveryCode as AnyObject?
        params["password"] = password as AnyObject?
        
        var data:Data!
        do {
            data = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        } catch {
            print(error)
        }
        let jsonString = String(data: data!, encoding: String.Encoding.utf8)
        data = jsonString?.data(using: String.Encoding.utf8)
        
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async(execute: {
                        closure(false,nil, error as NSError?)
                    })
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
                            closure(true, responseString as AnyObject?, nil)
                        }
                    }
                    
                }else{
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(false,nil, error as NSError?)
                        }
                    }
                }
            }
        })
        task.resume()
    }
}
