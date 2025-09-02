//
//  OMSDKWrapper.swift
//  OMSDK
//
//  Swift wrapper for OMSDK with DoubleVerify integration
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(WebKit)
import WebKit
#endif

// MARK: - DoubleVerify Configuration
public struct DoubleVerifyConfig {
    public static let baseJS = "https://cdn.doubleverify.com/dvbm.js"
    public static let basePixel = "https://tps.doubleverify.com/visit.jpg"
    
    // DoubleVerify parameters from your original tag
    public static let ctx = "818052"
    public static let cmp = "DV1871679"
    public static let advid = "818052"
    public static let mon = "1"
    public static let blk = "0"
    public static let dvpTigerReqSrc = "blueprint"
    public static let eeDpTigerReqSrc = "blueprint"
    public static let advwf = "displaySiteServed"
    
    // GDPR defaults (as you requested)
    public static let gdprDefault = "0"
    public static let gdprConsentDefault = ""
}

// MARK: - OMSDK + DoubleVerify Manager
@objc public class OMSDKManager: NSObject {
    
    @objc public static let shared = OMSDKManager()
    
    // Session management
    private var currentSessionId: String?
    private var currentPlacementId: String?
    private var isSessionActive = false
    
    #if canImport(WebKit)
    private var dvWebView: WKWebView?
    #endif
    
    private override init() {
        super.init()
    }
    
    @objc public func activateSDK() -> Bool {
        NSLog("@@ OMSDK + DoubleVerify integration activated")
        return true
    }
    
    @objc public func sdkVersion() -> String {
        return "1.0.0-doubleverify-integrated"
    }
    
    @objc public func createSession(
        partnerName: String,
        partnerVersion: String,
        creativeType: UInt,
        impressionType: UInt,
        impressionOwner: UInt,
        mediaEventsOwner: UInt,
        mainAdView: AnyObject,
        placementId: String
    ) -> Bool {
        
        // Generate session ID and store session info
        currentSessionId = generateSessionId()
        currentPlacementId = placementId
        isSessionActive = true
        
        NSLog("@@ OMSDK session created for placement: \(placementId)")
        NSLog("@@ Partner: \(partnerName) v\(partnerVersion)")
        NSLog("@@ Session ID: \(currentSessionId ?? "unknown")")
        
        // Initialize DoubleVerify tracking
        initializeDoubleVerifyTracking()
        
        return true
    }
    
    @objc public func fireLoadedEvent() -> Bool {
        guard isSessionActive else {
            NSLog("@@ OMSDK loaded event failed: No active session")
            return false
        }
        
        NSLog("@@ OMSDK loaded event fired for session: \(currentSessionId ?? "unknown")")
        
        // Fire DoubleVerify loaded event
        fireDoubleVerifyLoadedEvent()
        
        return true
    }
    
    @objc public func fireImpressionEvent() -> Bool {
        guard isSessionActive else {
            NSLog("@@ OMSDK impression event failed: No active session")
            return false
        }
        
        NSLog("@@ OMSDK impression event fired for session: \(currentSessionId ?? "unknown")")
        
        // Fire DoubleVerify impression event
        fireDoubleVerifyImpressionEvent()
        
        return true
    }
    
    @objc public func finishSession() {
        guard isSessionActive else {
            NSLog("@@ OMSDK session already finished")
            return
        }
        
        // Clean up DoubleVerify webview
        #if canImport(WebKit)
        dvWebView?.removeFromSuperview()
        dvWebView = nil
        #endif
        
        NSLog("@@ OMSDK session finished for: \(currentPlacementId ?? "unknown")")
        
        // Clean up session data
        currentSessionId = nil
        currentPlacementId = nil
        isSessionActive = false
    }
    
    // MARK: - Private Helpers
    
    private func generateSessionId() -> String {
        return String(UUID().uuidString.prefix(8))
    }
    
    // MARK: - DoubleVerify Integration
    
    private func initializeDoubleVerifyTracking() {
        guard let sessionId = currentSessionId,
              let placementId = currentPlacementId else {
            NSLog("@@ DoubleVerify initialization failed: Missing session data")
            return
        }
        
        let dvParams = buildDoubleVerifyParameters(sessionId: sessionId, placementId: placementId)
        NSLog("@@ DoubleVerify initialized with params: \(dvParams)")
        
        // Create hidden webview for DoubleVerify script execution
        setupDoubleVerifyWebView()
    }
    
    private func setupDoubleVerifyWebView() {
        #if canImport(WebKit) && canImport(UIKit)
        // Create hidden webview for DoubleVerify
        dvWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        dvWebView?.isHidden = true
        
        // Add to a window if available
        if let window = UIApplication.shared.windows.first {
            window.addSubview(dvWebView!)
        }
        
        NSLog("@@ DoubleVerify webview created and added to window")
        #else
        NSLog("@@ DoubleVerify webview not available on this platform")
        #endif
    }
    
    private func fireDoubleVerifyLoadedEvent() {
        guard let sessionId = currentSessionId,
              let placementId = currentPlacementId else {
            NSLog("@@ DoubleVerify loaded event failed: Missing session data")
            return
        }
        
        let dvParams = buildDoubleVerifyParameters(sessionId: sessionId, placementId: placementId)
        NSLog("@@ DoubleVerify loaded event firing with: \(dvParams)")
        
        // Execute DoubleVerify script in webview
        executeDoubleVerifyScript(params: dvParams)
    }
    
    private func fireDoubleVerifyImpressionEvent() {
        guard let sessionId = currentSessionId,
              let placementId = currentPlacementId else {
            NSLog("@@ DoubleVerify impression event failed: Missing session data")
            return
        }
        
        let dvParams = buildDoubleVerifyParameters(sessionId: sessionId, placementId: placementId)
        NSLog("@@ DoubleVerify impression event firing with: \(dvParams)")
        
        // Fire both script and pixel for maximum coverage
        executeDoubleVerifyScript(params: dvParams)
        fireDoubleVerifyPixel(params: dvParams)
    }
    
    private func buildDoubleVerifyParameters(sessionId: String, placementId: String) -> String {
        return [
            "ctx=\(DoubleVerifyConfig.ctx)",
            "cmp=\(DoubleVerifyConfig.cmp)",
            "sid=\(sessionId)",
            "plc=\(placementId)",
            "advid=\(DoubleVerifyConfig.advid)",
            "mon=\(DoubleVerifyConfig.mon)",
            "blk=\(DoubleVerifyConfig.blk)",
            "gdpr=\(DoubleVerifyConfig.gdprDefault)",
            "gdpr_consent=\(DoubleVerifyConfig.gdprConsentDefault)",
            "dvp_tigerreqsrc=\(DoubleVerifyConfig.dvpTigerReqSrc)",
            "ee_dp_tigerreqsrc=\(DoubleVerifyConfig.eeDpTigerReqSrc)",
            "advwf=\(DoubleVerifyConfig.advwf)"
        ].joined(separator: "&")
    }
    
    private func executeDoubleVerifyScript(params: String) {
        #if canImport(WebKit)
        guard let webView = dvWebView else {
            NSLog("@@ DoubleVerify webview not available")
            return
        }
        
        let scriptURL = "\(DoubleVerifyConfig.baseJS)#\(params)"
        let cacheBuster = Int(Date().timeIntervalSince1970)
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head><title>DoubleVerify</title></head>
        <body>
        <script src='\(scriptURL)&cb=\(cacheBuster)'></script>
        <noscript><img src='\(DoubleVerifyConfig.basePixel)?tagtype=display&\(params)&cb=\(cacheBuster)' width='0' height='0'/></noscript>
        </body>
        </html>
        """
        
        NSLog("@@ Executing DoubleVerify script: \(scriptURL)")
        webView.loadHTMLString(html, baseURL: nil)
        #else
        NSLog("@@ DoubleVerify script execution not available on this platform")
        #endif
    }
    
    private func fireDoubleVerifyPixel(params: String) {
        let cacheBuster = Int(Date().timeIntervalSince1970)
        let pixelURL = "\(DoubleVerifyConfig.basePixel)?tagtype=display&\(params)&cb=\(cacheBuster)"
        
        guard let url = URL(string: pixelURL) else {
            NSLog("@@ Invalid DoubleVerify pixel URL")
            return
        }
        
        NSLog("@@ Firing DoubleVerify pixel: \(pixelURL)")
        
        URLSession.shared.dataTask(with: url) { _, response, error in
            if let error = error {
                NSLog("@@ DoubleVerify pixel failed: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse {
                NSLog("@@ DoubleVerify pixel fired successfully, status: \(httpResponse.statusCode)")
            }
        }.resume()
    }
}