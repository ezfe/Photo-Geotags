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

class HomeViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var record: UISwitch!
    
    var locations = [CLLocation]() {
        didSet {
            if locations.count == 0 { return }
            
            let points = locations.map { (location) -> CLLocationCoordinate2D in
                return location.coordinate
            }
            
            map.removeOverlays(map.overlays)
            let polyline = MKPolyline(coordinates: points, count: points.count)
            map.add(polyline)
        }
    }
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.map.delegate = self
        
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.activityType = .other
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locations.append(contentsOf: locations)
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
        if record.isOn {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.stopUpdatingLocation()
        }
    }
}
