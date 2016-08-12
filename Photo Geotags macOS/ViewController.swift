//
//  ViewController.swift
//  Photo Geotags macOS
//
//  Created by Ezekiel Elin on 8/12/16.
//  Copyright © 2016 Ezekiel Elin. All rights reserved.
//

import Cocoa
import CloudKit

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let database = CKContainer.default().privateCloudDatabase
        
        let truePredicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "LocationHistory", predicate: truePredicate)
        
        database.perform(query, inZoneWith: nil) { (records, error) in
            guard let records = records else {
                print(error?.localizedDescription)
                return
            }
            
            
            
        }
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

