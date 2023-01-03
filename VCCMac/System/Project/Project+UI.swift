//
//  Project+UI.swift
//  VCCMac
//
//  Created by yuki on 2022/12/30.
//

import CoreUtil

private let formatter = DateFormatter() => {
    $0.doesRelativeDateFormatting = true
    $0.dateStyle = .full
    $0.timeStyle = .short
}

extension Project {
    var formattedDatep: some Publisher<String, Never> {
        self.$accessDate.map{ formatter.string(from: $0) }
    }
}

extension VPMTemplate {
    var projectType: ProjectType {
        switch self.name {
        case "Avatar": return .avatarVPM
        case "World": return .worldVPM
        case "Base": return .baseVPM
        case "UdonSharp": return .udonSharpVPM
        default: return .community
        }
    }
    
    var priority: Int {
        switch self.name {
        case "Avatar": return 5
        case "World": return 6
        case "UdonSharp": return 7
        case "Base": return 8
        default: return 100
        }
    }
}

extension ProjectType {
    var icon: NSImage {
        switch self {
        case .legacyBase: return R.Image.Project.base
        case .legacyAvatar: return R.Image.Project.avatar
        case .legacyWorld: return R.Image.Project.world
        case .legacyUdonSharp: return R.Image.Project.usharp
            
        case .udonSharpVPM: return R.Image.Project.usharp
        case .avatarVPM: return R.Image.Project.avatar
        case .worldVPM: return R.Image.Project.world
        case .baseVPM: return R.Image.Project.base
            
        case .community: return R.Image.Project.community
        case .unkown: return R.Image.Project.unkown
        case .notUnityProject: return R.Image.Project.error
        }
    }
    
    var isLegacy: Bool {
        switch self {
        case .legacyBase, .legacyAvatar, .legacyWorld, .legacyUdonSharp: return true
        default: return false
        }
    }
    
    var color: NSColor {
        switch self {
        case .legacyBase: return .systemOrange
        case .legacyAvatar: return .systemPink
        case .legacyWorld: return .systemBlue
        case .legacyUdonSharp: return .systemGreen
            
        case .udonSharpVPM: return .systemOrange
        case .avatarVPM: return .systemPink
        case .worldVPM: return .systemBlue
        case .baseVPM: return .systemGreen
            
        case .community: return .systemPurple
        case .unkown: return .systemYellow
        case .notUnityProject: return .systemRed
        }
    }
    
    var title: String {
        switch self {
        case .legacyBase: return "Base (Legacy)"
        case .legacyAvatar: return "Avatar (Legacy)"
        case .legacyWorld: return "World (Legacy)"
        case .legacyUdonSharp: return "UdonSharp (Legacy)"
            
        case .udonSharpVPM: return "World (U#)"
        case .avatarVPM: return "Avatar"
        case .worldVPM: return "World"
        case .baseVPM: return "Base"
            
        case .community: return "Community"
        case .unkown(let type): return "Unkown (\(type))"
        case .notUnityProject: return "Error Project"
        }
    }
}

