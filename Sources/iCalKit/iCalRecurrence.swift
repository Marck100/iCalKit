//
//  iCalRecurrence.swift
//  
//
//  Created by Marco Pilloni on 07/05/2020.
//

import UIKit

public enum iCalRecurrenceFrequency: Int {
    case daily = 0
    case weekly = 1
    case monthly = 2
    case yearly = 3
    init?(text: String) {
        switch text {
        case "daily":
            self = .daily
        case "weekly":
            self = .weekly
        case "monthly":
            self = .monthly
        case "yearly":
            self = .yearly
        default:
            return nil
        }
    }
}
public enum iCalWeekday: Int {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    init?(string: String) {
        switch string {
        case "SU":
            self = .sunday
        case "MO":
            self = .monday
        case "TU":
            self = .tuesday
        case "WE":
            self = .wednesday
        case "TH":
            self = .thursday
        case "FR":
            self = .friday
        case "SA":
            self = .saturday
        default:
            return nil
        }
    }
}

public struct iCalRecurrenceDayOfTheWeek {
    var dayOfTheWeek: iCalWeekday
    var weekNumber: Int
}

public struct iCalRecurrenceEnd {
    var endDate: Date?
    var occurrenceCount: Int
}

public struct iCalRecurrenceRule {
    var frequency: iCalRecurrenceFrequency
    var interval: Int
    
    var daysOfTheWeek: [iCalRecurrenceDayOfTheWeek]?
    var daysOfTheMonth: [NSNumber]?
    var monthsOfTheYear: [NSNumber]?
    var weeksOfTheYear: [NSNumber]?
    var daysOfTheYear: [NSNumber]?
    
    var setPositions: [NSNumber]?
    var end: iCalRecurrenceEnd?
}
