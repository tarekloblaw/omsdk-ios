import Foundation
import UIKit
import OMSDK_Loblawca

public final class OMIDSessionManager {
    public enum CreativeKind {
        case nativeDisplay
        case nativeVideo
        case nativeAudio
    }

    private var adSession: OMIDLoblawcaAdSession?
    private var adEvents: OMIDLoblawcaAdEvents?
    private var mediaEvents: OMIDLoblawcaMediaEvents?

    private weak var mainAdView: UIView?
    private let creativeKind: CreativeKind

    public init(creativeKind: CreativeKind, mainAdView: UIView?) {
        self.creativeKind = creativeKind
        self.mainAdView = mainAdView
    }

    public func startSession(vendorKey: String, verificationScriptURL: String, verificationParameters: String) {
        NSLog("@@ Starting session with vendorKey: \(vendorKey), scriptURL: \(verificationScriptURL), params: \(verificationParameters)")

        if !OMIDLoblawcaSDK.shared.isActive {
            OMIDLoblawcaSDK.shared.activate()
        }

        guard OMIDLoblawcaSDK.shared.isActive else {
            NSLog("@@ OMSDK not active, cannot start session")
            return
        }

        NSLog("@@ About to create AdSessionContext")

        guard let context = createAdSessionContext(vendorKey: vendorKey,
                                                   verificationScriptURL: verificationScriptURL,
                                                   verificationParameters: verificationParameters) else {
            NSLog("@@ Failed to create AdSessionContext")
            return
        }

        let configuration = createAdSessionConfiguration()

        do {
            let session = try OMIDLoblawcaAdSession(configuration: configuration, adSessionContext: context)
            if creativeKind != .nativeAudio, let adView = mainAdView {
                session.mainAdView = adView
            }
            adSession = session

            do {
                adEvents = try OMIDLoblawcaAdEvents(adSession: session)
                NSLog("@@ adEvents created successfully")
            } catch {
                NSLog("@@ adEvents creation failed: \(error)")
            }

            if creativeKind == .nativeVideo || creativeKind == .nativeAudio {
                do {
                    mediaEvents = try OMIDLoblawcaMediaEvents(adSession: session)
                    NSLog("@@ mediaEvents created successfully")
                } catch {
                    NSLog("@@ mediaEvents creation failed: \(error)")
                }
            }

            NSLog("@@ starting session")
            session.start()
            NSLog("@@ session started")

            NSLog("@@ Session state after start - mainAdView: \(session.mainAdView != nil ? "set" : "nil")")
            NSLog("@@ Session configuration - creativeType: \(configuration.creativeType), impressionType: \(configuration.impressionType)")

        } catch {
            NSLog("@@ session failed to start: \(error)")
        }
    }

    public func fireAdLoaded() {
        NSLog("@@ ad loaded")
        try? adEvents?.loaded()
    }

    public func fireImpression() {
        NSLog("@@ impressionOccured")

        guard let adEvents = adEvents else {
            NSLog("@@ impressionOccured failed: adEvents is nil")
            return
        }

        do {
            try adEvents.impressionOccurred()
            NSLog("@@ impressionOccurred called successfully")
        } catch {
            NSLog("@@ impressionOccured failed: \(error)")
        }
    }

    public func finish() {
        NSLog("@@ finish")
        adSession?.finish()
        adSession = nil
        adEvents = nil
        mediaEvents = nil
    }

    private func createAdSessionConfiguration() -> OMIDLoblawcaAdSessionConfiguration {
        switch creativeKind {
        case .nativeDisplay:
            return try! OMIDLoblawcaAdSessionConfiguration(
                creativeType: .nativeDisplay,
                impressionType: .viewable,
                impressionOwner: .nativeOwner,
                mediaEventsOwner: .noneOwner,
                isolateVerificationScripts: true
            )
        case .nativeVideo:
            return try! OMIDLoblawcaAdSessionConfiguration(
                creativeType: .video,
                impressionType: .beginToRender,
                impressionOwner: .nativeOwner,
                mediaEventsOwner: .nativeOwner,
                isolateVerificationScripts: false
            )
        case .nativeAudio:
            return try! OMIDLoblawcaAdSessionConfiguration(
                creativeType: .audio,
                impressionType: .audible,
                impressionOwner: .nativeOwner,
                mediaEventsOwner: .nativeOwner,
                isolateVerificationScripts: false
            )
        }
    }

    private func createAdSessionContext(vendorKey: String,
                                        verificationScriptURL: String,
                                        verificationParameters: String) -> OMIDLoblawcaAdSessionContext? {
        var resources: [OMIDLoblawcaVerificationScriptResource] = []

        guard let scriptURL = URL(string: verificationScriptURL) else {
            NSLog("@@ Failed to create verification resource: Invalid URL")
            return nil
        }

        let resource = OMIDLoblawcaVerificationScriptResource(url: scriptURL,
                                                              vendorKey: vendorKey,
                                                              parameters: verificationParameters)
        resources.append(resource!)
        NSLog("@@ Resource created and appended")

        do {
            let context = try OMIDLoblawcaAdSessionContext(
                partner: OMIDPartnerCache.shared.partner,
                script: OMIDPartnerCache.shared.omidJSService,
                resources: resources,
                contentUrl: nil,
                customReferenceIdentifier: nil
            )
            NSLog("@@ AdSessionContext created successfully with \(resources.count) verification resources")
            return context
        } catch {
            NSLog("@@ Failed to create AdSessionContext: \(error)")
            return nil
        }
    }
}

// MARK: - Partner and JS service cache

final class OMIDPartnerCache {
    static let shared = OMIDPartnerCache()

    private init() {}

    lazy var partner: OMIDLoblawcaPartner = {
        let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1.0"
        return OMIDLoblawcaPartner(name: "Loblaw", versionString: version)!
    }()

    var omidJSService: String {
        guard let url = Bundle.module.url(forResource: "omsdk-v1", withExtension: "js"),
              let jsContent = try? String(contentsOf: url) else {
            fatalError("omsdk-v1.js not found in package resources")
        }

        print("@@ OMSDK JS loaded from package: \(url.lastPathComponent), length: \(jsContent.count)")
        return jsContent
    }
}
