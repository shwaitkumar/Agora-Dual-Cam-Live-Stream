//
//  DualCameraManager.swift
//  Agora Dual Cam Live Stream
//
//  Created by Shwait Kumar on 03/12/24.
//

import Foundation
import AVFoundation

class DualCameraManager: NSObject {
    var multiCamSession: AVCaptureMultiCamSession?
    var frontCameraOutput: AVCaptureVideoDataOutput?
    var backCameraOutput: AVCaptureVideoDataOutput?
    var frameHandler: ((CMSampleBuffer, Bool) -> Void)? // Callback for video frames

    override init() {
        super.init()
        setupMultiCamSession()
    }

    func setupMultiCamSession() {
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            print("Dual-camera setup is not supported on this device.")
            return
        }

        multiCamSession = AVCaptureMultiCamSession()

        // Setup Back Camera
        if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let backInput = try? AVCaptureDeviceInput(device: backCamera),
           multiCamSession?.canAddInput(backInput) == true {
            multiCamSession?.addInput(backInput)

            backCameraOutput = AVCaptureVideoDataOutput()
            if let backOutput = backCameraOutput, multiCamSession?.canAddOutput(backOutput) == true {
                backOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "BackCameraQueue"))
                multiCamSession?.addOutput(backOutput)
            }
        }

        // Setup Front Camera
        if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
           let frontInput = try? AVCaptureDeviceInput(device: frontCamera),
           multiCamSession?.canAddInput(frontInput) == true {
            multiCamSession?.addInput(frontInput)

            frontCameraOutput = AVCaptureVideoDataOutput()
            if let frontOutput = frontCameraOutput, multiCamSession?.canAddOutput(frontOutput) == true {
                frontOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "FrontCameraQueue"))
                multiCamSession?.addOutput(frontOutput)
            }
        }
    }

    func startSession() {
        multiCamSession?.startRunning()
    }

    func stopSession() {
        multiCamSession?.stopRunning()
    }
}

extension DualCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let isFrontCamera = (output == frontCameraOutput)
        frameHandler?(sampleBuffer, isFrontCamera)
    }
}
