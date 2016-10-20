//
//  WSReachability.swift
//  WSReachability
//
//  Created by Ricardo Pereira on 20/10/2016.
//  Copyright © 2016 Whitesmith. All rights reserved.
//

import Foundation
import SystemConfiguration

public class WSReachability {

    public let log = WSReachabilityLog()
    public let host: String

    public typealias OSReachableCallback = (reachable: Bool) -> Void
    private var completion: OSReachableCallback?
    private var reachabilityRef: SCNetworkReachability

    private var lastReachabilityFlag: Bool?
    private var lastReachabilityTime = NSDate()

    public init?(forHost host: String) {
        self.host = host
        guard let reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, host) else {
            log.emit("Setup failed for host \(host)")
            return nil
        }
        reachabilityRef = reachability
    }

    deinit {
        self.off()
    }

    public func listen(completion: OSReachableCallback) {
        self.off()
        self.completion = completion

        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque())

        if SCNetworkReachabilitySetCallback(reachabilityRef, OSReachability_Callback, &context) {
            if SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode) {
                log.emit("Started listening for host \(host)")
            }
            else {
                log.emit("Failed starting listener for host \(host)")
            }
        }
        else {
            log.emit("SCNetworkReachabilitySetCallback failed")
        }
    }

    public func off() {
        SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)
        log.emit("Stopped listening for host \(host)")
    }

    internal func emit(reachable reachable: Bool) {
        log.emit("Host \(host) is \(reachable ? "available" : "unavailable")")
        let currentTime = NSDate()
        defer {
            lastReachabilityFlag = reachable
        }

        // If it has the same reachability flag and was emitted almost immediately after the last one, then ignore it.
        if lastReachabilityFlag == .Some(reachable) && currentTime.timeIntervalSinceDate(lastReachabilityTime) < 0.5 {
            return
        }

        lastReachabilityTime = currentTime
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            // Notify
            self?.completion?(reachable: reachable)
        }
    }

    public var isReachable: Bool {
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(reachabilityRef, &flags) {
            return flags.contains(SCNetworkReachabilityFlags.Reachable)
        }
        else {
            return false
        }
    }

}

internal func OSReachability_Callback(reachability: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutablePointer<Void>) {
    let instance = Unmanaged<WSReachability>.fromOpaque(COpaquePointer(info)).takeUnretainedValue()
    instance.emit(reachable: flags.contains(SCNetworkReachabilityFlags.Reachable))
}

public class WSReachabilityLog {

    public struct WSReachabilityLogListener {
        public typealias ListenerCallback = (message: String) -> Void
        public let callback: ListenerCallback
    }

    private var listener: WSReachabilityLogListener?

    public func subscribe(callback: WSReachabilityLogListener.ListenerCallback) {
        listener = WSReachabilityLogListener(callback: callback)
    }

    public func unsubscribe() {
        listener = nil
    }

    internal func emit(message: String) {
        listener?.callback(message: message)
    }

}
