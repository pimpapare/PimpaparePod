//
//  CallHistoryAPIs.swift
//  CoreAPIs
//
//  Created by Thiti Sununta on 05/10/2015.
//  Copyright © 2015 CLBS Ltd. All rights reserved.
//

import Foundation

public typealias CallHistoryFileDownloadProgress = (_ progress: Double?) -> Void
public typealias CallHistoryFileDownloadCompletion = (_ success:Bool, _ filePath:String? ,_ error: NSError?) -> Void

open class CallHistoryAPIs : NSObject,URLSessionDelegate,URLSessionDownloadDelegate {
    
    open static let sharedInstance = CallHistoryAPIs()
    
    fileprivate lazy var sharedSession: Foundation.URLSession = {
        let config = URLSessionConfiguration.default
        let session = Foundation.URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()
    
    lazy var serviceList: [[String: String]] = {
        let filePath = APIsConfig.productionMode ? APIsConfig.kCalHistoryServiceFileName : APIsConfig.kTestCalHistoryServiceFileName
        let servicePath = Bundle.main.path(forResource: filePath, ofType:"plist")!
        return NSArray(contentsOfFile: servicePath) as! [[String: String]]
    }()
    
    func servicePath(atIndex index: Int) -> String {
        assert(self.serviceList.count > index, "Invalid service path index")
        return self.serviceList[index]["ServicePath"]!
    }
    
    var fromDate : Date!
    var toDate : Date!
    
    fileprivate let maxReceiveEntry = 20
    fileprivate let maxUpdateEntry = 1000
    
    
    var callHistoryFaxDownloadCompletion:CallHistoryFileDownloadCompletion?
    var callHistoryFaxDownloadProgress:CallHistoryFileDownloadProgress?
    
    var callHistoryVoiceDownloadCompletion:CallHistoryFileDownloadCompletion?
    var callHistoryVoiceDownloadProgress:CallHistoryFileDownloadProgress?
    
    
    var voiceDownloadTask:URLSessionDownloadTask?
    var faxDownloadTask:URLSessionDownloadTask?
    var voiceDocumentId:String?
    var faxDocumentId:String?
    
    public override init() {
        super.init()
    }
    
    open func fetchCallHistoryBeforeDate(_ beforeDate:Date,userCredentials:UserCredentials,
                                         completion:((_ success:Bool,_ result:[String:AnyObject]?,_ error:NSError?) -> Void)?)
    {
        self.fromDate = beforeDate
        
        let serviceURL = servicePath(atIndex:10)
        var requestString = "\(serviceURL)?timestamp=\(stringForDateRequest(beforeDate))&max=\(maxReceiveEntry)"
        requestString = requestString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        if let ticket = userCredentials.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if APIsConfig.printResponse {
                    print("Error : '\(error!.localizedDescription)'")
                }
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let result: [String: AnyObject]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                    } catch let error as NSError {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, result, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(userCredentials, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        }else{
                            
                            self.fetchCallHistoryBeforeDate(self.fromDate, userCredentials: userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
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
    
    open func fetchHideCallHistoryBeforeDate(_ beforeDate:Date,userCredentials:UserCredentials,
                                             completion:((_ success:Bool,_ result:[String:AnyObject]?,_ error:NSError?) -> Void)?)
    {
        self.fromDate = beforeDate
        
        let serviceURL = servicePath(atIndex:19)
        var requestString = "\(serviceURL)?timestamp=\(stringForDateRequest(beforeDate))&max=\(maxReceiveEntry)"
        requestString = requestString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        if let ticket = userCredentials.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

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
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let result: [String: AnyObject]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                    } catch let error as NSError {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, result, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(userCredentials, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        }else{
                            
                            self.fetchHideCallHistoryBeforeDate(self.fromDate, userCredentials: userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
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
    
    open func fetchCallHistoryNewer(_ fromDate:Date, userCredentials:UserCredentials,
                                    completion:((_ success:Bool, _ result:[String:AnyObject]?,_ error:NSError?) -> Void)?){
        
        self.fromDate = fromDate
        
        let serviceURL = servicePath(atIndex: 9)
        var requestString = "\(serviceURL)?start=\(stringForDateRequest(fromDate))&max=\(maxUpdateEntry)"
        requestString = requestString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        request.timeoutInterval = 30
        
        if let ticket = userCredentials.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

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
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let result: [String: AnyObject]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                    } catch let error as NSError {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, result, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(userCredentials, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        } else {
                            
                            self.fetchCallHistoryNewer(self.fromDate, userCredentials: userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(false, nil, nil)
                        }
                    }
                }
            }
        })
        task.resume()
    }
    
    open func fetchCallHistoryByIdentifier(_ identifier:String, userCredentials:UserCredentials,
                                           completion:((_ success:Bool, _ result:[String:AnyObject]?,_ error:NSError?) -> Void)?){
        
        let serviceURL = servicePath(atIndex: 11)
        var requestString = "\(serviceURL)/\(identifier)"
        requestString = requestString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!

        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        if let ticket = userCredentials.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
            
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
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let result: [String: AnyObject]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                    } catch let error as NSError {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, result, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(userCredentials, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        }else{
                            
                            self.fetchCallHistoryByIdentifier(identifier, userCredentials: userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
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
    
    open func fetchNumberOfUnreadMessageEntry(_ userCredentials:UserCredentials,
                                              completion:((_ success:Bool, _ result:Int?,_ error:NSError?) -> Void)?)
    {
        let serviceURL = servicePath(atIndex: 12)
        let requestString = String(format: "%@", serviceURL)
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        if let ticket = userCredentials.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if  error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, nil, error?.localized)
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
                    let unreadNumber = Int(responseString!)
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, unreadNumber, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(userCredentials, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        }else{
                            
                            self.fetchNumberOfUnreadMessageEntry(userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
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
    
    open func updateRead(_ messageEntries:[String:AnyObject],userCredentials:UserCredentials,
                         completion:((_ success:Bool, _ result:[String:AnyObject]?,_ error:NSError?) -> Void)?)
    {
        let serviceURL = servicePath(atIndex: 13)
        let requestString = String(format: "%@", serviceURL)
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var data:Data!
        do {
            data = try JSONSerialization.data(withJSONObject: messageEntries, options: .prettyPrinted)
        } catch {
            print(error)
        }
        let jsonString = String(data: data!, encoding: String.Encoding.utf8)
        data = jsonString?.data(using: String.Encoding.utf8)
        
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        if let ticket = userCredentials.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        
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
                    DispatchQueue.main.async {
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let result: [String: AnyObject]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                    } catch let error as NSError {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, result, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(userCredentials, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        }else{
                            
                            self.updateRead(messageEntries, userCredentials: userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
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
    
    
    open func generateShortGoogleURL(longURL:String,
                                     completion:((_ success:Bool, _ result:String,_ error:NSError?) -> Void)?)
    {
        let parameters = ["longUrl": longURL]
        let url = URL(string: "https://www.googleapis.com/urlshortener/v1/url?key=AIzaSyCuQ_dku2qMUsjKE2E2KWiPI9ESnyMiV04")!
        
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

            if error != nil {
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, "", error?.localized)
                    }
                }
                
            }else{
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any] {
                        print(json)
                        if let closure = completion {
                            DispatchQueue.main.async {
                                closure(true, json.description, nil)
                            }
                        }
                    }
                } catch let error {
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(false, "", error.localized)
                        }
                    }
                }
            }
        })
        task.resume()
    }
    
    open func updateHide(_ messageEntries:[String:AnyObject],userCredentials:UserCredentials,
                         completion:((_ success:Bool, _ result:[String:AnyObject]?,_ error:NSError?) -> Void)?)
    {
        let serviceURL = servicePath(atIndex: 17)
        let requestString = String(format: "%@", serviceURL)
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var data:Data!
        do {
            data = try JSONSerialization.data(withJSONObject: messageEntries, options: .prettyPrinted)
        } catch {
            print(error)
        }
        let jsonString = String(data: data!, encoding: String.Encoding.utf8)
        data = jsonString?.data(using: String.Encoding.utf8)
        
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        if let ticket = userCredentials.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        
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
                    DispatchQueue.main.async {
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let result: [String: AnyObject]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                    } catch let error as NSError {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, result, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(userCredentials, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        }else{
                            
                            self.updateHide(messageEntries, userCredentials: userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
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
    
    
    open func updateDelete(_ messageEntries:[String:AnyObject],userCredentials:UserCredentials,
                           completion:((_ success:Bool, _ result:[String:AnyObject]?,_ error:NSError?) -> Void)?)
    {
        let serviceURL = servicePath(atIndex: 18)
        let requestString = String(format: "%@", serviceURL)
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var data:Data!
        do {
            data = try JSONSerialization.data(withJSONObject: messageEntries, options: .prettyPrinted)
        } catch {
            print(error)
        }
        let jsonString = String(data: data!, encoding: String.Encoding.utf8)
        data = jsonString?.data(using: String.Encoding.utf8)
        
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        if let ticket = userCredentials.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        
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
                    DispatchQueue.main.async {
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let result: [String: AnyObject]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                    } catch let error as NSError {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, result, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(userCredentials, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        }else{
                            
                            self.updateDelete(messageEntries, userCredentials: userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
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
    
    open func updateState(_ messageEntries:[String:AnyObject],userCredentials:UserCredentials,
                          completion:((_ success:Bool, _ result:[String:AnyObject]?,_ error:NSError?) -> Void)?)
    {
        let serviceURL = servicePath(atIndex: 14)
        let requestString = String(format: "%@", serviceURL)
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var data:Data!
        do {
            data = try JSONSerialization.data(withJSONObject: messageEntries, options: .prettyPrinted)
        } catch {
            print(error)
        }
        let jsonString = String(data: data!, encoding: String.Encoding.utf8)
        data = jsonString?.data(using: String.Encoding.utf8)
        
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        if let ticket = userCredentials.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        
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
                    DispatchQueue.main.async {
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let result: [String: AnyObject]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                    } catch let error as NSError {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, result, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(userCredentials, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        }else{
                            
                            self.updateState(messageEntries, userCredentials: userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
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
    
    
    open func markAllMessageEntryAsRead(_ userCredentials:UserCredentials,
                                        completion:((_ success:Bool, _ result:Int?,_ error:NSError?) -> Void)?)
    {
        let serviceURL = servicePath(atIndex: 16)
        let requestString = String(format: "%@", serviceURL)
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        if let ticket = userCredentials.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

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
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let responseString = String(data: data!, encoding: String.Encoding.utf8)
                    if APIsConfig.printResponse { print("Response : '\(String(describing: responseString))'") }
                    let markAsRead = Int(responseString!)
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, markAsRead, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(userCredentials, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        }else{
                            
                            self.markAllMessageEntryAsRead(userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
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
    
    
    open func emptyMessageEntryTrash(_ userCredentials:UserCredentials,
                                     completion:((_ success:Bool, _ result:AnyObject?,_ error:NSError?) -> Void)?){
        
        let serviceURL = servicePath(atIndex: 20)
        let requestString = String(format: "%@", serviceURL)
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        if let ticket = userCredentials.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
            
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
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(userCredentials, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        }else{
                            
                            self.emptyMessageEntryTrash(userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(false, nil, nil)
                        }
                    }
                }
            }
            
        })
        
        task.resume()
    }
    
    
    open func updateQualityFeedback(_ qualityFeedback:[String:AnyObject],userCredentials:UserCredentials,
                                    completion:((_ success:Bool, _ result:[String:AnyObject]?,_ error:NSError?) -> Void)?){
        
        let serviceURL = servicePath(atIndex: 7)
        let requestString = String(format: "%@", serviceURL)
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        var data:Data!
        do {
            data = try JSONSerialization.data(withJSONObject: qualityFeedback, options: .prettyPrinted)
        } catch {
            print(error)
        }
        let jsonString = String(data: data!, encoding: String.Encoding.utf8)
        data = jsonString?.data(using: String.Encoding.utf8)
        
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        if let ticket = userCredentials.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        
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
                    DispatchQueue.main.async {
                        closure(false, nil, error?.localized)
                    }
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let result: [String: AnyObject]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                    } catch let error as NSError {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
                    if let closure = completion {
                        DispatchQueue.main.async {
                            closure(true, result, nil)
                        }
                    }
                    
                }else if (statusCode == 401){
                    
                    UserAPIs.sharedInstance.extendTicket(userCredentials, completion: { (userCredentials, error) in
                        if error != nil {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                            
                        }else{
                            
                            self.updateQualityFeedback(qualityFeedback, userCredentials: userCredentials!, completion: completion)
                        }
                    })
                    
                }else{
                    
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
    
    open func downloadVoiceMail(_ documentId:String,voiceURL:String,userCredential:UserCredentials,progress:CallHistoryFileDownloadProgress?,completion:CallHistoryFileDownloadCompletion?) {
        
        callHistoryVoiceDownloadProgress = progress
        callHistoryVoiceDownloadCompletion = completion
        self.voiceDocumentId = documentId
        let configuration = URLSessionConfiguration.background(withIdentifier: documentId)
        let backgroundSession = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        let request = URLRequest(url: URL(string: voiceURL)!)
        if APIsConfig.debugURL {
            print("URL : '\(voiceURL)'")
        }
        voiceDownloadTask = backgroundSession.downloadTask(with: request)
        voiceDownloadTask!.resume()
    }
    
    open func downloadFaxDocument(_ documentId:String,userCredential:UserCredentials,progress:CallHistoryFileDownloadProgress?,completion:CallHistoryFileDownloadCompletion?) {
        
        callHistoryFaxDownloadProgress = progress
        callHistoryFaxDownloadCompletion = completion
        
        let serviceURL = servicePath(atIndex: 15)
        var requestString = "\(serviceURL)?documentId=\(documentId)"
        requestString = requestString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if APIsConfig.debugURL {
            print("URL : '\(requestString)'")
        }
        
        self.faxDocumentId = documentId
        let configuration = URLSessionConfiguration.background(withIdentifier: documentId)
        let backgroundSession = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        var request = URLRequest(url: URL(string: requestString)!)
        if let ticket = userCredential.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        
        faxDownloadTask = backgroundSession.downloadTask(with: request)
        faxDownloadTask!.resume()
    }
    
    //MARK: session delegate
    open func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("session error: \(String(describing: error?.localizedDescription)).")
    }
    
    open func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
       
        print("session \(session) has finished the download task \(downloadTask) of URL \(location).")
        
        let httpResponse = downloadTask.response as? HTTPURLResponse
        let statusCode = httpResponse!.statusCode
        if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
        
        if statusCode / 100 == 2 {
            
            let fileManager = FileManager()
            
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)[0]
            let downloadPath:String = documentsPath + "/Downloads/"
            
            if !fileManager.fileExists(atPath: downloadPath) {
                
                do {
                    try fileManager.createDirectory(atPath: downloadPath, withIntermediateDirectories: false, attributes: nil)
                } catch let error as NSError {
                    print ("Error: \(error.domain)")
                }
            }
            
            let suggestedFileName:String = downloadTask.response!.suggestedFilename!
            let fileExtension =  suggestedFileName.pathExtension
            
            var documentId:String = ""
            if downloadTask == voiceDownloadTask {
                documentId = voiceDocumentId!
            }
            else if downloadTask == faxDownloadTask{
                documentId = faxDocumentId!
            }else{
                
            }
            
            let saveFileName = documentId.appendingFormat(".%@", fileExtension!.lowercased())
            let savePath = downloadPath.stringByAppendingPathComponent(saveFileName)
            
            if fileManager.fileExists(atPath: savePath) {
                do {
                    try fileManager.removeItem(at: URL(fileURLWithPath:savePath))
                } catch let error as NSError {
                    print ("Error: \(error.domain)")
                }
            }
            
            do {
                try fileManager.moveItem(at: location, to: URL(fileURLWithPath:savePath))
                print("File is saved to : \(savePath)")
                
            } catch let error as NSError {
                print ("Error: \(error.domain)")
            }
            
            if downloadTask == faxDownloadTask {
                DispatchQueue.main.async(execute: {
                    if let closure = self.callHistoryFaxDownloadCompletion {
                        closure(true, savePath, nil)
                    }
                })
            }
            if downloadTask == voiceDownloadTask {
                DispatchQueue.main.async(execute: {
                    if let closure = self.callHistoryVoiceDownloadCompletion {
                        closure(true, savePath, nil)
                    }
                })
            }
            
        }else{
            
            if downloadTask == faxDownloadTask {
                DispatchQueue.main.async(execute: {
                    if let closure = self.callHistoryFaxDownloadCompletion {
                        closure(false, nil, nil)
                    }
                })
            }
            if downloadTask == voiceDownloadTask {
                DispatchQueue.main.async(execute: {
                    if let closure = self.callHistoryVoiceDownloadCompletion {
                        closure(false, nil, nil)
                    }
                })
            }
        }
    }
    
    open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("session \(session) download task \(downloadTask) wrote an additional \(bytesWritten) bytes (total \(totalBytesWritten) bytes) out of an expected \(totalBytesExpectedToWrite) bytes.")
        if (downloadTask == voiceDownloadTask){
            let progress:Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            DispatchQueue.main.async(execute: {
                if let closure = self.callHistoryVoiceDownloadProgress {
                    closure(progress)
                }
            })
        }
        if (downloadTask == faxDownloadTask){
            let progress:Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            DispatchQueue.main.async(execute: {
                if let closure = self.callHistoryFaxDownloadProgress {
                    closure(progress)
                }
            })
        }
    }
    
    open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("session \(session) download task \(downloadTask) resumed at offset \(fileOffset) bytes out of an expected \(expectedTotalBytes) bytes.")
    }
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error == nil {
            print("session \(session) download completed")
            if task == faxDownloadTask {
                DispatchQueue.main.async {
                    if let closure = self.callHistoryFaxDownloadCompletion {
                        closure(false, nil, nil)
                    }
                }
            }
            if task == voiceDownloadTask {
                DispatchQueue.main.async {
                    if let closure = self.callHistoryVoiceDownloadCompletion {
                        closure(false, nil, nil)
                    }
                }
            }
            
        } else {
            print("session \(session) download failed with error \(String(describing: error?.localizedDescription))")
            if task == faxDownloadTask {
                DispatchQueue.main.async {
                    if let closure = self.callHistoryFaxDownloadCompletion {
                        closure(false, nil, error?.localized)
                    }
                }
            }
            if task == voiceDownloadTask {
                DispatchQueue.main.async {
                    if let closure = self.callHistoryVoiceDownloadCompletion {
                        closure(false, nil, error?.localized)
                    }
                }
            }
        }
    }
    
    open func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("background session \(session) finished events.")
        if !session.configuration.identifier!.isEmpty {
        }
    }
    
    func stringForDateRequest(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = APIsConfig.serverDateFormat
        formatter.timeZone = TimeZone(identifier: APIsConfig.serverTimeZone)
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
    
}

extension String {
    
    var pathExtension: String? {
        return URL(fileURLWithPath: self).pathExtension
    }
    var lastPathComponent: String? {
        return URL(fileURLWithPath: self).lastPathComponent
    }
    
    func stringByAppendingPathComponent(_ path: String) -> String {
        let nsSt = self as NSString
        return nsSt.appendingPathComponent(path)
    }
}
