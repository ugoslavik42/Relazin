//
//  restartuserspace.swift
//  relazin
//
//  Userspace reboot: asks launchd to tear down and restart all userspace
//  daemons (like `launchctl reboot userspace`). Requires the exploit to have
//  run first (no-sandbox entitlement is only useful once the sandbox is gone).
//

import Foundation

/// Restarts userspace via `launchctl reboot userspace`.
/// Returns nil on successful spawn, or an error description.
@discardableResult
func restartuserspace() -> String? {
    globallogger.log("restarting userspace (launchctl reboot userspace)")

    var pid = pid_t(0)
    let path = "/bin/launchctl"

    var args: [UnsafeMutablePointer<CChar>?] = [
        strdup("launchctl"),
        strdup("reboot"),
        strdup("userspace"),
        nil
    ]
    defer { for a in args where a != nil { free(a) } }

    let rc = posix_spawn(&pid, path, nil, nil, &args, nil)
    guard rc == 0 else {
        let msg = "posix_spawn failed: \(String(cString: strerror(rc)))"
        globallogger.log("userspace reboot failed: \(msg)")
        return msg
    }

    // If launchd accepted the request, userspace (including us) goes down
    // immediately, so reaching this line usually means it was refused.
    globallogger.log("launchctl spawned (pid \(pid)) — if nothing happens, run the exploit first")
    return nil
}
