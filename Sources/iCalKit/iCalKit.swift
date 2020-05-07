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
            guard let calendar = self.extractCalendar(fromText: text) else {
                completionHandler(nil, iCalError.invalidResult)
                return
            }
            
            completionHandler(calendar, nil)
            
        }
        
        task.resume()
        
    }
    
    private func extractCalendar(fromText text: String) -> iCalCalendar? {
        
        let dispatchGroup = DispatchGroup()
        
        var lines = text.components(separatedBy: "\n")
        guard let calendarName = getValue(fromLines: lines, key: calendarNameKey) else { return nil }
        var events: [iCalEvent] = []
        
        while let endLine = lines.firstIndex(where: { $0.contains(eventEndKey) }) {
            if let name = getValue(fromLines: lines, key: eventNameKey), let startDateLiteral = getValue(fromLines: lines, key: eventStartDate), let startDate = toDay(startDateLiteral), let endDateLiteral = getValue(fromLines: lines, key: eventEndDate), let endDate = toDay(endDateLiteral) {
                
                let recurrenceRule: Recurrence? = {
                    if let rule = getValue(fromLines: lines, key: eventRecurrenceRule) {
                        return parseRule(rule, startDate: startDate)
                    } else {
                        return nil
                    }
                }()
                let notes = getValue(fromLines: lines, key: eventNotes)
                let url: URL? = {
                    if let path = getValue(fromLines: lines, key: eventURL) {
                        return URL(string: path)
                    } else {
                        return nil
                    }
                }()
                
                var location: CLLocation?
                
                if let locationLiteral = getValue(fromLines: lines, key: eventLocation) {
                    dispatchGroup.enter()
                    CLGeocoder().geocodeAddressString(locationLiteral) { (placemarks, error) in
                        location = placemarks?.first?.location
                        dispatchGroup.leave()
                    }
                    
                }
                
                events.append(iCalEvent(name: name, startDate: startDate, endDate: endDate, location: location, notes: notes, url: url, recurrenceRule: recurrenceRule))
                
            }
            for _ in 0...endLine {
                lines.removeFirst()
            }
        }
        
        return iCalCalendar(name: calendarName, events: events)
        
    }
    
    func getValue(fromLines lines: [String], key: String) -> String? {
        guard let index = lines.firstIndex(where: {$0.contains(key)}) else { return nil }
     
        let string = lines[index]
        let value = string.split(separator: ":").last
        return value == nil ? nil : String(value!)
        
    }
    
    func toDay(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        
        return formatter.date(from: string)
    }
    
}

