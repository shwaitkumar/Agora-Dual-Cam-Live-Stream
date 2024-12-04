//
//  AudienceViewController.swift
//  Agora Dual Cam Live Stream
//
//  Created by Shwait Kumar on 04/12/24.
//

import UIKit
import AgoraRtcKit

class AudienceViewController: UIViewController {
    var agoraKit: AgoraRtcEngineKit?
    var remoteVideoView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the UI and Agora engine
        self.title = "Audience Mode"
        initializeAgoraEngine()
        setupRemoteVideoView()
        joinChannelAsAudience()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Ensure the remote video view resizes properly
        remoteVideoView.frame = self.view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Leave the channel and clean up
        agoraKit?.leaveChannel(nil)
        agoraKit = nil
        print("Left channel and cleaned up Agora engine.")
    }

    // MARK: - Agora Setup

    func initializeAgoraEngine() {
        // Initialize Agora engine with APP ID
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: Constants.agoraAppId, delegate: self)

        // Set audience mode
        agoraKit?.setClientRole(.audience)

        // Enable logging for debugging
        agoraKit?.setLogFile(NSTemporaryDirectory() + "agora_audience.log")
        agoraKit?.setLogFilter(AgoraLogFilter.info.rawValue)

        print("Agora Engine initialized for audience.")
    }

    func joinChannelAsAudience() {
        guard let agoraKit = agoraKit else { return }

        let token: String? = nil // No token required
        let channelName: String = "TLAB4VDP1" // Same channel name as the host
        let uid: UInt = 67890 // Unique UID for the audience

        agoraKit.joinChannel(byToken: token, channelId: channelName, info: nil, uid: uid) { (channel, uid, elapsed) in
            print("Audience joined channel: \(channel) with UID: \(uid)")
        }
    }

    // MARK: - UI Setup

    func setupRemoteVideoView() {
        // Create a UIView to render the remote video (full screen)
        remoteVideoView = UIView(frame: self.view.bounds)
        remoteVideoView.backgroundColor = .gray
        self.view.addSubview(remoteVideoView)
    }
}

// MARK: - Agora Delegate

extension AudienceViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("Host joined with UID: \(uid)")
        
        DispatchQueue.main.async {
            self.setupRemoteVideo(for: uid)
        }
    }

    // Setup remote video
    private func setupRemoteVideo(for uid: UInt) {
        guard let agoraKit = agoraKit else { return }

        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = self.remoteVideoView
        videoCanvas.renderMode = .fit

        // Clean up any existing layers
        self.remoteVideoView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        agoraKit.setupRemoteVideo(videoCanvas)

        print("Remote video setup for UID: \(uid)")
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("Agora Error: \(errorCode.rawValue) - \(errorCode)")
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didConnectionLost reason: Int) {
        print("Connection lost with reason: \(reason)")
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didClientRoleChanged oldRole: AgoraClientRole, newRole: AgoraClientRole) {
        print("Client role changed from \(oldRole) to \(newRole)")
    }
}
