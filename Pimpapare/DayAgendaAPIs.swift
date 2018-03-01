//
//  DayAgendaAPIs.swift
//  CoreAPIs
//
//  Created by Thiti Sununta on 5/3/2559 BE.
//  Copyright © 2559 CLBS Ltd. All rights reserved.
//  Web Service: http://opengrok.coast.ebuero.de/source/xref/pinguin/webservices/src/main/java/ag/pinguin/webservices/rs/dayplan/DayplanService.java

import UIKit

public enum AdaptiveAppointmentCreatingMode {
    case overrideExistingEntries, overrideNewEntries
}

public typealias DayAgendaFetchAppointmentsCompletion = (_ success: Bool, _ appointments: [[String: AnyObject]]?, _ error: Error?) -> Void

public typealias DayAgendaFetchStandardCallHandlingCompletion = (_ success: Bool, _ callHandling: [String: AnyObject]?, _ error: Error?) -> Void
public typealias DayAgendaUpdateStandardCallHadnlingCompletion = (_ success: Bool, _ error: Error?) -> ()

public typealias DayAgendaUpdateAppointmentCompletion = (_ success: Bool, _ result: [String: AnyObject]?, _ error: Error?) -> Void
public typealias DayAgendaDeleteAppointmentCompletion = (_ success: Bool, _ error: Error?) -> Void
public typealias DayAgendaFetchExcusePhraseTemplatesCompletion = (_ success: Bool, _ excusePhraseTemplates: [[String: AnyObject]]?, _ error: Error?) -> Void

open class DayAgendaAPIs: NSObject, URLSessionDelegate {

    
    fileprivate enum AppointmentCreatingMode {
        case normal, force
    }
    
    enum AppointmentFetchingMode {
        case range, before, after
    }
    
    open static let sharedInstance = DayAgendaAPIs()

    fileprivate lazy var sharedSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(120.0)
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()
    
    fileprivate lazy var serviceList: [[String: String]] = {
        let filePath = APIsConfig.productionMode ? APIsConfig.kDayAgendaServiceFileName : APIsConfig.kTestDayAgendaServiceFileName
        let servicePath = Bundle.main.path(forResource: filePath, ofType:"plist")!
        return NSArray(contentsOfFile: servicePath) as! [[String: String]]
    }()
    
    fileprivate func servicePath(atIndex index: Int) -> String {
        assert(self.serviceList.count > index, "Invalid service path index")
        return serviceList[index]["ServicePath"]!
    }
    
    // MARK: - Fetch
    
    open func fetchAppointments(from fromDate: Date, to toDate: Date, forUser user: UserCredentials, completion: DayAgendaFetchAppointmentsCompletion?) {
        
        fetchAppointments(forUser: user, from: fromDate, to: toDate, mode: .range, limit: 0, completion: completion)
    }
    
    open func fetchAppointments(before beforeDate: Date, forUser user: UserCredentials, limit: Int, completion: DayAgendaFetchAppointmentsCompletion?) {
        
        fetchAppointments(forUser: user, from: beforeDate, to: nil, mode: .before, limit: limit, completion: completion)
    }
    
    open func fetchAppointments(after afterDate: Date, forUser user: UserCredentials, limit: Int, completion: DayAgendaFetchAppointmentsCompletion?) {
        
        fetchAppointments(forUser: user, from: afterDate, to: nil, mode: .after, limit: limit, completion: completion)
    }
    
    fileprivate func fetchAppointments(forUser user: UserCredentials,
                                       from fromDate: Date,
                                       to toDate: Date?,
                                       mode: AppointmentFetchingMode,
                                       limit: Int = 0,
                                       completion: DayAgendaFetchAppointmentsCompletion?)
    {
        let serviceURL: String
        let paramString: String
        
        switch mode {
        case .range:
            serviceURL = servicePath(atIndex: 0)
            paramString = "\(serviceURL)?start=\(stringForDateRequest(fromDate))&end=\(stringForDateRequest(toDate!))"
        case .before:
            serviceURL = servicePath(atIndex: 10)
            paramString = "\(serviceURL)?timestamp=\(stringForDateRequest(fromDate))&max=\(limit)"
        case .after:
            serviceURL = servicePath(atIndex: 11)
            paramString = "\(serviceURL)?timestamp=\(stringForDateRequest(fromDate))&max=\(limit)"
        }
        
        let requestString = paramString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if APIsConfig.debugURL { print("URL : '\(requestString)'") }
        
        var request = URLRequest(url: URL(string: requestString)!)
        
        if let ticket = user.ticket {
            request.addValue(ticket, forHTTPHeaderField: "Cookie")
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request) { (data, response, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if APIsConfig.printResponse { print("Error : '\(error!.localizedDescription)'") }
                if let closure = completion {
                    DispatchQueue.main.async(execute: {
                        closure(false, nil, error?.localized)
                    })
                }
                
            }else{
            
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let result: [[String: AnyObject]]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.allowFragments) as? [[String: AnyObject]]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
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
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) -> Void in
                        
                        if (error != nil) {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                        } else {
                            self.fetchAppointments(forUser: userCredentials!, from: fromDate, to: toDate, mode: mode, limit: limit, completion: completion)
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
        }
        
        task.resume()
    }
    
    open func fetchExcusePhraseTemplates(forUser user: UserCredentials, completion: DayAgendaFetchExcusePhraseTemplatesCompletion?) {
        
        let serviceURL = servicePath(atIndex: 12)
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if  APIsConfig.debugURL { print("URL : '\(requestString)'") }
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        request.addValue(user.ticket!, forHTTPHeaderField: "Cookie")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request) { (data, response, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if APIsConfig.printResponse { print("Error : '\(error!.localizedDescription)'") }
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, nil, error?.localized)
                    }
                }
                return
            }
            
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse!.statusCode
            
            if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
            if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
            
            if statusCode / 100 == 2 {

                let result: [String: AnyObject]!
                do {
                    result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]
                    if APIsConfig.printResponse { print("JSON Response : '\(result)'") }
                    
                } catch let error {
                    result = nil
                    print("JSON Error: \(error)")
                }
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        if let excuseList = result["list"] as? [[String: AnyObject]] {
                            closure(true, excuseList , error)
                        } else {
                            closure(true, nil , nil)
                        }
                    }
                }

                
            } else if statusCode == 401 {
                
                UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) -> Void in
                    if (error != nil) {
                        if let closure = completion {
                            DispatchQueue.main.async {
                                closure(false, nil, error?.localized)
                            }
                        }
                    } else {
                        self.fetchExcusePhraseTemplates(forUser: userCredentials!, completion: completion)
                    }
                    
                })
                
            } else {
                
                if APIsConfig.printResponse { print("Error : '\(error!.localizedDescription)'") }
                
                if let closure = completion {
                    DispatchQueue.main.async {
                        closure(false, nil, error?.localized)
                    }
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Standard Call Handling
    open func fetchStandardCallHandling(forUser user: UserCredentials, completion: DayAgendaFetchStandardCallHandlingCompletion?) {
        
        let serviceURL = servicePath(atIndex: 7)
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if  APIsConfig.debugURL { print("fetchStandardCallHandling URL : '\(requestString)'") }
        
        var request = URLRequest(url: URL(string: requestString)!)
        request.addValue(user.ticket!, forHTTPHeaderField: "Cookie")
        request.httpMethod = "GET"
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if APIsConfig.printResponse { print("Error : '\(error!.localizedDescription)'") }
                
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
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                        
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
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) -> Void in
                        if (error != nil) {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                        } else {
                            self.fetchStandardCallHandling(forUser: userCredentials!, completion: completion)
                        }
                        
                    })
                    
                } else {
                    
                    if APIsConfig.printResponse { print("Error : '\(error!.localizedDescription)'") }
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
    
    open func updateDefaultCallHandling(_ defaultCallHandling: [String: Any], forUser user: UserCredentials, completion: DayAgendaUpdateStandardCallHadnlingCompletion?) {
        
        let serviceURL = servicePath(atIndex: 8)
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if  APIsConfig.debugURL { print("URL : '\(requestString)'") }
        
        let data = try! JSONSerialization.data(withJSONObject: defaultCallHandling, options: .prettyPrinted)
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        request.addValue(user.ticket!, forHTTPHeaderField: "Cookie")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if APIsConfig.printResponse { print("Error : '\(error!.localizedDescription)'") }
                
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
                    
                    let result: [String: AnyObject]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                        
                    } catch let error {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
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
                            self.updateDefaultCallHandling(defaultCallHandling, forUser: userCredentials!, completion: completion)
                        }
                        
                    })
                    
                } else {
                    
                    if APIsConfig.printResponse { print("Error : '\(error!.localizedDescription)'") }
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
    
    // MARK: - Create
    
    // adaptive
    open func createOrUpdateAppointment(_ appointmentInfo: [String: AnyObject], forUser user: UserCredentials, adaptiveMode mode: AdaptiveAppointmentCreatingMode, completion: DayAgendaUpdateAppointmentCompletion?) {
        
        let serviceURL:String = servicePath(atIndex: 13)
        let modeParam: String
        switch mode {
        case .overrideNewEntries:
            modeParam = "?mode=2"
        case .overrideExistingEntries:
            modeParam = "?mode=1"
        }
        
        let requestString = (serviceURL + modeParam).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!

        if  APIsConfig.debugURL { print("URL : '\(requestString)'") }
        
        let appointmentData = try! JSONSerialization.data(withJSONObject: appointmentInfo, options: .prettyPrinted)
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        request.addValue(user.ticket!, forHTTPHeaderField: "Cookie")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = appointmentData
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if APIsConfig.printResponse { print("Error : '\(String(describing: error?.localizedDescription))'") }
                if let closure = completion {
                    DispatchQueue.main.async(execute: {
                        closure(false, nil, error?.localized)
                    })
                }
                
            }else{
                
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse!.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(statusCode)'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode / 100 == 2 {
                    
                    let result: [String: AnyObject]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                        
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
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) -> Void in
                        
                        if (error != nil) {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                        } else {
                            self.createOrUpdateAppointment(appointmentInfo, forUser: userCredentials!, adaptiveMode: mode, completion: completion)
                        }
                        
                    })
                    
                } else {
                    
                    if APIsConfig.printResponse { print("Error : '\(String(describing: error?.localizedDescription))'") }
                    
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
    
    //
    open func saveOrUpdateAppointment(_ appointmentInfo: [String: AnyObject], forUser user: UserCredentials, adaptiveMode mode: AdaptiveAppointmentCreatingMode, completion: DayAgendaUpdateAppointmentCompletion?) {
        
        var serviceURL:String = servicePath(atIndex: 14)

        switch mode {
        case .overrideNewEntries:
            serviceURL = serviceURL + "forcesave"
        case .overrideExistingEntries:
            serviceURL = serviceURL + "save"
        }
        
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if  APIsConfig.debugURL { print("URL : '\(requestString)'") }
        
        let appointmentData = try! JSONSerialization.data(withJSONObject: appointmentInfo, options: .prettyPrinted)
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        request.addValue(user.ticket!, forHTTPHeaderField: "Cookie")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = appointmentData
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
                
                if APIsConfig.printResponse { print("Error : '\(String(describing: error?.localizedDescription))'") }
                
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
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                        
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
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) -> Void in
                        
                        if (error != nil) {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                        } else {
                            self.createOrUpdateAppointment(appointmentInfo, forUser: userCredentials!, adaptiveMode: mode, completion: completion)
                        }
                        
                    })
                    
                } else {
                    
                    if APIsConfig.printResponse { print("Error : '\(String(describing: error?.localizedDescription))'") }
                    
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
    
    // nomal + force delete conflicts
    fileprivate func createOrUpdateAppointment(_ appointmentInfo: [String: AnyObject], forUser user: UserCredentials, mode: AppointmentCreatingMode, completion: DayAgendaUpdateAppointmentCompletion?) {
        
        let serviceURL: String
        switch mode {
        case .force:
           serviceURL = servicePath(atIndex: 3)
        default:
            serviceURL = servicePath(atIndex: 1)
        }
        
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if  APIsConfig.debugURL { print("URL : '\(requestString)'") }
        
        let appointmentData = try! JSONSerialization.data(withJSONObject: appointmentInfo, options: .prettyPrinted)
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        request.addValue(user.ticket!, forHTTPHeaderField: "Cookie")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = appointmentData
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
                let statusCode = httpResponse?.statusCode
                
                if APIsConfig.printResponse { print("StatusCode : '\(String(describing: statusCode))'") }
                if APIsConfig.debugHTTPResponse { print("Response : '\(String(describing: response))'") }
                
                if statusCode! / 100 == 2 {
                    
                    let result: [String: AnyObject]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                        
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
                    
                    UserAPIs.sharedInstance.extendTicket(user, completion: { (userCredentials, error) -> Void in
                        
                        if (error != nil) {
                            if let closure = completion {
                                DispatchQueue.main.async {
                                    closure(false, nil, error?.localized)
                                }
                            }
                        } else {
                            self.createOrUpdateAppointment(appointmentInfo, forUser: userCredentials!, mode: mode, completion: completion)
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
    
    open func createOrUpdateAppointment(_ appointmentInfo: [String: AnyObject], forUser user: UserCredentials, completion: DayAgendaUpdateAppointmentCompletion?) {
        // normal
        createOrUpdateAppointment(appointmentInfo, forUser: user, mode: .normal, completion: completion)
    }
    
    open func forceCreateOrUpdateAppointment(_ appointmentInfo: [String: AnyObject], forUser user: UserCredentials, completion: DayAgendaUpdateAppointmentCompletion?) {
        // force delete any conflicts
        createOrUpdateAppointment(appointmentInfo, forUser: user, mode: .force, completion: completion)
    }
    
    // MARK: - Finish
    
    // MARK: - Delete
    
    open func deleteAppointment(_ appointment: Appointment, forUser user: UserCredentials, completion: DayAgendaDeleteAppointmentCompletion?) {
        
        let serviceURL = servicePath(atIndex: 2) + appointment.identifier
        let requestString = serviceURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        if  APIsConfig.debugURL { print("URL : '\(requestString)'") }
        
        var request = URLRequest(url: URL(string: requestString as String)!)
        request.addValue(user.ticket!, forHTTPHeaderField: "Cookie")
        request.httpMethod = "POST"
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let task = sharedSession.dataTask(with: request, completionHandler: {(data, response, error) -> Void in

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if error != nil {
            
                if APIsConfig.printResponse { print("Error : '\(error!.localizedDescription)'") }
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
                    
                    let result: [String: AnyObject]?
                    do {
                        result = try JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: AnyObject]
                        if APIsConfig.printResponse { print("JSON Response : '\(String(describing: result))'") }
                        
                    } catch let error {
                        result = nil
                        print("JSON Error: \(error)")
                    }
                    
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
                            self.deleteAppointment(appointment, forUser: userCredentials!, completion: completion)
                        }
                    })
                    
                } else {
                    
                    if APIsConfig.printResponse { print("Error : '\(error!.localizedDescription)'") }
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
    
    // MARK: - Utilities

    func stringForDateRequest(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = APIsConfig.serverDateFormat
        formatter.timeZone = TimeZone(identifier: APIsConfig.serverTimeZone)
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
}
