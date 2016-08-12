//
//  HomeViewController.swift
//  Photo Geotags
//
//  Created by Ezekiel Elin on 7/28/16.
//  Copyright © 2016 Ezekiel Elin. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import CloudKit

import PhotoGeotagsKit

class HomeViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var record: UISwitch!
    
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var uploadStatus: UIActivityIndicatorView!
    
    let defaults = UserDefaults(suiteName: "group.com.ezekielelin.photogeotags")!
    
    var locations = [CLLocation]() {
        didSet {
            if locations.count == 0 { return }
            
            let points = locations.map { (location) -> CLLocationCoordinate2D in
                return location.coordinate
            }
            
            map.removeOverlays(map.overlays)
            let polyline = MKPolyline(coordinates: points, count: points.count)
            map.add(polyline)
            
            let data = NSKeyedArchiver.archivedData(withRootObject: locations)
            defaults.set(data, forKey: locArrayKey)
        }
    }
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.map.delegate = self
        
        if let locData = defaults.data(forKey: locArrayKey), let locarr = NSKeyedUnarchiver.unarchiveObject(with: locData) as? [CLLocation] {
            self.locations = locarr
        } else {
            //Save, duplicate code
            let data = NSKeyedArchiver.archivedData(withRootObject: locations)
            defaults.set(data, forKey: locArrayKey)
        }
 
        self.record.isOn = defaults.bool(forKey: recordingBool)
        
        defaults.bool(forKey: recordingBool)
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.activityType = .other
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            if defaults.bool(forKey: recordingBool) {
                locationManager.startUpdatingLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let adding = locations.first else {
            return
        }
        
        if let last = self.locations.last {
            let latdiff = abs(last.coordinate.latitude - adding.coordinate.latitude)
            let londiff = abs(last.coordinate.longitude - adding.coordinate.longitude)
            
            if latdiff > 0.00005 || londiff > 0.00005 {
                self.locations.append(adding)
            }
        } else {
            self.locations.append(adding)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 4.0
        return renderer
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destination as? LocationPicker {
            destination.locations = self.locations
        }
    }
    
    @IBAction func switchSwitch(_ sender: AnyObject) {
        defaults.set(record.isOn, forKey: recordingBool)
        if record.isOn {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.stopUpdatingLocation()
        }
    }
    
    @IBAction func upload(_ sender: AnyObject) {
        uploadButton.isHidden = true
        uploadStatus.startAnimating()
        
        let privateDB = CKContainer.default().privateCloudDatabase
        
        
        let truePredicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "LocationHistory", predicate: truePredicate)
        
        privateDB.perform(query, inZoneWith: nil) { (records, error) in
            
            guard let records = records else { print(error?.localizedDescription); return }
            
            let record: CKRecord
            
            if records.count == 0 {
                record = CKRecord(recordType: "LocationHistory")
            } else {
                record = records[0]
            }
            
            
            record.setValue(NSKeyedArchiver.archivedData(withRootObject: self.locations), forKey: "Data")
            privateDB.save(record) { (record, error) in
                guard let _ = record else {
                    print(error?.localizedDescription)
                    return
                }
                print("Uploaded record...")
                
                self.uploadStatus.stopAnimating()
                self.uploadButton.isHidden = false
            }
        }
    }
}
