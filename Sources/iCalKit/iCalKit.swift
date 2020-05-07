import Foundation
import CoreLocation

final public class iCal {
    
    private let calendarNameKey = "X-WR-CALNAME"
    private let eventEndKey = "END:VEVENT"
    private let eventNameKey = "SUMMARY"
    private let eventStartDate = "DTSTART"
    private let eventEndDate = "DTEND"
    private let eventLocation = "LOCATION"
    private let eventNotes = "DESCRIPTION"
    private let eventURL = "URL"
    private let eventRecurrenceRule = "RRULE"
    
    private enum iCalError: Error {
        case invalidPath, invalidData, invalidResult
    }
    
    static public let shared = iCal()
    
    public func loadCalendar(withPath path: String, completionHandler: @escaping( iCalCalendar?, Error?) -> Void) {
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
            
            self.extractCalendar(fromText: text) { (calendar) in
                if let calendar = calendar {
                    completionHandler(calendar, nil)
                } else {
                    completionHandler(nil, iCalError.invalidResult)
                }
            }
            
        }
        
        task.resume()
        
    }
    
    private func extractCalendar(fromText text: String, completionHandler: @escaping(iCalCalendar?) -> Void) {
        
        let dispatchGroup = DispatchGroup()
        
        var lines = text.components(separatedBy: "\n")
        guard let calendarName = getValue(fromLines: lines, key: calendarNameKey) else {
            completionHandler(nil)
            return
        }
        var events: [iCalEvent] = []
        
        while let endLine = lines.firstIndex(where: { $0.contains(eventEndKey) }) {
            
            dispatchGroup.enter()
            if let name = getValue(fromLines: lines, key: eventNameKey), let startDateLiteral = getValue(fromLines: lines, key: eventStartDate), let startDate = toDate(startDateLiteral), let endDateLiteral = getValue(fromLines: lines, key: eventEndDate), let endDate = toDate(endDateLiteral) {
               
                let recurrenceRule: Recurrence? = {
                    if let rule = getValue(fromLines: lines, key: eventRecurrenceRule) {
                        return parseRule(rule, startDate: startDate)
                    } else {
                        return nil
                    }
                }()
                let notes = getValue(fromLines: lines, key: eventNotes)?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                let url: URL? = {
                    if let path = getValue(fromLines: lines, key: eventURL) {
                        return URL(string: path)
                    } else {
                        return nil
                    }
                }()
                
                var location: CLLocation?
                
                if let locationLiteral = getValue(fromLines: lines, key: eventLocation) {
                    
                    CLGeocoder().geocodeAddressString(locationLiteral) { (placemarks, error) in
                       
                        location = placemarks?.first?.location
                        
                        events.append(iCalEvent(name: name, startDate: startDate, endDate: endDate, location: location, notes: notes, url: url, recurrenceRule: recurrenceRule))
                        
                        dispatchGroup.leave()
                    }
                    
                } else {
                    
                    events.append(iCalEvent(name: name, startDate: startDate, endDate: endDate, location: location, notes: notes, url: url, recurrenceRule: recurrenceRule))
                    
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
    
    func getValue(fromLines lines: [String], key: String) -> String? {
        guard let index = lines.firstIndex(where: {$0.contains(key)}) else { return nil }
     
        let string = lines[index]
        let value = string.split(separator: ":").last
        return value == nil ? nil : String(value!)
        
    }
    
    func toDate(_ string: String) -> Date? {
        var finalString = string.replacingOccurrences(of: "T", with: "").replacingOccurrences(of: "Z", with: "")
        
        let year = Int(finalString.prefix(4))
        finalString.removeFirst(4)
        let month = Int(finalString.prefix(2))
        finalString.removeFirst(2)
        let day = Int(finalString.prefix(2))
        finalString.removeFirst(2)
        let hour = Int(finalString.prefix(2))
        finalString.removeFirst(2)
        let minute = Int(finalString.prefix(2))
        finalString.removeFirst(2)
        let second = Int(finalString)
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        
        return Calendar.current.date(from: components)
    }
    
}

