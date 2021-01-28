//
//  ViewController.swift
//  FitnessTrackerApp
//
//  Created by qubsys on 27/01/2021.
//

import UIKit
import Vision

class ViewController: UIViewController {

    override func viewDidLoad() {
        
        //link storyboard elements to the code
        @IBOutlet weak var movementLabel: UILabel!
        
        @IBOutlet weak var previewImageView: UIImageView!
        
        //call videoCapture Class from other file
        private let videoCapture = VideoCapture()
        
        //declare image size and initially set image size to zero
        var imageSize = CGSize.zero
        
        
        
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}



