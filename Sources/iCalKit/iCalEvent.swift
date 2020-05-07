//
//  File.swift
//  
//
//  Created by Marco Pilloni on 02/05/2020.
//

import Foundation
import CoreLocation


public struct iCalEvent {
    
    let name: String
    let startDate: Date
    let endDate: Date
    let location: CLLocation?
    let notes: String?
    let url: URL?
    
    let recurrenceRule: Recurrence?
    
}
