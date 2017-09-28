//
//  Constants.swift
//  Photo Geotags
//
//  Created by Ezekiel Elin on 8/12/16.
//  Copyright © 2016 Ezekiel Elin. All rights reserved.
//

import Foundation
import CloudKit

public let locArrayKey = "locations"
public let recordingBool = "recordingLocation"

public let container = CKContainer(identifier: "iCloud.com.ezekielelin.Photo-Geotags")
public let database = container.privateCloudDatabase
