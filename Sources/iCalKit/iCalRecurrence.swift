//
//  File.swift
//  
//
//  Created by Marco Pilloni on 07/05/2020.
//

import UIKit

public struct Recurrence {
    
    enum Frequency: String {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case yearly = "yearly"
    }
    
    enum Day: String {
        case sunday = "SU"
        case monday = "MO"
        case tuesday = "TU"
        case wednesday = "WE"
        case thursday = "TH"
        case friday = "FR"
        case saturday = "SA"
        
        var weekday: Int {
            switch self {
            case .sunday:
                return 1
            case .monday:
                return 2
            case .tuesday:
                return 3
            case .wednesday:
                return 4
            case .thursday:
                return 5
            case .friday:
                return 6
            case .saturday:
                return 7
            }
        }
    }
    
    let frequency: Frequency
    let interval: Int
    let daysOfTheWeek: [NSNumber]?
    let daysOfTheMonth: [NSNumber]?
    let daysOfTheYear: [NSNumber]?
    let monthsOfTheYear: [NSNumber]?
    let weeksOfTheYear: [NSNumber]?
    let end: Date?
    
}
