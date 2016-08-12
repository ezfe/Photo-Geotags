//
//  PhotoEditingViewController.swift
//  Update Location
//
//  Created by Ezekiel Elin on 8/12/16.
//  Copyright © 2016 Ezekiel Elin. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

import MapKit

import PhotoGeotagsKit

class PhotoEditingViewController: UIViewController, PHContentEditingController {

    var input: PHContentEditingInput?
    
    var locations = [CLLocation]()
    
    let defaults = UserDefaults(suiteName: "group.com.ezekielelin.photogeotags")!
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var image: UIImageView!
    
    @IBAction func cancelAction(_ sender: AnyObject) {
        
        
    }
    
    @IBAction func updateLocation(_ sender: AnyObject) {
        guard let input = input else { return }
        
        let location = calculateLocation(at: input.creationDate!, locations: self.locations)
        
        map.centerCoordinate = location.coordinate
        map.region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        
        let image = UIImage(contentsOfFile: input.fullSizeImageURL!.absoluteString)
        image
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let locData = defaults.data(forKey: locArrayKey), let locarr = NSKeyedUnarchiver.unarchiveObject(with: locData) as? [CLLocation] {
            self.locations = locarr
        } else {
            print("No data found in UserDefaults")
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - PHContentEditingController
    
    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        // Inspect the adjustmentData to determine whether your extension can work with past edits.
        // (Typically, you use its formatIdentifier and formatVersion properties to do this.)
        return false
    }
    
    func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: UIImage) {
        // Present content for editing, and keep the contentEditingInput for use when closing the edit session.
        // If you returned true from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
        // If you returned false, the contentEditingInput has past edits "baked in".
        input = contentEditingInput
        
        image.image = placeholderImage
    }
    
    func finishContentEditing(completionHandler: ((PHContentEditingOutput?) -> Void)) {
        // Update UI to reflect that editing has finished and output is being rendered.
        
        // Render and provide output on a background queue.
        DispatchQueue.global().async {
            // Create editing output from the editing input.
            let output = PHContentEditingOutput(contentEditingInput: self.input!)
            
            // Provide new adjustments and render output to given location.
            // output.adjustmentData = <#new adjustment data#>
            // let renderedJPEGData = <#output JPEG#>
            // renderedJPEGData.writeToURL(output.renderedContentURL, atomically: true)
            
            // Call completion handler to commit edit to Photos.
            completionHandler(output)
            
            // Clean up temporary files, etc.
        }
    }
    
    var shouldShowCancelConfirmation: Bool {
        // Determines whether a confirmation to discard changes should be shown to the user on cancel.
        // (Typically, this should be "true" if there are any unsaved changes.)
        return false
    }
    
    func cancelContentEditing() {
        // Clean up temporary files, etc.
        // May be called after finishContentEditingWithCompletionHandler: while you prepare output.
    }

}
