//
//  DualCamViewController.swift
//  Agora Dual Cam Live Stream
//
//  Created by Shwait Kumar on 03/12/24.
//

import UIKit
import AVFoundation
import AgoraRtcKit
import CoreImage

class DualCamViewController: UIViewController {
    
    // Agora Properties
    var agoraKit: AgoraRtcEngineKit?
    
    // Camera Properties
    var multiCamSession: AVCaptureMultiCamSession?
    var frontCameraOutput: AVCaptureVideoDataOutput?
    var backCameraOutput: AVCaptureVideoDataOutput?
    var frameHandler: ((CMSampleBuffer, Bool) -> Void)? // Callback for video frames
    
    // Views
    var frontCameraView: UIView!
    var backCameraView: UIView!
    
    // Status Indicators
    var statusLabel: UILabel!
    var liveIcon: UIView!
    
    // Buffers for holding frames from each camera
    var frontPixelBuffer: CVPixelBuffer?
    var backPixelBuffer: CVPixelBuffer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Request permissions and setup
        title = "Host Mode"
        
        requestPermissions { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    print("Permissions granted")
                    self?.initializeAgoraEngine()
                    self?.setupDualCameraViews()
                    self?.setupMultiCamSession()
                    self?.startDualCameraSession()
                    self?.joinChannel()
                    self?.setupStatusViews()
                    self?.updateStatus(message: "Agora Engine Initialized")
                } else {
                    print("Permissions not granted")
                }
            }
        }
    }
    
    // MARK: - Camera Setup
    
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

    func startDualCameraSession() {
        multiCamSession?.startRunning()
        setupCameraPreviews()
    }

    func stopDualCameraSession() {
        multiCamSession?.stopRunning()
    }

    func setupCameraPreviews() {
        guard let multiCamSession = multiCamSession else { return }

        // Back Camera Preview (Full Screen)
        if backCameraOutput != nil {
            let backLayer = AVCaptureVideoPreviewLayer(session: multiCamSession)
            backLayer.frame = backCameraView.bounds
            backLayer.videoGravity = .resizeAspectFill
            backCameraView.layer.addSublayer(backLayer)
        }

        // Front Camera Preview (Small Window)
        if frontCameraOutput != nil {
            let frontLayer = AVCaptureVideoPreviewLayer(session: multiCamSession)
            frontLayer.frame = frontCameraView.bounds
            frontLayer.videoGravity = .resizeAspectFill
            frontCameraView.layer.addSublayer(frontLayer)
        }
    }

    // MARK: - Agora Setup
    
    func initializeAgoraEngine() {
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: Constants.agoraAppId, delegate: self)
        agoraKit?.enableVideo()
        agoraKit?.setClientRole(.broadcaster)
        agoraKit?.setExternalVideoSource(true, useTexture: false, sourceType: .videoFrame)

        print("Agora Engine initialized successfully")
    }

    func joinChannel() {
        guard let agoraKit = agoraKit else { return }
        
        let token: String? = nil
        let channelName = "dual-cam-test"
        let uid: UInt = 12345 // Unique UID for the host

        agoraKit.joinChannel(byToken: token, channelId: channelName, info: nil, uid: uid) { (channel, uid, elapsed) in
            print("Host joined channel: \(channel) with UID: \(uid)")
        }
    }

    // MARK: - Status Views
    
    func setupDualCameraViews() {
        backCameraView = UIView(frame: self.view.bounds)
        backCameraView.backgroundColor = .black
        self.view.addSubview(backCameraView)

        frontCameraView = UIView(frame: CGRect(x: 20, y: 120, width: 150, height: 200))
        frontCameraView.backgroundColor = .gray
        frontCameraView.layer.cornerRadius = 8
        frontCameraView.layer.masksToBounds = true
        self.view.addSubview(frontCameraView)
    }

    func setupStatusViews() {
        // Status Label
        statusLabel = UILabel()
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.boldSystemFont(ofSize: 16)
        statusLabel.textColor = .white
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        statusLabel.isHidden = true
        self.view.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            statusLabel.heightAnchor.constraint(equalToConstant: 40),
            statusLabel.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        // Live Icon
        liveIcon = UIView()
        liveIcon.backgroundColor = .red
        liveIcon.layer.cornerRadius = 20
        liveIcon.isHidden = true
        self.view.addSubview(liveIcon)
        liveIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            liveIcon.widthAnchor.constraint(equalToConstant: 100),
            liveIcon.heightAnchor.constraint(equalToConstant: 40),
            liveIcon.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            liveIcon.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        // Add "LIVE" Label
        let liveLabel = UILabel()
        liveLabel.text = "LIVE"
        liveLabel.textColor = .white
        liveLabel.font = UIFont.boldSystemFont(ofSize: 16)
        liveLabel.textAlignment = .center
        liveIcon.addSubview(liveLabel)
        liveLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            liveLabel.centerXAnchor.constraint(equalTo: liveIcon.centerXAnchor),
            liveLabel.centerYAnchor.constraint(equalTo: liveIcon.centerYAnchor)
        ])
    }
    
    func updateStatus(message: String, hideAfter seconds: Double = 3.0) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
            self.statusLabel.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                self.statusLabel.isHidden = true
                self.liveIcon.isHidden = false
            }
        }
    }

    // MARK: - Permissions
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else { completion(false); return }
            AVCaptureDevice.requestAccess(for: .audio) { completion($0) }
        }
    }
    
}

// MARK: - Agora Delegate

extension DualCamViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("Did join channel: \(channel) with UID: \(uid)")
        let partialUid = "\(uid)".prefix(2) + "XXX"
        updateStatus(message: "Agora ID: \(partialUid)")
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("Remote user joined with UID: \(uid)")
        updateStatus(message: "Remote user joined")
    }
}

// MARK: - Camera Delegate

extension DualCamViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get pixel buffer")
            return
        }

        // Determine which camera the frame is from and store the buffer
        if output == frontCameraOutput {
            frontPixelBuffer = pixelBuffer
        } else if output == backCameraOutput {
            backPixelBuffer = pixelBuffer
        }

        // Ensure both buffers are available before merging
        guard let frontBuffer = frontPixelBuffer, let backBuffer = backPixelBuffer else { return }

        // Merge frames and push to Agora
        if let mergedBuffer = mergeFrames(frontBuffer: frontBuffer, backBuffer: backBuffer) {
            pushMergedFrameToAgora(mergedBuffer)
        }
    }
    
    private func mergeFrames(frontBuffer: CVPixelBuffer, backBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let ciContext = CIContext()

        // Convert buffers to CIImages
        let frontImage = CIImage(cvPixelBuffer: frontBuffer)
        let backImage = CIImage(cvPixelBuffer: backBuffer)

        // Get dimensions of the back camera frame (base layer)
        let width = CVPixelBufferGetWidth(backBuffer)
        let height = CVPixelBufferGetHeight(backBuffer)

        // Scale and position the front camera overlay
        let resizedFrontImage = frontImage.transformed(by: CGAffineTransform(scaleX: CGFloat(width) / 2.5 / frontImage.extent.width,
                                                                             y: CGFloat(height) / 2.3 / frontImage.extent.height))
        let frontTransform = CGAffineTransform(translationX: 20, y: (CGFloat(height) / 2) + 20)

        // Apply the transform to position the front camera
        let positionedFrontImage = resizedFrontImage.transformed(by: frontTransform)

        // Correct compositing: Place front camera on top of back camera
        let overlayedImage = positionedFrontImage.composited(over: backImage)

        // Create a new pixel buffer for the merged frame
        var mergedBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attributes as CFDictionary, &mergedBuffer)

        // Render the overlayed image into the new pixel buffer
        if let mergedBuffer = mergedBuffer {
            ciContext.render(overlayedImage, to: mergedBuffer)
        }

        return mergedBuffer
    }

    private func pushMergedFrameToAgora(_ mergedBuffer: CVPixelBuffer) {
        let videoFrame = AgoraVideoFrame()
        videoFrame.format = 12 // NV12 format
        videoFrame.textureBuf = mergedBuffer
        videoFrame.rotation = 90 // Adjust rotation for portrait orientation

        agoraKit?.pushExternalVideoFrame(videoFrame)
    }
}
