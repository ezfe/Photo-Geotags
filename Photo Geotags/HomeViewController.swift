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
    
    //TODO: Revert this to UserDefaults.default
    let defaults = UserDefaults(suiteName: "group.com.ezekielelin.photogeotags")!
    
    var locations = [CLLocation]() {
        didSet {
            map.removeOverlays(map.overlays)
            
            if locations.count > 0 {
                let points = locations.map { (location) -> CLLocationCoordinate2D in
                    return location.coordinate
                }
                
                let polyline = MKPolyline(coordinates: points, count: points.count)
                map.add(polyline)
                
                let data = Converter.locations(locations: self.locations)
                defaults.set(data, forKey: locArrayKey)
            } else {
                print("No locations, nothing to draw")
            }
            
        }
    }
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.map.delegate = self
        
        self.locations = Converter.locations(data: defaults.data(forKey: locArrayKey))
 
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

        let locationData = Converter.locations(locations: self.locations)
        let count = Double(locationData.count)
        let message: String
        if count < 1000 {
            message = "\(count) B"
        } else if count < 1000000 {
            message = "\(count/1000) KB"
        } else {
            message = "\(count/1000) MB"
        }
        
        let alert = UIAlertController(title: "Enter Upload Name", message: "This upload will be \(message).\n\nYou will need to choose from a list of your past uploads, so you should use a unique identifying title.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (_) in
            let record = CKRecord(recordType: "LocationHistory")
            
            record.setValue(locationData, forKey: "Data")
            record.setValue(alert.textFields?[0].text ?? "Untitled", forKey: "Name")
            
            database.save(record) { (record, error) in
                guard let _ = record else {
                    print(error?.localizedDescription)
                    return
                }
                
                print("Uploaded record...")
                
                DispatchQueue.main.async {
                    self.locations.removeAll()
                    
                    self.uploadStatus.stopAnimating()
                    self.uploadButton.isHidden = false
                    
                    let confirmAlert = UIAlertController(title: "Uploaded", message: "Your locations were successfully uploaded", preferredStyle: .alert)
                    confirmAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(confirmAlert, animated: true, completion: nil)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            
            DispatchQueue.main.async {
                self.uploadStatus.stopAnimating()
                self.uploadButton.isHidden = false
            }
            
            print("Canceled")
        }))
        alert.addTextField(configurationHandler: nil)
        self.present(alert, animated: true, completion: nil)
    }
}
