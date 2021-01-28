//
//  VideoCapture.swift
//  FitnessTrackerApp
//
//  Created by qubsys on 27/01/2021.
//

import AVFoundation
import CoreVideo
import UIKit
import VideoToolbox

protocol  VideoCaptureDelegate: AnyObject {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame image: CGImage?)
    func videoCaptureBuffer(_ videoCapture: VideoCapture, didCaptureBuffer buffer: CMSampleBuffer)
}

class VideoCapture: NSObject {
    enum VideoCaptureError: Error{
        case captureSessionIsMissing
        case invalidInput
        case invalidOutput
        case unknown
    }
    
    weak var delegate: VideoCaptureDelegate?
    
    //An object that manages capture activity and coordinates the flow of data from input devices to capture outputs.
    let captureSession = AVCaptureSession()
    
    //A capture output that records video and provides access to video frames for processing.
    let videoOutput = AVCaptureVideoDataOutput()
    
    //A device that provides input in this case video, for capture sessions and offers controls for hardware-specific capture features. Also setting the position of this to the front camera
    private(set) var cameraPosition = AVCaptureDevice.Position.front
    
    
    private let sessionQueue = DispatchQueue(label: "Movement Estimation Session Queue")
    
    
    //flip camera function
    public func flipCamera(completion: @escaping (Error?) -> Void) {
        sessionQueue.async {
            
            do {
                self.cameraPosition = self.cameraPosition == .back ? .front : .back
                
                //Camera changes to be made atomically.
                self.captureSession.beginConfiguration()
                
                try self.setCaptureSessionInput()
                try self.setCaptureSessionOutput()
                
                self.captureSession.commitConfiguration()
                
                DispatchQueue.main.async {
                    completion(nil)
                }
            }catch {
                DispatchQueue.main.async {
                    completion(error)
                }
                
            }
        }
    }
    
    //Set up AVCapture Error Handler
    public func setUpAVCapture(completion: @escaping (Error?) -> Void) {
        sessionQueue.async {
            do {
                try self.setUpAVCapture()
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    //Set up Same AVCapture Function for no Error
    private func setUpAVCapture() throws {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }

        captureSession.beginConfiguration()

        captureSession.sessionPreset = .vga640x480

        try setCaptureSessionInput()

        try setCaptureSessionOutput()

        captureSession.commitConfiguration()
    }

    
    private func setCaptureSessionInput() throws {

        guard let captureDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: AVMediaType.video,
            position: cameraPosition) else {
                throw VideoCaptureError.invalidInput
        }

        captureSession.inputs.forEach { input in
            captureSession.removeInput(input)
        }

        
        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            throw VideoCaptureError.invalidInput
        }

        guard captureSession.canAddInput(videoInput) else {
            throw VideoCaptureError.invalidInput
        }

        captureSession.addInput(videoInput)
    }

    private func setCaptureSessionOutput() throws {
        captureSession.outputs.forEach { output in
            captureSession.removeOutput(output)
        }

        // Discard new frames that arrive while the dispatch queue is already busy with an older frame.
        
        videoOutput.alwaysDiscardsLateVideoFrames = true

        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)

        guard captureSession.canAddOutput(videoOutput) else {
            throw VideoCaptureError.invalidOutput
        }

        captureSession.addOutput(videoOutput)

        // Update the video orientation
        if let connection = videoOutput.connection(with: .video),
            connection.isVideoOrientationSupported {
            connection.videoOrientation =
                AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation)
            connection.isVideoMirrored = cameraPosition == .front

            // Inverse the landscape orientation to force the image in the upward
            // orientation.
            if connection.videoOrientation == .landscapeLeft {
                connection.videoOrientation = .landscapeRight
            } else if connection.videoOrientation == .landscapeRight {
                connection.videoOrientation = .landscapeLeft
            }
        }
    }


    public func startCapturing(completion completionHandler: (() -> Void)? = nil) {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                // Invoke the startRunning method of the captureSession to start the
                // flow of data from the inputs to the outputs.
                self.captureSession.startRunning()
            }

            if let completionHandler = completionHandler {
                DispatchQueue.main.async {
                    completionHandler()
                }
            }
        }
    }


    
    public func stopCapturing(completion completionHandler: (() -> Void)? = nil) {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }

            if let completionHandler = completionHandler {
                DispatchQueue.main.async {
                    completionHandler()
                }
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {

    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        guard let delegate = delegate else { return }

        if let pixelBuffer = sampleBuffer.imageBuffer {
            guard CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly) == kCVReturnSuccess
                else {
                    return
            }

            var image: CGImage?

            VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &image)
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

            DispatchQueue.main.sync {
                delegate.videoCapture(self, didCaptureFrame: image)
                delegate.videoCaptureBuffer(self, didCaptureBuffer: sampleBuffer)
            }
        }
    }
}

    

