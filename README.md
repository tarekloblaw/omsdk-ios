# OMSDK Swift Package

A Swift Package Manager wrapper for the OMSDK (Open Measurement SDK) static framework.

## Overview

This package provides a clean Swift Package Manager interface for integrating OMSDK into your iOS and tvOS applications. OMSDK enables measurement and verification of digital advertising.

## Requirements

- iOS 12.0+
- tvOS 12.0+
- Xcode 14.0+
- Swift 5.7+

## Installation

### Swift Package Manager

Add this package to your project using Xcode:

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/yourorg/omsdk.git`
3. Choose the version rule and add the package
4. Add `OMSDK` to your target dependencies

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourorg/omsdk.git", from: "1.0.0")
]
```

## Usage

### Basic Setup

```swift
import OMSDK

class AdManager {
    func setupOMSDK() {
        // Activate the SDK
        let sdk = OMIDLoblawcaSDK.shared
        let activated = sdk.activate()
        
        if activated {
            print("OMSDK activated successfully")
            print("OMSDK version: \(OMIDLoblawcaSDK.versionString())")
        } else {
            print("Failed to activate OMSDK")
        }
    }
}
```

### Creating an Ad Session

```swift
import OMSDK
import UIKit

class AdViewController: UIViewController {
    private var adSession: OMIDAdSession?
    private var adEvents: OMIDAdEvents?
    
    func createAdSession(for adView: UIView) {
        do {
            // Create partner
            let partner = try OMIDPartner(name: "YourPartnerName", versionString: "1.0.0")
            
            // Create context (without verification scripts for basic usage)
            let context = try OMIDAdSessionContext(partner: partner, verificationScriptResources: [])
            
            // Create configuration
            let config = try OMIDAdSessionConfiguration(
                creativeType: .nativeDisplay,
                impressionType: .viewable,
                impressionOwner: .nativeOwner,
                mediaEventsOwner: .none,
                isolateVerificationScripts: false
            )
            
            // Create session
            adSession = try OMIDAdSession(configuration: config, adSessionContext: context)
            
            // Set main ad view
            try adSession?.setMainAdView(adView)
            
            // Create ad events
            adEvents = try OMIDAdEvents(adSession: adSession!)
            
            // Start session
            try adSession?.start()
            
            print("OMSDK ad session created and started successfully")
            
        } catch {
            print("Failed to create OMSDK ad session: \(error)")
        }
    }
    
    func fireAdLoadedEvent() {
        do {
            try adEvents?.loaded()
            print("Ad loaded event fired")
        } catch {
            print("Failed to fire ad loaded event: \(error)")
        }
    }
    
    func fireImpressionEvent() {
        do {
            try adEvents?.impression()
            print("Impression event fired")
        } catch {
            print("Failed to fire impression event: \(error)")
        }
    }
    
    deinit {
        adSession?.finish()
    }
}
```

### With Verification Scripts (DoubleVerify, etc.)

```swift
func createAdSessionWithVerification(for adView: UIView, scriptURL: String, parameters: String?) {
    do {
        let partner = try OMIDPartner(name: "YourPartnerName", versionString: "1.0.0")
        
        // Create verification script resource
        let scriptResource = try OMIDVerificationScriptResource(
            url: URL(string: scriptURL)!,
            vendorKey: nil,
            parameters: parameters
        )
        
        let context = try OMIDAdSessionContext(
            partner: partner,
            verificationScriptResources: [scriptResource]
        )
        
        // Continue with session creation...
        
    } catch {
        print("Failed to create ad session with verification: \(error)")
    }
}
```

## Key Classes

- **OMIDLoblawcaSDK**: Main SDK class for activation and version info
- **OMIDAdSession**: Represents an ad measurement session
- **OMIDAdEvents**: Used to fire ad lifecycle events
- **OMIDPartner**: Represents the integration partner
- **OMIDVerificationScriptResource**: For third-party verification scripts
- **OMIDAdSessionConfiguration**: Configuration for ad sessions
- **OMIDAdSessionContext**: Context containing partner and verification info

## Best Practices

1. **Always activate the SDK** before creating any sessions
2. **Create sessions on the main thread** - OMSDK requires main thread usage
3. **Finish sessions** when ads are no longer visible or the view is deallocated
4. **Handle errors gracefully** - All OMSDK methods can throw exceptions
5. **Set the main ad view** before starting the session

## Troubleshooting

### Common Issues

1. **"OMSDK not activated"**: Call `OMIDLoblawcaSDK.shared.activate()` before using other APIs
2. **Threading issues**: Ensure all OMSDK calls are made on the main thread
3. **Session not starting**: Verify the main ad view is set before calling `start()`

### Debug Logging

OMSDK includes internal logging. To see debug information, you can check the console for OMSDK-related messages.

## License

This package wraps the OMSDK static framework. Please refer to the OMSDK license terms for usage rights and restrictions.

## Support

For OMSDK-specific questions, refer to the official OMSDK documentation.
For package-related issues, please open an issue in this repository.
