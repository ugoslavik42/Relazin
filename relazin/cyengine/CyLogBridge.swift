//
//  CyLogBridge.swift
//  relazin
//
//  Lets the ported ObjC tweak engine write into relazin's Logger.
//

import Foundation

@objcMembers
class CyLogBridge: NSObject {
    static func log(_ message: String) {
        globallogger.log(message)
    }
}
