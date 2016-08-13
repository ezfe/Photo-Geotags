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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshRecords()
        
        // Do any additional setup after loading the view.
    }
    
    ///Remove all records from the popup, set a custom title, and disableAll()
    func pauseUI(chooserMessage: String) {
        recordChooser.removeAllItems()
        recordChooser.addItem(withTitle: chooserMessage)
        
        disableAll()
    }
    
    /**Disable all relevant UI elements
     Reverses, and can be reversed by, enableAll()*/
    func disableAll() {
        setIsEnabled(false)
    }
    
    /**Enable all relevant UI elements
    Reverses, and can be reversed by, disableAll()*/
    func enableAll() {
        setIsEnabled(true)
    }
    
    func setIsEnabled(_ value: Bool) {
        recordChooser.isEnabled = value
        deleteButton.isEnabled = value
    }
    
    func updateUI() {
        if records.count > 0 {
            recordChooser.removeAllItems()
            recordChooser.addItems(withTitles: records.map({ (record) -> String in
                return record["Name"] as! String
            }))
            
            if let minDate = locations.first?.timestamp, let maxDate = locations.last?.timestamp {
                self.datePicker.minDate = minDate
                self.datePicker.maxDate = maxDate
            }
            
            enableAll()
        } else {
            pauseUI(chooserMessage: "No records...")
        }
        
        self.recordUpdate(self)
        self.dateChanged(self)
    }
    
    func refreshRecords() {
        self.records.removeAll()
        
        let truePredicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "LocationHistory", predicate: truePredicate)
        
        pauseUI(chooserMessage: "Loading...")
        
        database.perform(query, inZoneWith: nil) { (records, error) in
            defer {
                DispatchQueue.main.async { self.updateUI() }
            }
            
            guard let records = records else {
                print(error?.localizedDescription ?? "Unknown error")
                return
            }
            
            if records.count == 0 {
                print("No records received")
            } else {
                self.records = records
            }
        }
    }
    
    ///Returns the selected record, or nil
    func selectedRecord() -> CKRecord? {
        if !recordChooser.isEnabled {
            print("Record chooser disabled, assuming no record available")
            return nil
        }
        
        let index = recordChooser.indexOfSelectedItem
        if records.count <= index || records.count == 0 {
            return nil
        }
        return records[index]
    }
    
    ///Update the locations array
    @IBAction func recordUpdate(_ sender: AnyObject) {
        guard let record = selectedRecord() else {
            return
        }
        
        self.locations = Converter.locations(data: record["Data"] as? Data)
    }
    
    @IBAction func deleteCurrentRecord(_ sender: AnyObject) {
        disableAll()
        
        guard let record = selectedRecord() else {
            print("No record selected, unable to delete")
            return
        }

        database.delete(withRecordID: record.recordID) { (recordID, error) in
            
            guard let recordID = recordID else {
                print(error?.localizedDescription ?? "Unknown error")
                return
            }

            print("Successfully deleted \(recordID.recordName)")
            
            DispatchQueue.main.async { self.refreshRecords() }
        }
    }
    
    @IBAction func refreshButtonAction(_ sender: AnyObject) {
        self.refreshRecords()
    }
    
    ///Update the location label
    @IBAction func dateChanged(_ sender: AnyObject) {
        let date = datePicker.dateValue
        let location = calculateLocation(at: date, locations: locations)
        locationLabel.stringValue = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
    }
}

