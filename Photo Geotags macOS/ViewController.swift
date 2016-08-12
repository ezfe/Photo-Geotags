//
//  ViewController.swift
//  Photo Geotags macOS
//
//  Created by Ezekiel Elin on 8/12/16.
//  Copyright © 2016 Ezekiel Elin. All rights reserved.
//

import Cocoa
import CloudKit
import PhotoGeotagsKit
import MapKit

class ViewController: NSViewController {

    var records = [CKRecord]()
    var locations = [CLLocation]()
    
    @IBOutlet weak var deleteButton: NSButton!
    @IBOutlet weak var recordChooser: NSPopUpButton!
    //@IBOutlet weak var map: MKMapView!
    @IBOutlet weak var datePicker: NSDatePicker!
    @IBOutlet weak var locationLabel: NSTextField!
    
    
    let container = CKContainer(identifier: "iCloud.com.ezekielelin.Photo-Geotags")
    let database = CKContainer(identifier: "iCloud.com.ezekielelin.Photo-Geotags").privateCloudDatabase
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshRecords()
        
        // Do any additional setup after loading the view.
    }
    
    func updateUI() {
        if records.count > 0 {
            recordChooser.removeAllItems()
            recordChooser.addItems(withTitles: records.map({ (record) -> String in
                return record["Name"] as! String
            }))
            recordChooser.isEnabled = true
            deleteButton.isEnabled = true
        } else {
            recordChooser.removeAllItems()
            recordChooser.addItem(withTitle: "No records...")
            recordChooser.isEnabled = false
            deleteButton.isEnabled = false
        }
        
        self.recordUpdate(self)
        self.dateChanged(self)
    }
    
    func refreshRecords() {
        self.records.removeAll()
        
        let truePredicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "LocationHistory", predicate: truePredicate)
        
        deleteButton.isEnabled = false
        
        recordChooser.removeAllItems()
        recordChooser.addItem(withTitle: "Loading...")
        recordChooser.isEnabled = false
        
        database.perform(query, inZoneWith: nil) { (records, error) in
            guard let records = records else {
                print(error?.localizedDescription)
                DispatchQueue.main.async { self.updateUI() }
                return
            }
            
            if records.count == 0 {
                print("No records...")
            } else {
                self.records = records
            }
            DispatchQueue.main.async { self.updateUI() }
        }
    }
    
    func selectedRecord() -> CKRecord? {
        let index = recordChooser.indexOfSelectedItem
        if records.count <= index || records.count == 0 {
            return nil
        }
        return records[index]
    }
    
    @IBAction func recordUpdate(_ sender: AnyObject) {
        guard let record = selectedRecord() else {
            return
        }
        
        self.locations = Converter.locations(data: record["Data"] as! Data)
    }
    
    @IBAction func deleteCurrentRecord(_ sender: AnyObject) {
        deleteButton.isEnabled = false
        recordChooser.isEnabled = false
        
        let index = recordChooser.indexOfSelectedItem
        if records.count <= index || records.count == 0 {
            return
        }
        let record = records[index]

        database.delete(withRecordID: record.recordID) { (recordID, error) in
            
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Successfully deleted \(recordID!)")
            }
            
            DispatchQueue.main.async { self.refreshRecords() }
        }
    }
    
    @IBAction func refreshButtonAction(_ sender: AnyObject) {
        self.refreshRecords()
    }
    
    @IBAction func dateChanged(_ sender: AnyObject) {
        let date = datePicker.dateValue
        let location = calculateLocation(at: date, locations: locations)
        locationLabel.stringValue = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
    }
}

