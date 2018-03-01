//
//  CallHandling.swift
//  CoreAPIs
//
//  Created by Thanakrit Weekhamchai on 7/18/16.
//  Copyright © 2016 CLBS Ltd. All rights reserved.
//

import UIKit

public class CallHandling {

    public var instructionID: String!

    public var identifier: String?
    public var message: String?
    public var profileName: String?
    
    public var isProfile: Bool = false
    public var isDefault: Bool = false
    
    public var order: Int = 0
    
    public init(withInstructionID instruction: String) {
        self.instructionID = instruction
    }
    
    
    public func copy() -> CallHandling {
        
        let coppied = CallHandling(withInstructionID: self.instructionID)
        coppied.identifier = self.identifier
        coppied.message = self.message
        coppied.profileName = self.profileName
        coppied.isProfile = self.isProfile
        coppied.isDefault = self.isDefault
        coppied.order = self.order
        
        return coppied
    }
}
