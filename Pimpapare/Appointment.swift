//
//  Appointment.swift
//  CoreAPIs
//
//  Created by Thanakrit Weekhamchai on 7/18/16.
//  Copyright © 2016 CLBS Ltd. All rights reserved.
//

import UIKit

public class Appointment {

    public var identifier: String!
    public var name: String?
    public var startDate: Date?
    public var endDate: Date?
    
    public var startNow: Bool = false
    
    public var callHandling: CallHandling?
    
    public init(withIdentifier identifier: String) {
        self.identifier = identifier
    }
    
    public func copy() -> Appointment {
    
        let coppied = Appointment(withIdentifier: self.identifier)
        coppied.name = self.name
        coppied.startDate = self.startDate
        coppied.endDate = self.endDate
        coppied.startNow = self.startNow
        coppied.callHandling = self.callHandling?.copy()
        
        return coppied
    }
}
