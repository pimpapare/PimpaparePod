//
//  AppUtilityAPIs.swift
//  CoreAPIs
//
//  Created by Thanakrit Weekhamchai on 7/15/16.
//  Copyright © 2016 CLBS Ltd. All rights reserved.
//

import UIKit
import SystemConfiguration

public typealias AccessClosure = (_ success: Bool, _ supported: Bool, _ error: NSError?) -> ()

open class AppUtilityAPIs: NSObject, URLSessionDelegate {
    
    open static let sharedInstance = AppUtilityAPIs()
    
    fileprivate lazy var sharedSession: URLSession = {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()
    
    fileprivate lazy var serviceList: [[String: String]] = {
        let filePath = APIsConfig.productionMode ? APIsConfig.kAppUtilityServiceFileName : APIsConfig.kTestAppUtilityServiceFileName
        let servicePath = Bundle.main.path(forResource: filePath, ofType:"plist")!
        return NSArray(contentsOfFile: servicePath) as! [[String: String]]
    }()
    
    fileprivate func servicePath(atIndex index: Int) -> String {
        assert(self.serviceList.count > index, "Invalid service path index")
        return serviceList[index]["ServicePath"]!
    }
    
    open func internetConnectionAvailable() -> Bool{
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    open func checkSupport(forAppVersion version: String, completion: AccessClosure?) {
        
        let serviceURL = servicePath(atIndex: 0)
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.httpMethod = "GET"
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = sharedSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, false, error?.localized)
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
                    
                    let minSupportedVersion = String(data: data!, encoding: String.Encoding.utf8)!
                    
                    var minSupportNum = Int(minSupportedVersion.replacingOccurrences(of: ".", with: ""))!
                    if minSupportNum < 100 {
                        minSupportNum = minSupportNum * 10
                    }
                    
                    var appVersionNum = Int(version.replacingOccurrences(of: ".", with: ""))!
                    if appVersionNum < 100 {
                        appVersionNum = appVersionNum * 10
                    }
                    
                    print("App version: \(appVersionNum), minimum supported version: \(minSupportNum)")
                    
                    let isSupported = appVersionNum >= minSupportNum
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, isSupported, nil)
                        }
                    }
                    
                } else {
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(false, false, error?.localized)
                        }
                    }
                }
            }
        })
        
        task.resume()
    }
}

extension NSError {
    
    convenience init(login statusCode:Int) {
        
        var errorDescription = ""
        
        if statusCode == 401{
            errorDescription = "login_error_code_401"
        }else if statusCode == 403{
            errorDescription = "login_error_code_403"
        }else if statusCode == 404{
            errorDescription = "login_error_code_404"
        }else if statusCode == 500{
            errorDescription = "login_error_code_500"
        }else if statusCode == 502{
            errorDescription = "login_error_code_502"
        }else if statusCode == 503{
            errorDescription = "login_error_code_503"
        }else if statusCode == 504{
            errorDescription = "login_error_code_504"
        }else{
            errorDescription = "login_error_code_default"
        }
        self.init(domain: NSURLErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : errorDescription])
    }
    
    var localized: NSError? {
        if self.code == Int(CFNetworkErrors.cfurlErrorUserAuthenticationRequired.rawValue)  || self.code == Int(CFNetworkErrors.cfurlErrorUserCancelledAuthentication.rawValue){
            return NSError(domain:self.domain, code: self.code, userInfo: [NSLocalizedDescriptionKey : "login_error_code_401"])
        }else if self.code == Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue) {
            return NSError(domain:self.domain, code: self.code, userInfo: [NSLocalizedDescriptionKey : "no_network"])
        }else{
            return self
        }
    }
}
extension Error {
    
    var localized: NSError? {
        if let nsError = (self as NSError?){
            if nsError.code == Int(CFNetworkErrors.cfurlErrorUserAuthenticationRequired.rawValue)  || nsError.code == Int(CFNetworkErrors.cfurlErrorUserCancelledAuthentication.rawValue){
                return NSError(domain:nsError.domain, code: nsError.code, userInfo: [NSLocalizedDescriptionKey : "login_error_code_401"])
            }else if nsError.code == Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue) {
                return NSError(domain:nsError.domain, code: nsError.code, userInfo: [NSLocalizedDescriptionKey : "no_network"])
            }else{
                return nsError
            }
            
        }else{
            return self as NSError?
        }
    }
}
