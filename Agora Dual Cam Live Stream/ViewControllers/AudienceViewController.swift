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
        self.title = "Audience Mode"

        // Initialize the Agora engine and join the channel
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
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: Constants.agoraAppId, delegate: self)
        agoraKit?.setClientRole(.audience) // Set the role to audience
        agoraKit?.enableVideo() // Enable video
        print("Agora Engine initialized successfully")
    }

    func joinChannelAsAudience() {
        guard let agoraKit = agoraKit else { return }

        let token: String? = nil
        let channelName: String = "dual-cam-test" // Match the channel name with the host
        let uid: UInt = 67890 // Unique UID for the audience

        agoraKit.joinChannel(byToken: token, channelId: channelName, info: nil, uid: uid) { (channel, uid, elapsed) in
            print("Audience joined channel: \(channel) with UID: \(uid)")
        }
    }

    // MARK: - UI Setup

    func setupRemoteVideoView() {
        // Create a single remote video view
        remoteVideoView = UIView()
        remoteVideoView.backgroundColor = .black
        self.view.addSubview(remoteVideoView)
    }
}

// MARK: - Agora Delegate

extension AudienceViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("Host joined channel with UID: \(uid)")

        // Set up the remote video for the merged stream
        setupRemoteVideo(for: uid)
    }

    private func setupRemoteVideo(for uid: UInt) {
        guard let agoraKit = agoraKit else { return }

        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = remoteVideoView // Single merged stream rendered in fullscreen
        videoCanvas.renderMode = .fit

        agoraKit.setupRemoteVideo(videoCanvas)
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
