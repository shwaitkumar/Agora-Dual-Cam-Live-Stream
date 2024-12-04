//
//  DualCamViewController.swift
//  Agora Dual Cam Live Stream
//
//  Created by Shwait Kumar on 03/12/24.
//

import UIKit
import AVFoundation
import AgoraRtcKit

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
        // Comment below line if you want to directly paste APP ID below
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: Constants.agoraAppId, delegate: self)
        /* Remove this long comment line and directly paste you APP ID in below code
         agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: "PASTE_YOUR_AGORA_APP_ID_HERE", delegate: self)
         */
        agoraKit?.enableVideo()
        agoraKit?.setExternalVideoSource(true, useTexture: false, sourceType: .videoFrame)
        print("Agora Engine initialized successfully")
    }

    func joinChannel() {
        guard let agoraKit = agoraKit else { return }
        
        let token: String? = nil // No token required
        let channelName = "TLAB4VDP1" // Ensure the same channel name is used for host and audience
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
        let isFrontCamera = (output == frontCameraOutput)
        frameHandler?(sampleBuffer, isFrontCamera)
    }
}
