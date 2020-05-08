//
//  File.swift
//  
//
//  Created by Marco Pilloni on 07/05/2020.
//

import UIKit

public struct Recurrence {
    
    public enum Frequency: String {
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
    
    public let frequency: Frequency
    public let interval: Int
    public let daysOfTheWeek: [NSNumber]?
    public let daysOfTheMonth: [NSNumber]?
    public let daysOfTheYear: [NSNumber]?
    public let monthsOfTheYear: [NSNumber]?
    public let weeksOfTheYear: [NSNumber]?
    public let end: Date?
    
}
