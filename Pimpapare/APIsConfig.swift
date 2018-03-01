//
//  APIsConfig.swift
//  CoreAPIs
//
//  Created by Thiti Sununta on 17/06/2015.
//  Copyright (c) 2015 CLBS Ltd. All rights reserved.
//

import UIKit

public struct APIsConfig {
    
    fileprivate static let configDict: [String: AnyObject] = {
        let bundle = Bundle(identifier: "th.in.office24.apis")! as Bundle
        let configFilePath = bundle.path(forResource: "APIsConfig", ofType:"plist")!
        let config = NSDictionary(contentsOfFile: configFilePath) as! [String: AnyObject]
        return config
    }()

    static let productionMode: Bool = {
        return configDict["Production Mode"] as! Bool
    }()
    
    static let printResponse: Bool = {
        return configDict["Print Response"] as! Bool
    }()
    
    static let debugHTTPResponse: Bool = {
        return configDict["Debug HTTP Response"] as! Bool
    }()
    
    static let debugURL: Bool = {
        return configDict["Debug URL"] as! Bool
    }()
    
    static let useMockupData: Bool = {
        return configDict["Use Mockup Data"] as! Bool
    }()
    
    public static let serverTimeZone : String = {
        return configDict["Server Time Zone"] as! String
    }()
    
    public static let serverDateFormat : String = {
       return configDict["Server Date Formatt"] as! String
    }()
    
    // MARK: - Keys
    
    static let kUserServiceFileName = "UserServiceConfig"
    static let kDayAgendaServiceFileName = "DayPlannerServiceConfig"
    static let kCalHistoryServiceFileName = "CallHistoryServiceConfig"
    static let kNotificationServiceFileName = "NotificationServiceConfig"
    static let kContactSyncServiceFileName = "ContactSyncServiceConfig"
    static let kFeedbackServiceFileName = "FeedbackServiceConfig"
    static let kAccountRecoveryServiceFileName = "AccountRecoveryServiceConfig"
    static let kRegisterServiceFileName = "RegisterServiceConfig"
    static let kAppUtilityServiceFileName = "AppUtilityServiceConfig"
    static let kCustomerServiceFileName = "CustomerServiceConfig"
    static let kPhoneServiceFileName = "PhoneServiceConfig"
    
    static let kTestUserServiceFileName = "TSVUserServiceConfig"
    static let kTestDayAgendaServiceFileName = "TSVDayPlannerServiceConfig"
    static let kTestCalHistoryServiceFileName = "TSVCallHistoryServiceConfig"
    static let kTestNotificationServiceFileName = "TSVNotificationServiceConfig"
    static let kTestContactSyncServiceFileName = "TSVContactSyncServiceConfig"
    static let kTestFeedbackServiceFileName = "TSVFeedbackServiceConfig"
    static let kTestAccountRecoveryServiceFileName = "TSVAccountRecoveryServiceConfig"
    static let kTestRegisterServiceFileName = "TSVRegisterServiceConfig"
    static let kTestAppUtilityServiceFileName = "TSVAppUtilityServiceConfig"
    static let kTestCustomerServiceFileName = "TSVCustomerServiceConfig"
    static let kTestPhoneServiceFileName = "TSVPhoneServiceConfig"

}
