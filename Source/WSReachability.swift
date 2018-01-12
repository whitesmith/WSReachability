//
//  WSReachability.swift
//  WSReachability
//
//  Created by Ricardo Pereira on 20/10/2016.
//  Copyright © 2016 Whitesmith. All rights reserved.
//

import Foundation
import SystemConfiguration

open class WSReachability {

    open let log = WSReachabilityLog()
    open let host: String

    public typealias OSReachableCallback = (_ reachable: Bool) -> Void
    fileprivate var completion: OSReachableCallback?
    fileprivate var reachabilityRef: SCNetworkReachability

    fileprivate var lastReachabilityFlag: Bool?
    fileprivate var lastReachabilityTime = Date()

    public init?(use host: String) {
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

    open func listen(_ completion: @escaping OSReachableCallback) {
        self.off()
        self.completion = completion

        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)

        context.info = Unmanaged<WSReachability>.passUnretained(self).toOpaque()

        if SCNetworkReachabilitySetCallback(reachabilityRef, OSReachability_Callback, &context) {
            if SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode as! CFString) {
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

    open func off() {
        SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode as! CFString)
        log.emit("Stopped listening for host \(host)")
    }

    internal func emit(reachable: Bool) {
        log.emit("Host \(host) is \(reachable ? "available" : "unavailable")")
        let currentTime = Date()
        defer {
            lastReachabilityFlag = reachable
        }

        // If it has the same reachability flag and was emitted almost immediately after the last one, then ignore it.
        if lastReachabilityFlag == .some(reachable) && currentTime.timeIntervalSince(lastReachabilityTime) < 0.5 {
            return
        }

        lastReachabilityTime = currentTime
        DispatchQueue.main.async { [weak self] in
            // Notify
            self?.completion?(reachable)
        }
    }

    open var isReachable: Bool {
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(reachabilityRef, &flags) {
            return flags.contains(SCNetworkReachabilityFlags.reachable)
        }
        else {
            return false
        }
    }

}

internal func OSReachability_Callback(_ reachability: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
    guard  let info = info else {
        return
    }
    let instance = Unmanaged<WSReachability>.fromOpaque(info).takeUnretainedValue()
    instance.emit(reachable: flags.contains(SCNetworkReachabilityFlags.reachable))
}

open class WSReachabilityLog {

    public struct WSReachabilityLogListener {
        public typealias ListenerCallback = (_ message: String) -> Void
        public let callback: ListenerCallback
    }

    fileprivate var listener: WSReachabilityLogListener?

    open func subscribe(_ callback: @escaping WSReachabilityLogListener.ListenerCallback) {
        listener = WSReachabilityLogListener(callback: callback)
    }

    open func unsubscribe() {
        listener = nil
    }

    internal func emit(_ message: String) {
        listener?.callback(message)
    }

}
