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
    
    var agoraKit: AgoraRtcEngineKit?
    let dualCameraManager = DualCameraManager()
    
    var frontCameraView: UIView!
    var backCameraView: UIView!
    
    var statusLabel: UILabel!
    var liveIcon: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Request permissions and setup
        requestPermissions { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    print("Permissions granted")
                    self?.initializeAgoraEngine()
                    self?.setupDualCameraViews()
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
    
    // MARK: - Helper Methods
    
    // Configure UI elements for live stream status
    func setupStatusViews() {
        // Status Label
        statusLabel = UILabel()
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.boldSystemFont(ofSize: 16)
        statusLabel.textColor = .white
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        statusLabel.isHidden = true // Initially hidden
        self.view.addSubview(statusLabel)
        
        // Enable Auto Layout for statusLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            statusLabel.heightAnchor.constraint(equalToConstant: 40),
            statusLabel.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        // Live Icon
        liveIcon = UIView()
        liveIcon.backgroundColor = UIColor.red
        liveIcon.layer.cornerRadius = 20
        liveIcon.isHidden = true // Initially hidden

        let liveLabel = UILabel()
        liveLabel.text = "LIVE"
        liveLabel.textColor = .white
        liveLabel.font = UIFont.boldSystemFont(ofSize: 16)
        liveLabel.textAlignment = .center
        liveIcon.addSubview(liveLabel)

        // Enable Auto Layout for liveIcon
        liveIcon.translatesAutoresizingMaskIntoConstraints = false
        liveLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(liveIcon)

        NSLayoutConstraint.activate([
            liveIcon.widthAnchor.constraint(equalToConstant: 100),
            liveIcon.heightAnchor.constraint(equalToConstant: 40),
            liveIcon.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            liveIcon.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            // Center liveLabel inside liveIcon
            liveLabel.centerXAnchor.constraint(equalTo: liveIcon.centerXAnchor),
            liveLabel.centerYAnchor.constraint(equalTo: liveIcon.centerYAnchor)
        ])
    }
    
    func updateStatus(message: String, hideAfter seconds: Double = 3.0) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.statusLabel.text = message
            self.statusLabel.isHidden = false

            // Hide after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                self.statusLabel.isHidden = true
                self.liveIcon.isHidden = false // Show the live icon
            }
        }
    }

    // Configure Agora Engine
    func initializeAgoraEngine() {
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: Constants.agoraAppId, delegate: self)
        agoraKit?.enableVideo()
        agoraKit?.setExternalVideoSource(true, useTexture: false, sourceType: .videoFrame)
        print("Agora Engine initialized successfully")
    }

    func joinChannel() {
        guard let agoraKit = agoraKit else {
            print("AgoraKit not initialized")
            return
        }
        let token: String? = nil
        let channelName = "dual_camera_test"

        agoraKit.joinChannel(byToken: token, channelId: channelName, info: nil, uid: 0) { (channel, uid, elapsed) in
            print("Joined channel: \(channel) with UID: \(uid)")
        }
    }

    // Configure Dual Camera Views
    func setupDualCameraViews() {
        // Full-screen view for back camera
        backCameraView = UIView(frame: self.view.bounds)
        backCameraView.backgroundColor = .black
        self.view.addSubview(backCameraView)

        // Smaller view for front camera, positioned at the top-left corner
        let width: CGFloat = 150
        let height: CGFloat = 200
        let x: CGFloat = 20 // Padding from the left
        let y: CGFloat = 50 // Padding from the top
        frontCameraView = UIView(frame: CGRect(x: x, y: y, width: width, height: height))
        frontCameraView.backgroundColor = .gray
        frontCameraView.layer.cornerRadius = 8
        frontCameraView.layer.masksToBounds = true
        self.view.addSubview(frontCameraView)
    }

    func startDualCameraSession() {
        dualCameraManager.frameHandler = { [weak self] sampleBuffer, isFrontCamera in
            guard let self = self, let agoraKit = self.agoraKit else { return }

            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let videoFrame = AgoraVideoFrame()
                videoFrame.format = 12 // NV12 format
                videoFrame.time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                videoFrame.textureBuf = pixelBuffer

                // Push frames separately for front and back cameras
                agoraKit.pushExternalVideoFrame(videoFrame, videoTrackId: 0)
            }
        }
        
        dualCameraManager.startSession()
        setupCameraPreviews()
    }

    func setupCameraPreviews() {
        guard let multiCamSession = dualCameraManager.multiCamSession else { return }

        // Back Camera Preview (Full Screen)
        if dualCameraManager.backCameraOutput != nil {
            let backLayer = AVCaptureVideoPreviewLayer(session: multiCamSession)
            backLayer.frame = backCameraView.bounds
            backLayer.videoGravity = .resizeAspectFill // Fill the screen
            backCameraView.layer.addSublayer(backLayer)
        }

        // Front Camera Preview (Small Window)
        if dualCameraManager.frontCameraOutput != nil {
            let frontLayer = AVCaptureVideoPreviewLayer(session: multiCamSession)
            frontLayer.frame = frontCameraView.bounds
            frontLayer.videoGravity = .resizeAspectFill // Fit the small view
            frontCameraView.layer.addSublayer(frontLayer)
        }
    }

    // Handle Camera persmission
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            print("Camera access: \(granted)")
            if !granted {
                completion(false)
                return
            }
            AVCaptureDevice.requestAccess(for: .audio) { audioGranted in
                print("Microphone access: \(audioGranted)")
                completion(audioGranted)
            }
        }
    }
    
}

// MARK: - AgoraRTCEngine Delegate

extension DualCamViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("Did join channel: \(channel) with UID: \(uid)")
        let partialUid = "\(uid)".prefix(2) + "XXX" // Show partial ID
        updateStatus(message: "Agora ID: \(partialUid)")
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("Remote user joined with UID: \(uid)")
        updateStatus(message: "Remote user joined")
    }
}
