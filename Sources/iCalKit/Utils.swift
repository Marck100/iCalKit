//
//  Utils.swift
//  
//
//  Created by Marco Pilloni on 17/07/2020.
//

import Foundation

extension Date {
    func to(timeZone outputTimeZone: TimeZone, from inputTimeZone: TimeZone) -> Date {
         let delta = TimeInterval(outputTimeZone.secondsFromGMT(for: self) - inputTimeZone.secondsFromGMT(for: self))
         return addingTimeInterval(delta)
    }
}

extension TimeZone {
    static let abbreviationDictionary_v2: [String: String] = {
        var dictionary = TimeZone.abbreviationDictionary
        dictionary["RM"] = "Europe/Rome"
        return dictionary
    }()
}
