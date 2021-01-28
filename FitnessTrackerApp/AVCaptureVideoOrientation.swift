//
//  AVCaptureVideoOrientation.swift
//  FitnessTrackerApp
//
//  Created by qubsys on 28/01/2021.
//

import AVFoundation
import UIKit

//make the app rotate depending on the way the device is being held.

extension AVCaptureVideoOrientation {
    init(deviceOrientation: UIDeviceOrientation){
        switch deviceOrientation {
        case .landscapeLeft:
            self = .landscapeLeft
        case .landscapeRight:
            self = .landscapeRight
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        default:
            self = .portrait
        }
    }
}
