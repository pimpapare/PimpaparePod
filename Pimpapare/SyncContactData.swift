//
//  SyncContact.swift
//  CoreAPIs
//
//  Created by Thanakrit Weekhamchai on 7/21/16.
//  Copyright © 2016 CLBS Ltd. All rights reserved.
//

import UIKit

open class SyncContactData {

    open var contactsInfo: [String: AnyObject]!
    open var user: UserCredentials!
    
    public init(contacts: [String: AnyObject], forUser user: UserCredentials) {
        self.contactsInfo = contacts
        self.user = user
    }
}
