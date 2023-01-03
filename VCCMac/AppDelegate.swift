//
//  AppDelegate.swift
//  VCCMac
//
//  Created by yuki on 2022/12/21.
//

import Cocoa
import CoreUtil

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {}
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

