//
//  File.swift
//  
//
//  Created by Marco Pilloni on 02/05/2020.
//

import Foundation
import CoreLocation


public struct iCalEvent {
    
    public let identifier: String
    
    public let name: String
    public let startDate: Date
    public let endDate: Date
    public let location: CLLocation?
    public let notes: String?
    public let url: URL?
    
    public let recurrenceRule: Recurrence?
    
}
