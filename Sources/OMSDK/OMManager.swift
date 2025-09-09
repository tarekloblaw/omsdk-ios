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
        omsdkLog("Starting session with vendorKey: \(vendorKey), scriptURL: \(verificationScriptURL), params: \(verificationParameters)")

        if !OMIDLoblawcaSDK.shared.isActive {
            OMIDLoblawcaSDK.shared.activate()
        }

        guard OMIDLoblawcaSDK.shared.isActive else {
            omsdkLog("OMSDK not active, cannot start session")
            return
        }

        omsdkLog("About to create AdSessionContext")

        guard let context = createAdSessionContext(vendorKey: vendorKey,
                                                   verificationScriptURL: verificationScriptURL,
                                                   verificationParameters: verificationParameters) else {
            omsdkLog("Failed to create AdSessionContext")
            return
        }

        guard let configuration = createAdSessionConfiguration() else {
            omsdkLog("Failed to create AdSessionConfiguration")
            return
        }

        do {
            let session = try OMIDLoblawcaAdSession(configuration: configuration, adSessionContext: context)
            if creativeKind != .nativeAudio, let adView = mainAdView {
                session.mainAdView = adView
            }
            adSession = session

            do {
                adEvents = try OMIDLoblawcaAdEvents(adSession: session)
                omsdkLog("adEvents created successfully")
            } catch {
                omsdkLog("adEvents creation failed: \(error)")
            }

            if creativeKind == .nativeVideo || creativeKind == .nativeAudio {
                do {
                    mediaEvents = try OMIDLoblawcaMediaEvents(adSession: session)
                    omsdkLog("mediaEvents created successfully")
                } catch {
                    omsdkLog("mediaEvents creation failed: \(error)")
                }
            }

            omsdkLog("starting session")
            session.start()
            omsdkLog("session started")

            omsdkLog("Session state after start - mainAdView: \(session.mainAdView != nil ? "set" : "nil")")
            omsdkLog("Session configuration - creativeType: \(configuration.creativeType), impressionType: \(configuration.impressionType)")

        } catch {
            omsdkLog("session failed to start: \(error)")
        }
    }

    public func fireAdLoaded() {
        omsdkLog("ad loaded")
        try? adEvents?.loaded()
    }

    public func fireImpression() {
        omsdkLog("impressionOccured")

        guard let adEvents = adEvents else {
            omsdkLog("impressionOccurred failed: adEvents is nil")
            return
        }

        do {
            try adEvents.impressionOccurred()
            omsdkLog("impressionOccurred called successfully")
        } catch {
            NSLog("impressionOccured failed: \(error)")
        }
    }

    public func finish() {
        omsdkLog("finish")
        adSession?.finish()
        adSession = nil
        adEvents = nil
        mediaEvents = nil
    }

    private func createAdSessionConfiguration() -> OMIDLoblawcaAdSessionConfiguration? {
        do {
            switch creativeKind {
            case .nativeDisplay:
                return try OMIDLoblawcaAdSessionConfiguration(
                    creativeType: .nativeDisplay,
                    impressionType: .viewable,
                    impressionOwner: .nativeOwner,
                    mediaEventsOwner: .noneOwner,
                    isolateVerificationScripts: true
                )
            case .nativeVideo:
                return try OMIDLoblawcaAdSessionConfiguration(
                    creativeType: .video,
                    impressionType: .beginToRender,
                    impressionOwner: .nativeOwner,
                    mediaEventsOwner: .nativeOwner,
                    isolateVerificationScripts: false
                )
            case .nativeAudio:
                return try OMIDLoblawcaAdSessionConfiguration(
                    creativeType: .audio,
                    impressionType: .audible,
                    impressionOwner: .nativeOwner,
                    mediaEventsOwner: .nativeOwner,
                    isolateVerificationScripts: false
                )
            }
        } catch {
            omsdkLog("Failed to create AdSessionConfiguration: \(error)")
            return nil
        }
    }

    private func createAdSessionContext(vendorKey: String,
                                        verificationScriptURL: String,
                                        verificationParameters: String) -> OMIDLoblawcaAdSessionContext? {
        var resources: [OMIDLoblawcaVerificationScriptResource] = []

        guard let scriptURL = URL(string: verificationScriptURL) else {
            omsdkLog("Failed to create verification resource: Invalid URL")
            return nil
        }

        guard let resource = OMIDLoblawcaVerificationScriptResource(url: scriptURL,
                                                                    vendorKey: vendorKey,
                                                                    parameters: verificationParameters) else {
            omsdkLog("Failed to create verification script resource")
            return nil
        }
        resources.append(resource)
        omsdkLog("Resource created and appended")

        do {
            let context = try OMIDLoblawcaAdSessionContext(
                partner: OMIDPartnerCache.shared.partner,
                script: OMIDPartnerCache.shared.omidJSService,
                resources: resources,
                contentUrl: nil,
                customReferenceIdentifier: nil
            )
            omsdkLog("AdSessionContext created successfully with \(resources.count) verification resources")
            return context
        } catch {
            omsdkLog("Failed to create AdSessionContext: \(error)")
            return nil
        }
    }

    private func omsdkLog(_ message: String) {
        #if DEBUG
        print("@@ \(message)")
        #endif
    }
}

// MARK: - Partner and JS service cache

final class OMIDPartnerCache {
    static let shared = OMIDPartnerCache()

    private init() {}

    lazy var partner: OMIDLoblawcaPartner = {
        let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1.0"
        return OMIDLoblawcaPartner(name: "loblawca", versionString: version)!
    }()

    var omidJSService: String {
        guard let url = Bundle.module.url(forResource: "omsdk-v1", withExtension: "js"),
              let jsContent = try? String(contentsOf: url) else {
            print("@@ omsdk-v1.js not found")
            return ""
        }

        print("@@ OMSDK JS loaded from package: \(url.lastPathComponent), length: \(jsContent.count)")
        return jsContent
    }
}
