//
//  LocationPicker.swift
//  Photo Geotags
//
//  Created by Ezekiel Elin on 8/11/16.
//  Copyright © 2016 Ezekiel Elin. All rights reserved.
//

import UIKit
import MapKit
import CloudKit


class LocationPicker: UIViewController {

    var locations = [CLLocation]()
    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var secondPicker: UISlider!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var coordinateLabel: UILabel!
    
    @IBAction func share(sender: UIButton) {
        let data = Converter.locations(locations: self.locations)
        let str = data.base64EncodedString()
        
        let vc = UIActivityViewController(activityItems: [str as NSString], applicationActivities: nil)
        present(vc, animated: true, completion: nil)
    
    }
    
    @IBAction func close(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func updateLocation(at date: Date) {
        let coords = calculateLocation(at: date, locations: locations)
        
        coordinateLabel.text = "\(coords.coordinate.latitude), \(coords.coordinate.longitude)"
        map.centerCoordinate = coords.coordinate
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coords.coordinate
        annotation.title = coords.timestamp.description(with: Locale.current)
        
        map.removeAnnotations(map.annotations)
        map.addAnnotation(annotation)
        
        map.region = MKCoordinateRegion(center: coords.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
    }
    
    @IBAction func dateChanged(_ sender: AnyObject) {
        var date = datePicker.date
        date.addTimeInterval(Double(secondPicker.value))
        dateLabel.text = date.description(with: Locale.current)
        updateLocation(at: date)
        
        print(date.description(with: Locale.current))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let first = locations.first, let last = locations.last else {
            print("No first/last")
            return
        }
        
        datePicker.minimumDate = first.timestamp
        datePicker.maximumDate = last.timestamp
        
        dateChanged(self)
        
        let truePredicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "LocationHistory", predicate: truePredicate)
        
        database.perform(query, inZoneWith: nil) { (records, error) in            
            guard let records = records else {
                print(error?.localizedDescription ?? "Unknown error")
                return
            }
            
            if records.count == 0 {
                print("No records received")
            } else {
                for record in records {
                let locations = Converter.locations(data: record["Data"] as? Data)
                let date = Date()
                
                let location = calculateLocation(at: date, locations: locations)
                let string = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
                
                print(string)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
