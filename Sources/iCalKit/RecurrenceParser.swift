//
//  File.swift
//  
//
//  Created by Marco Pilloni on 07/05/2020.
//

import Foundation


extension iCal {
    
    func parseRule(_ rule: String, startDate: Date) -> Recurrence? {
        
        let params = rule.components(separatedBy: ";")
        guard let frequencyValue = getValue(fromLines: params, key: "FREQ", separator: "=")?.lowercased(), let frequency = Recurrence.Frequency(rawValue: frequencyValue) else { return nil }
        let interval: Int = {
            guard let interval = getValue(fromLines: params, key: "INTERVAL", separator: "=") else { return 1 }
            return Int(interval) ?? 1
        }()
        let count: Int? = {
            guard let count = getValue(fromLines: params, key: "COUNT", separator: "=") else { return nil }
            return Int(count)
        }()
        let until: Date? = {
            if let untilLiteral = getValue(fromLines: params, key: "UNTIL", separator: "=") {
                return toDate(untilLiteral)
            } else if let count = count {
                return toDate(startDate: startDate, frequency: frequency, interval: interval, count: count - 1)
            } else {
                return nil
            }
            
        }()
        let daysOfTheWeek: [NSNumber]? = {
            guard let daysLiteral = getValue(fromLines: params, key: "BYDAY", separator: "=") else { return frequency == .daily ? [NSNumber].weekDays : nil }
            let days = daysLiteral.components(separatedBy: ",")
            return days.compactMap { (string) -> NSNumber? in
                var string = string.replacingOccurrences(of: "\r", with: "")
                guard let weekDay = Recurrence.Day(rawValue: String(string.suffix(2)))?.weekday else { return nil }
                string.removeLast(2)
                return weekDay * (Int(string) ?? 1) as NSNumber
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
            guard let daysLiteral = getValue(fromLines: params, key: "BYYEARDAY", separator: "=") else { return frequency == .year ? startDate.dayOfTheYear :  nil }
            let days = daysLiteral.components(separatedBy: ",")
            return days.compactMap({ Int($0) }) as [NSNumber]
        }()
        
        return Recurrence(frequency: frequency, interval: interval, daysOfTheWeek: daysOfTheWeek, daysOfTheMonth: daysOfTheMonth, daysOfTheYear: daysOfTheYear, monthsOfTheYear: monthsOfTheYear, weeksOfTheYear: weeksOfTheYear, end: until)
        
    }
    
    private func toDate(startDate: Date, frequency: Recurrence.Frequency, interval: Int, count: Int) -> Date {
        
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
        let day = calendar.ordinality(of: .day, in: .year, for: self)
    }
}

