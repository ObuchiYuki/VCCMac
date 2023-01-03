//
//  R.swift
//  DevToys
//
//  Created by yuki on 2022/01/29.
//

import Cocoa

enum R {
    enum Size {
        static let corner: CGFloat = 5
        static let controlHeight: CGFloat = 26
    }
    enum FontSize {
        static let sidebarTitle: CGFloat = 12
        static let controlTitle: CGFloat = 12
        static let control: CGFloat = 10.5
    }
    
    enum Color {
        static var controlBackgroundColor: NSColor { NSColor.textColor.withAlphaComponent(0.08) }
        static var controlHighlightedBackgroundColor: NSColor { NSColor.textColor.withAlphaComponent(0.15) }
        static let transparentBackground = NSColor(patternImage: NSImage(named: "transparent_background")!)
    }
    enum Image {
        static let unity = NSImage(named: "unity")!
        static let addProject = NSImage(named: "add_project")!
        static let menu = NSImage(named: "menu")!
        
        static let sidebarDisclosure = NSImage(named: "sidebar.disclosure")!
        static let pulldownIndicator = NSImage(named: "pulldown.indicator")!
        
        static let search = NSImage(named: "search")!
        static let check = NSImage(named: "check")!
        static let error = NSImage(named: "error")!

        static let paramators = NSImage(named: "paramators")!
        static let settings = NSImage(named: "settings")!
        
        static let stepperUp = NSImage(named: "stepper.up")!
        static let stepperDown = NSImage(named: "stepper.down")!
        
        static let open = NSImage(named: "open")!
        static let drop = NSImage(named: "drop")!
        static let export = NSImage(named: "export")!
        
        enum Tool {
            static let home = NSImage(named: "tool/home")!
            static let settings = NSImage(named: "tool/settings")!
            static let project = NSImage(named: "tool/project")!
            static let learn = NSImage(named: "tool/learn")!
            static let tools = NSImage(named: "tool/tools")!
        }
        
        enum Project {
            static let community = NSImage(named: "project/community")!
            
            static let avatar = NSImage(named: "project/avatar")!
            static let avatarOld = NSImage(named: "project/avatar_old")!
            
            static let world = NSImage(named: "project/world")!
            static let worldOld = NSImage(named: "project/world_old")!
            
            static let usharp = NSImage(named: "project/usharp")!
            static let usharpOld = NSImage(named: "project/usharp_old")!
            
            static let base = NSImage(named: "project/base")!
            static let baseOld = NSImage(named: "project/base_old")!
            
            static let unkown = NSImage(named: "project/unkown")!
            static let warn = NSImage(named: "project/warn")!
            static let error = NSImage(named: "project/error")!
        }
    }
}

extension Bundle {
    static let current = Bundle(for: { class __ {}; return  __.self }())
}
