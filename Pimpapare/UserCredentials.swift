//
//  UserCredentials.swift
//  CoreAPIs
//
//  Created by Thiti Sununta on 06/10/2015.
//  Copyright © 2015 CLBS Ltd. All rights reserved.
//

import Foundation

open class UserCredentials  : NSObject {
    
    open var username : String!
    open var password : String!
    open var ticket : String?
    
    public init(username: String,password: String,ticket: String){
    
        self.username = username
        self.password = password
        self.ticket = ticket
    }
} 
