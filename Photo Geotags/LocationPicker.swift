//
//  LocationPicker.swift
//  Photo Geotags
//
//  Created by Ezekiel Elin on 8/11/16.
//  Copyright © 2016 Ezekiel Elin. All rights reserved.
//

import UIKit
import MapKit

class LocationPicker: UIViewController {

    var locations = [CLLocation]()
    @IBOutlet weak var map: MKMapView!
    
    @IBAction func close(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func calculateLocation(at date: Date) {
        if locations.count == 0 { print("No data to parse"); return }
        
        var smallDiff = abs(locations[0].timestamp.timeIntervalSinceReferenceDate - date.timeIntervalSinceReferenceDate)
        var smallLoc = locations[0]
        
        for (i, location) in locations.enumerated() {
            let thisDifference = abs(location.timestamp.timeIntervalSinceReferenceDate - date.timeIntervalSinceReferenceDate)
            if thisDifference < smallDiff {
                smallDiff = thisDifference
                smallLoc = location
            }
        }
        
        /*
        //Where we are in relation to the nearest location
        enum Relation { case after, before, at }
        let interval = smallLoc.timestamp.timeIntervalSince(date)
        
        var relation = Relation.at
         
        if interval < 0 {
        relation = .after
        } else if interval > 0 {
        relation = .before
        }
        */
        
        outputLabel.text = "\(smallLoc.coordinate.latitude), \(smallLoc.coordinate.longitude)"
        map.centerCoordinate = smallLoc.coordinate
    }
    
    @IBOutlet weak var outputLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBAction func dateChanged(_ sender: AnyObject) {
        calculateLocation(at: datePicker.date)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        calculateLocation(at: datePicker.date)
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
