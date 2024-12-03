# Agora Dual Cam Live Stream

## Overview
The **Agora Dual Cam Live Stream** app allows users to live stream video using both the front and back cameras simultaneously. The app leverages **Agora’s real-time video SDK** and Apple's **AVCaptureMultiCamSession** to provide seamless dual-camera streaming. It features:

- **Full-screen Back Camera**: The back camera occupies the full screen during the live stream.
- **Front Camera in Picture-in-Picture Mode**: The front camera is displayed in a smaller overlay at the top-left corner.
- A smooth and user-friendly design, making it ideal for streaming use cases like tutorials, interviews, or real-time broadcasting.

---

## Setting Up the Project

To run this project, you need to set up the `Constants.swift` file to include your **Agora App ID**.

### Steps:
1. Locate the file `Constants.sample.swift` in the `HelperClasses` folder.
2. Make a copy of the file and rename it to `Constants.swift`.
3. Open the `Constants.swift` file and replace `"YOUR_APP_ID_HERE"` with your actual Agora App ID.

```swift
struct Constants {
    static let agoraAppId = "YOUR_APP_ID_HERE"
}
