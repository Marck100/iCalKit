//
//  File.swift
//  
//
//  Created by Marco Pilloni on 07/05/2020.
//

import Foundation


extension iCal {
    
    func parseRule(_ rule: String, startDate: Date) -> iCalRecurrenceRule? {
      
        let params = rule.components(separatedBy: ";")
        guard let frequencyValue = getValue(fromLines: params, key: "FREQ", separator: "=")?.lowercased(), let frequency = iCalRecurrenceFrequency(text: frequencyValue) else { return nil }
        let interval: Int = {
            guard let interval = getValue(fromLines: params, key: "INTERVAL", separator: "=") else { return 1 }
            return Int(interval) ?? 1
        }()
        let end: iCalRecurrenceEnd? = {
            if let value = getValue(fromLines: params, key: "COUNT", separator: "="), let count = Int(value)  {
                return iCalRecurrenceEnd(endDate: nil, occurrenceCount: count)
            } else if let date = getValue(fromLines: params, key: "UNTIL") {
                let date = toDate(date, withTimeZone: nil)
                return iCalRecurrenceEnd(endDate: date, occurrenceCount: 0)
            } else {
                return nil
            }
        }()
        let daysOfTheWeek: [iCalRecurrenceDayOfTheWeek]? = {
            guard let daysLiteral = getValue(fromLines: params, key: "BYDAY", separator: "=") else { return nil }
            let days = daysLiteral.components(separatedBy: ",")
            return days.compactMap { (string) -> iCalRecurrenceDayOfTheWeek? in
                guard let weekday = iCalWeekday(string: String(string.suffix(2))) else { return nil }
                let weekNumber = Int(string.dropLast(2)) ?? 0
                return iCalRecurrenceDayOfTheWeek(dayOfTheWeek: weekday, weekNumber: weekNumber)
            }
        }()
        let daysOfTheMonth: [NSNumber]? = {
            guard let daysLiteral = getValue(fromLines: params, key: "BYMONTHDAY", separator: "=") else { return nil }
            let days = daysLiteral.components(separatedBy: ",")
            return days.compactMap({ Int($0) }) as [NSNumber]
        }()
        let weeksOfTheYear: [NSNumber]? = {
            guard let weeksLiteral = getValue(fromLines: params, key: "BYWEEKNO", separator: "=") else { return nil }
            let weeks = weeksLiteral.components(separatedBy: ",")
            return weeks.compactMap({ Int($0) }) as [NSNumber]
        }()
        let monthsOfTheYear: [NSNumber]? = {
            guard let monthsLiteral = getValue(fromLines: params, key: "BYMONTH=", separator: "=") else { return nil }
            let months = monthsLiteral.components(separatedBy: ",")
            return months.compactMap({ Int($0) }) as [NSNumber]
        }()
        let daysOfTheYear: [NSNumber]? = {
            guard let daysLiteral = getValue(fromLines: params, key: "BYYEARDAY", separator: "=") else { return nil }
            let days = daysLiteral.components(separatedBy: ",")
            return days.compactMap({ Int($0) }) as [NSNumber]
        }()
        let setPositions: [NSNumber]? = {
            guard let setPositions = getValue(fromLines: params, key: "BYSETPOS", separator: "=") else { return nil }
            let positions = setPositions.components(separatedBy: ",")
            return positions.compactMap { NSNumber(pointer: $0) }
        }()
        
        return iCalRecurrenceRule(frequency: frequency, interval: interval, daysOfTheWeek: daysOfTheWeek, daysOfTheMonth: daysOfTheMonth, monthsOfTheYear: monthsOfTheYear, weeksOfTheYear: weeksOfTheYear, daysOfTheYear: daysOfTheYear, setPositions: setPositions, end: end)
        
    }
    
    private func toDate(startDate: Date, frequency: iCalRecurrenceFrequency, interval: Int, count: Int) -> Date {
        
        let singleTimeInterval: TimeInterval = {
            switch frequency {
            case .daily:
                return 60 * 60 * 24
            case .weekly:
                return 60 * 60 * 24 * 7
            case .monthly:
                return 60 * 60 * 24 * 31
            case .yearly:
                return 60 * 60 * 24 * 365
            }
        }()
        
        let timeInterval: TimeInterval = singleTimeInterval * Double(interval * count)
        
        return Date(timeInterval: timeInterval, since: startDate)
        
    }
    
}

extension Array where Element == NSNumber {
    
    static fileprivate let weekDays: [NSNumber] = [1, 2, 3, 4, 5, 6, 7]
    
}

extension Date {
    var dayOfTheYear: Int {
        let calendar = Calendar.current
        let day = calendar.ordinality(of: .day, in: .year, for: self)!
        return day
    }
    var monthOfTheYear: Int {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: self)
        return month
    }
    var dayOfTheMonth: Int {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: self)
        return day
    }
}

