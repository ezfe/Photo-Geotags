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
import CoreImage
import CoreMedia

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
        
        datePicker.timeZone = TimeZone.current
        
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
        
        datePicker.isHidden = !value
        locationLabel.isHidden = !value
    }
    
    func updateUI() {
        if records.count > 0 {
            recordChooser.removeAllItems()
            recordChooser.addItems(withTitles: records.map({ (record) -> String in
                return record["Name"] as! String
            }))
            
            /*
            if let minDate = locations.first?.timestamp, let maxDate = locations.last?.timestamp {
                
                self.datePicker.minDate = minDate
                self.datePicker.maxDate = maxDate
 
            }
             */
 
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
//        if !recordChooser.isEnabled {
//            print("Record chooser disabled, assuming no record available")
//            return nil
//        }
        
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
    
    @IBAction func loadFromPhotos(_ sender: AnyObject) {
        var script = "tell application \"Photos\""
        script += "\n\tset currentSelection to the selection"
        script += "\n\tif currentSelection is {} then error number -28"
        script += "\n\tset thisItem to item 1 of currentSelection"
        script += "\n\t(the date of thisItem) as string"
        script += "\nend tell"
        var error: NSDictionary?
        
        var date: Date
        
        if let scriptObject = NSAppleScript(source: script) {
            let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error)
            if let returnedText = output.stringValue {
                //Parse Date
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "EEEE, MMMM d, y 'at' h:mm:ss a"
                guard let parsed = dateFormatter.date(from: returnedText) else {
                    print("Unable to get date")
                    print(returnedText)
                    return
                }
                
                date = parsed
            } else if (error != nil) {
                print("error: \(error!)")
                return
            } else {
                print("error...")
                return
            }
        } else {
            print("Unable to create script")
            return
        }
        
        datePicker.dateValue = date
        dateChanged(sender)
        
        let location = calculateLocation(at: date, locations: self.locations)
        let string = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: NSPasteboard.PasteboardType.string)
        
        NSAppleScript(source: "tell application \"Photos\" to activate")!.executeAndReturnError(nil)
    }
    
    @IBOutlet weak var imageWell: NSImageCell!
    @IBAction func imageWellChange(_ sender: AnyObject) {
        //TODO: Implementation
        /*
        guard let image = imageWell.image else {
            print("No Image...")
            return
        }
        
        /* Calculate date of photo */
        var dateOpt: Date? = nil
        
        for representation in image.representations {
            if let bitmap = representation as? NSBitmapImageRep {
                
                let exif = bitmap.value(forProperty: NSImageEXIFData)
                guard let dateString = exif?["DateTimeOriginal"] as? String else {
                    print("Unable to read DateTimeOriginal")
                    print(exif)
                    return
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                guard let parsed = dateFormatter.date(from: dateString) else {
                    print("Unable to parse DateTimeOriginal as a Date object")
                    print(dateString)
                    return
                }
                
                dateOpt = parsed
            }
        }
        
        guard let date = dateOpt else {
            print("No date found")
            return
        }
        
        let location = calculateLocation(at: date, locations: locations)
        
        /* Store Location */
        
        let source = CGImageSourceCreateWithData(image.tiffRepresentation! as CFData, nil)!
        
        guard let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary? else {
            print("Unable to convert to NSDictionary")
            return
        }
        
        let metadataAsMutable = metadata.mutableCopy()
        
        let GPSDictionary = NSMutableDictionary()
        
        GPSDictionary.setValue(abs(location.coordinate.latitude), forKey: kCGImagePropertyGPSLatitude as String)
        if location.coordinate.latitude < 0 {
            GPSDictionary.setValue("S", forKey: kCGImagePropertyGPSLatitudeRef as String)
        } else {
            GPSDictionary.setValue("N", forKey: kCGImagePropertyGPSLatitudeRef as String)
        }
        
        GPSDictionary.setValue(abs(location.coordinate.longitude), forKey: kCGImagePropertyGPSLongitude as String)
        if location.coordinate.longitude < 0 {
            GPSDictionary.setValue("W", forKey: kCGImagePropertyGPSLongitudeRef as String)
        } else {
            GPSDictionary.setValue("E", forKey: kCGImagePropertyGPSLongitudeRef as String)
        }
        
        GPSDictionary.setValue(location.altitude, forKey: kCGImagePropertyGPSAltitude as String)
        GPSDictionary.setValue(0, forKey: kCGImagePropertyGPSAltitudeRef as String)
        
        metadataAsMutable.setValue(GPSDictionary, forKey: kCGImagePropertyGPSDictionary as String)
        
        let UTI = CGImageSourceGetType(source)!
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTI, 1, nil)!
        
        CGImageDestinationAddImageFromSource(destination, source, 0, metadataAsMutable as! CFDictionary)
        
        print(CGImageDestinationFinalize(destination))
        
        try! data.write(toFile: "/Users/ezekielelin/Desktop/test.jpg", options: .atomic)
         */
    }
    
    @IBAction func loadFromData(sender: Any) {
        var clipboardItems: [String] = []
        for element in NSPasteboard.general.pasteboardItems! {
            if let str = element.string(forType: .string) {
                clipboardItems.append(str)
            }
        }
        
        // Access the item in the clipboard
        let str = clipboardItems[0] // Good Morning
        
        if let data = Data(base64Encoded: str) {
            self.locations = Converter.locations(data: data)
            self.enableAll()
        } else {
            print("Failed...")
            print(str)
        }
    }
}w












