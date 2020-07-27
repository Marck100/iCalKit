import Foundation
import CoreLocation

final public class iCal {
    
    private enum iCalError: Error {
        case invalidPath, invalidData, invalidResult
    }
    
    private let calendarNameKey = "X-WR-CALNAME"
    private let eventStartKey = "BEGIN:VEVENT"
    private let eventEndKey = "END:VEVENT"
    private let eventNameKey = "SUMMARY"
    private let eventStartDate = "DTSTART"
    private let eventEndDate = "DTEND"
    private let eventLocation = "LOCATION"
    private let eventNotes = "DESCRIPTION"
    private let eventURL = "URL"
    private let eventRecurrenceRule = "RRULE"
    private let eventID = "UID"
    private let eventAlert = "TRIGGER"
    private let eventExcludation = "EXDATE"
    
    static public let shared = iCal()
    
    
    /// Load calendar from URL
    /// - Parameters:
    ///   - path: URL path
    ///   - loadEvents: Load calendar's events or not
    ///   - completionHandler: Includes loaded calendar and errors
    public func loadCalendar(withPath path: String, loadEvents: Bool = true, completionHandler: @escaping(iCalCalendar?, Error?) -> Void) {
        guard let url = URL(string: path) else {
            completionHandler(nil, iCalError.invalidPath)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            guard let data = data, let text = String(data: data, encoding: .utf8) else {
                completionHandler(nil, iCalError.invalidData)
                return
            }
            
            self.extractCalendar(fromText: text, loadEvents: loadEvents) { (calendar) in
                completionHandler(calendar, calendar == nil ? iCalError.invalidResult : nil)
            }
            
        }
        
        task.resume()
        
    }
    
    public func loadCalendar(withLocal path: String, loadEvents: Bool = true, completionHandler: @escaping(iCalCalendar?, Error?) -> Void) {
        
        do {
            let text = try String(contentsOfFile: path)
            self.extractCalendar(fromText: text, loadEvents: loadEvents) { (calendar) in
                completionHandler(calendar, calendar == nil ? iCalError.invalidResult : nil)
            }
        } catch let error {
            completionHandler(nil, error)
        }
        
    }
    
    
    private func extractCalendar(fromText text: String, loadEvents: Bool = true, completionHandler: @escaping(iCalCalendar?) -> Void) {
       
        let dispatchGroup = DispatchGroup()
        var lines = text.components(separatedBy: "\n")
        
        guard let calendarName = getValue(fromLines: lines, key: calendarNameKey) else {
            completionHandler(nil)
            return
        }
        guard loadEvents == true else {
            let calendar = iCalCalendar(name: calendarName, events: [])
            completionHandler(calendar)
            return
        }
        
        for line in lines {
            if line.contains(eventStartKey) {
                break
            }
            lines.removeFirst()
        }
        
        var events: [iCalEvent] = []
        
        while let endLine = lines.firstIndex(where: { $0.contains(eventEndKey) }) {
            dispatchGroup.enter()
            
            let currentLines = Array(lines.prefix(endLine))
            
            let startTimeZone: TimeZone? = {
                guard let string = getValue(fromLines: lines, key: eventStartDate, getLast: false)?.split(separator: ";").last else { return nil }
                return getTimeZone(String(string))
            }()
            let endTimeZone: TimeZone? = {
                guard let string = getValue(fromLines: lines, key: eventEndDate, getLast: false)?.split(separator: ";").last else { return nil }
                return getTimeZone(String(string))
            }()
            
            let excludationDates: [Date] = {
                var dates: [Date] = []
                for line in getItems(withKey: eventExcludation, lines: lines) {
                    if let date = getExcludationDate(lines: [line]) {
                        dates.append(date)
                    }
                }
                return dates
            }()
            
            if let id = getValue(fromLines: currentLines, key: eventID),let name = getValue(fromLines: lines, key: eventNameKey), let startDateLiteral = getValue(fromLines: lines, key: eventStartDate), let startDate = toDate(startDateLiteral, withTimeZone: startTimeZone), let endDateLiteral = getValue(fromLines: lines, key: eventEndDate), let endDate = toDate(endDateLiteral, withTimeZone: endTimeZone) {
            
                let recurrenceRule: iCalRecurrenceRule? = {
                    if let rule = getValue(fromLines: currentLines, key: eventRecurrenceRule) {
                        return parseRule(rule, startDate: startDate)
                    } else {
                        return nil
                    }
                }()
                let notes = getValue(fromLines: currentLines, key: eventNotes)?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                let url: URL? = {
                    if let path = getValue(fromLines: currentLines, key: eventURL) {
                        return URL(string: path)
                    } else {
                        return nil
                    }
                }()
                
                let alertOffset: TimeInterval? = {
                    guard var alertValue = getValue(fromLines: currentLines, key: eventAlert) else { return nil }
                    guard alertValue.prefix(3) == "-PT" else { return nil }
                    let moltiplicator: TimeInterval = {
                        switch alertValue.last {
                        case "M":
                            return 60
                        case "H":
                            return 3600
                        default:
                            return 0
                        }
                    }()
                    alertValue.removeFirst(3)
                    alertValue.removeLast()
                    guard let interval = TimeInterval(alertValue) else { return nil }
                
                    return interval * moltiplicator
                }()
                
                if let locationLiteral = getValue(fromLines: currentLines, key: eventLocation) {
                    
                    CLGeocoder().geocodeAddressString(locationLiteral) { (placemarks, error) in
                       
                        let location = placemarks?.first?.location
                        
                        events.append(iCalEvent(identifier: id, name: name, startDate: startDate, endDate: endDate, location: location, notes: notes, url: url, recurrenceRule: recurrenceRule, alertOffset: alertOffset, excludationDates: excludationDates))
                        
                        dispatchGroup.leave()
                    }
                    
                } else {
                    
                    events.append(iCalEvent(identifier: id, name: name, startDate: startDate, endDate: endDate, location: nil, notes: notes, url: url, recurrenceRule: recurrenceRule, alertOffset: alertOffset, excludationDates: excludationDates))
                    
                    dispatchGroup.leave()
                   
                }
               
            }
            for _ in 0...endLine {
                lines.removeFirst()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completionHandler(iCalCalendar(name: calendarName, events: events))
        }
        
    }
    
    private func getItems(withKey key: String, lines: [String]) -> [String] {
        return lines.filter { $0.hasPrefix(key) }
    }
    
    private func getExcludationDate(lines: [String]) -> Date? {
        let excludationTimeZone: TimeZone? = {
            guard let string = getValue(fromLines: lines, key: eventExcludation, getLast: false)?.split(separator: ";").last else { return nil }
            return getTimeZone(String(string))
        }()
        let excludationDate: Date? = {
            guard let string = getValue(fromLines: lines, key: eventExcludation) else { return nil }
            return toDate(string, withTimeZone: excludationTimeZone)
        }()
        return excludationDate
    }
    
    func getValue(fromLines lines: [String], key: String, separator: Character = ":", getLast: Bool = true) -> String? {
      
        guard let index = lines.firstIndex(where: {$0.contains("\(key)")}) else { return nil }
        let string = lines[index]
        
        let value = getLast == true ? string.split(separator: separator).last :  string.split(separator: separator).first
      
        return value?.replacingOccurrences(of: "\r", with: "")
        
    }
    
    internal func getTimeZone(_ string: String) -> TimeZone? {
        
        let string = string.replacingOccurrences(of: "TZID=", with: "")
        let abbreviationDictionary = TimeZone.abbreviationDictionary_v2
       
        if let abbreviation = abbreviationDictionary.first(where: { $0.value == string})?.key {
            return TimeZone(abbreviation: abbreviation)
        } else if let secondAbbreviation = abbreviationDictionary.first(where: { $0.value.split(separator: "/").first == string.split(separator: "/").first })?.key {
            return TimeZone(abbreviation: secondAbbreviation)
        } else {
            return nil
        }
        
    }
    
    internal func toDate(_ string: String, withTimeZone timeZone: TimeZone?) -> Date? {
        var finalString = string.replacingOccurrences(of: "T", with: "").replacingOccurrences(of: "Z", with: "")
       
        let year = Int(finalString.prefix(4))
        if year != nil {
            finalString.removeFirst(4)
        }
        let month = Int(finalString.prefix(2))
        if month != nil {
            finalString.removeFirst(2)
        }
        let day = Int(finalString.prefix(2))
        if day != nil {
            finalString.removeFirst(2)
        }
        let hour = Int(finalString.prefix(2))
        if hour != nil {
            finalString.removeFirst(2)
        }
        let minute = Int(finalString.prefix(2))
        if minute != nil {
            finalString.removeFirst(2)
        }
        let second = Int(finalString)

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        
        guard let date = Calendar.current.date(from: components) else { return nil }
        
        if components.hour != nil {
            let newZone = timeZone ?? TimeZone(abbreviation: "GMT")!
            let currentTimeZone = TimeZone.current
            return date.to(timeZone: currentTimeZone, from: newZone)
        } else {
            return date
        }
    }
    
}

