//
//  File.swift
//  Photo Geotags
//
//  Created by Ezekiel Elin on 8/12/16.
//  Copyright © 2016 Ezekiel Elin. All rights reserved.
//

import Foundation
import CoreLocation

public func calculateLocation(at date: Date, locations: [CLLocation]) -> CLLocation {
    if locations.count == 0 { assert(false); return CLLocation() }
    
    var smallDiff = abs(locations[0].timestamp.timeIntervalSinceReferenceDate - date.timeIntervalSinceReferenceDate)
    var smallLoc = locations[0]
    
    for (_, location) in locations.enumerated() {
        let thisDifference = abs(location.timestamp.timeIntervalSinceReferenceDate - date.timeIntervalSinceReferenceDate)
        if thisDifference < smallDiff {
            smallDiff = thisDifference
            smallLoc = location
        }
    }
    
    return smallLoc
}
