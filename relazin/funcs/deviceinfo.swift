//
//  deviceinfo.swift
//  relazin
//
//  Device info shown on the terminal home screen.
//

import UIKit
import Darwin

enum deviceinfo {

    /// e.g. "iOS 17.0"
    static var os: String {
        "iOS \(UIDevice.current.systemVersion)"
    }

    /// e.g. "iPhone14,3"
    static var host: String {
        var u = utsname()
        uname(&u)
        return withUnsafeBytes(of: &u.machine) { ptr in
            String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
    }

    /// e.g. "Darwin 23.0.0"
    static var kernel: String {
        var u = utsname()
        uname(&u)
        let release = withUnsafeBytes(of: &u.release) { ptr in
            String(cString: ptr.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        return "Darwin \(release)"
    }

    /// e.g. "v0.3.3(0)"
    static var build: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "v\(version)(\(build))"
    }

    /// System uptime since boot, e.g. "1h 43m"
    static var uptime: String {
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        var boottime = timeval()
        var size = MemoryLayout<timeval>.stride
        guard sysctl(&mib, u_int(mib.count), &boottime, &size, nil, 0) == 0 else {
            return "unknown"
        }
        let seconds = Int(Date().timeIntervalSince1970) - Int(boottime.tv_sec)
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
