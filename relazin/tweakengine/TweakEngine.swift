//
//  TweakEngine.swift
//  relazin
//
//  Runtime tweak loading — no IPA rebuild needed:
//   • .js    → JavaScriptCore runtime with a remote-call bridge into SpringBoard
//   • .dylib → injected into SpringBoard via remote dlopen()
//
//  Both run on top of lara's existing RemoteCall session (laramgr.sbProc).
//

import Foundation
import JavaScriptCore

enum tweakengine {

    // MARK: - Shared state

    private static var mgr: laramgr { laramgr.shared }

    static var isReady: Bool { mgr.rcready && mgr.sbProc != nil }

    // MARK: - .dylib injection

    /// Injects a .dylib into SpringBoard via remote dlopen().
    /// The file is copied to /tmp first so SpringBoard can definitely read it.
    static func injectDylib(at path: String) -> (ok: Bool, detail: String) {
        guard isReady, let sb = mgr.sbProc else {
            return (false, "RemoteCall not ready — run the exploit and init RemoteCall first (Advanced Options → Exploit & Actions).")
        }

        // copy to a SpringBoard-readable location
        let stage = "/tmp/relazin_\(URL(fileURLWithPath: path).lastPathComponent)"
        do {
            if FileManager.default.fileExists(atPath: stage) {
                try FileManager.default.removeItem(atPath: stage)
            }
            try FileManager.default.copyItem(atPath: path, toPath: stage)
            try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: stage)
        } catch {
            return (false, "could not stage dylib: \(error.localizedDescription)")
        }

        globallogger.log("injecting \(stage) into SpringBoard")

        let remotePath = stage.withCString { remote_alloc_str(sb, $0) }
        guard remotePath != 0 else {
            return (false, "remote string allocation failed")
        }

        let RTLD_NOW: UInt64 = 0x2
        let handle = mgr.rccall(name: "dlopen", args: [remotePath, RTLD_NOW], timeout: 10000)

        guard handle != 0 else {
            // fetch dlerror() text from SpringBoard
            var errText = "unknown error"
            let errPtr = mgr.rccall(name: "dlerror", args: [], timeout: 2000)
            if errPtr != 0, let s = sb[errPtr]?.string, !s.isEmpty {
                errText = s
            }
            globallogger.log("dlopen failed: \(errText)")
            return (false, "dlopen failed: \(errText)")
        }

        globallogger.log("dylib loaded, handle \(hex(handle))")
        return (true, "loaded — handle \(hex(handle))")
    }

    // MARK: - .js runtime

    /// Executes a .js tweak. The script gets these globals:
    ///   rc(name, [args])          → call any function in SpringBoard, args as "0x…" hex strings, returns hex string
    ///   allocStr(str)             → allocate a C string in SpringBoard, returns hex pointer
    ///   read64(addrHex)           → read 8 bytes in SpringBoard, returns hex string
    ///   write64(addrHex, valHex)  → write 8 bytes in SpringBoard
    ///   log(msg)                  → print to the output console
    static func runJS(source: String, output: @escaping (String) -> Void) {
        guard isReady, let sb = mgr.sbProc else {
            output("[!] RemoteCall not ready — run the exploit and init RemoteCall first.")
            return
        }

        guard let ctx = JSContext() else {
            output("[!] could not create JSContext")
            return
        }

        ctx.exceptionHandler = { _, exc in
            output("[!] js exception: \(exc?.toString() ?? "unknown")")
        }

        let rcFn: @convention(block) (String, [String]) -> String = { name, args in
            let parsed = args.map { strtoull($0, nil, 0) } // handles "0x…" and decimal
            let ret = mgr.rccall(name: name, args: parsed, timeout: 10000)
            return hex(ret)
        }
        ctx.setObject(rcFn, forKeyedSubscript: "rc" as NSString)

        let allocFn: @convention(block) (String) -> String = { str in
            hex(str.withCString { remote_alloc_str(sb, $0) })
        }
        ctx.setObject(allocFn, forKeyedSubscript: "allocStr" as NSString)

        let readFn: @convention(block) (String) -> String = { addrHex in
            hex(sb.remoteRead64(from: strtoull(addrHex, nil, 0)))
        }
        ctx.setObject(readFn, forKeyedSubscript: "read64" as NSString)

        let writeFn: @convention(block) (String, String) -> Void = { addrHex, valHex in
            sb.remote_write64(strtoull(addrHex, nil, 0), value: strtoull(valHex, nil, 0))
        }
        ctx.setObject(writeFn, forKeyedSubscript: "write64" as NSString)

        let logFn: @convention(block) (String) -> Void = { msg in
            output(msg)
        }
        ctx.setObject(logFn, forKeyedSubscript: "log" as NSString)

        output("[*] running tweak…")
        ctx.evaluateScript(source)
        output("[*] done")
    }
}
