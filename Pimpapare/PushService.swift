//
//  PushService.swift
//  CoreAPIs
//
//  Created by Thiti Sununta on 9/9/2559 BE.
//  Copyright © 2559 CLBS Ltd. All rights reserved.
//

import UIKit

open class PushService  : NSObject {
    
    open var deviceToken : String!
    open var isReceiveSilentBadge : Bool!
    open var isReceiveEventReminder : Bool!
    open var isReceiveLocationAwarenss : Bool!
    open var isSupportMessageEntry : Bool!
    
}
