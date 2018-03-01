//
//  UserAPIs.swift
//  CoreAPIs
//
//  Created by Thiti Sununta on 17/06/2015.
//  Copyright (c) 2015 CLBS Ltd. All rights reserved.
//

import Foundation

public let kUserCredentailsDidUpdateNotification = "UserCredentailsDidUpdateNotification"
public let kUserCredentailsDidFailNotification = "UserCredentailsDidFailNotification"

open class UserAPIs: NSObject {

    open static let sharedInstance = UserAPIs()
    
    lazy var serviceList: [[String: String]] = {
        let filePath = APIsConfig.productionMode ? APIsConfig.kUserServiceFileName : APIsConfig.kTestUserServiceFileName
        let servicePath = Bundle.main.path(forResource: filePath, ofType:"plist")!
        return NSArray(contentsOfFile: servicePath) as! [[String: String]]
    }()

    func servicePath(atIndex index: Int) -> String {
        assert(self.serviceList.count > index, "Invalid service path index")
        return serviceList[index]["ServicePath"]!
    }
    
    public override init() {
        super.init()
    }
    open func extendTicket(_ userCredentials: UserCredentials,
                           completion:@escaping (_ userCredentials: UserCredentials?, _ error: NSError?) -> Void){
        
        let serviceURL = servicePath(atIndex: 0)
        
        var request = URLRequest(url: URL(string: serviceURL)!)
        request.httpMethod = "POST"
        
        let requestString = String(format: "username=%@&password=%@", userCredentials.username, userCredentials.password)
        request.httpBody = requestString.data(using: String.Encoding.utf8);
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        let session = URLSession.shared
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
            
            DispatchQueue.main.async{
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            if error != nil {
                
                if APIsConfig.printResponse {
                    print("Error : '\(error!.localizedDescription)'")
                }
                
                DispatchQueue.main.async{
                    completion(nil, error!.localized)
                }

            } else {
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse {
                    print("StatusCode : '\(statusCode)'")
                }
                
                if APIsConfig.debugHTTPResponse {
                    print("Response : '\(String(describing: response))'")
                }
                
                if statusCode == 200 {
                    
                    let fields = httpResponse!.allHeaderFields as NSDictionary
                    let key = "Set-Cookie"
                    let cookie = fields[key] as! String
                    userCredentials.ticket = cookie
                    
                    DispatchQueue.main.async{
                        NotificationCenter.default.post(name: Notification.Name(rawValue: kUserCredentailsDidUpdateNotification), object: userCredentials)
                        completion(userCredentials, nil)
                    }
                    
                }else if statusCode == 401{
                    
                    DispatchQueue.main.async{
                        NotificationCenter.default.post(name: Notification.Name(rawValue: kUserCredentailsDidFailNotification), object: userCredentials)
                        let error = NSError(domain:NSURLErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "login_error_code_401"])
                        completion(nil, error)
                    }
                
                }else{
                    
                    DispatchQueue.main.async{
                        let error = NSError(login: statusCode)
                        completion(nil, error)
                    }
                }
            }
        })
        
        task.resume()
    }
    
    open func login(_ userCredentials:UserCredentials!,
                    completion:@escaping (_ userCredentials: UserCredentials?, _ error: NSError?) -> Void){
        
        let serviceURL = servicePath(atIndex: 0)
        var request = URLRequest(url: URL(string: serviceURL)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 20.0
        let requestString = String(format: "username=%@&password=%@",userCredentials.username,userCredentials.password)
        request.httpBody = requestString.data(using: String.Encoding.utf8);

        if  APIsConfig.debugURL {
            print("URL : '\(serviceURL)'\(requestString)'")
        }
        
        let session = URLSession.shared
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
            
            DispatchQueue.main.async{
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if APIsConfig.printResponse {
                    print("Error : '\(error!.localizedDescription)'")
                }
                DispatchQueue.main.async{
                    completion(nil, error!.localized)
                }

            } else {
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse!.statusCode
                if APIsConfig.printResponse {
                    print("StatusCode : '\(statusCode)'")
                }
                
                if APIsConfig.debugHTTPResponse {
                    print("Response : '\(String(describing: response))'")
                }
                                
                if statusCode == 200 {
                
                    let fields = httpResponse!.allHeaderFields as! [String:AnyObject]
                    let key = "Set-Cookie"
                    let cookie = fields[key] as! String
                    //let result:Dictionary<String, String> = [cookie:key]
                    userCredentials.ticket = cookie
                    DispatchQueue.main.async{
                        completion(userCredentials, nil)
                    }

                }else{
                    
                    DispatchQueue.main.async{
                        let error = NSError(login: statusCode)
                        completion(nil, error)
                    }
                }
            }
        })
        
        task.resume()
    }
}
