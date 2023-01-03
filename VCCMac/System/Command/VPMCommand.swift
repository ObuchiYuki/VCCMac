//
//  VPM.swift
//  VCCMac
//
//  Created by yuki on 2022/12/22.
//

import Foundation
import CoreUtil

enum VPMError: Error {
    case postCheckFailed(String)
    case checkFailed(String)
}

struct VPMTemplate {
    let name: String
    let url: URL
}


final class VPMCommand {
    let catalyst: VPMCatalyst
    
    init(catalyst: VPMCatalyst) {
        self.catalyst = catalyst
    }
    
    // MARK: - Project -
    
    func newProject(name: String, templete: VPMTemplate, at url: URL) async throws {
        try await catalyst.run(["new", name, templete.name, "--path", url.path])
        
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        if !(exists && isDirectory.boolValue) {
            throw VPMError.postCheckFailed("Project created but not exists at '\(url.path)'.")
        }
    }
    
    func getProjectType(at url: URL) async throws -> ProjectType {
        let result = try await catalyst.run(["check", "project", url.path])
        if result.starts(with: /\[\d\d:\d\d:\d\d ERR\]/) || !result.contains(/Project is/) {
            return .notUnityProject
        }
        guard let projectType = result.firstMatch(of: /Project is (.*)/)?.1 else {
            throw VPMError.checkFailed("Cannot get project type.")
        }
        
        let udonsharpURL = url.appending(component: "Packages/com.vrchat.udonsharp")
        let udonsharpExists = FileManager.default.fileExists(at: udonsharpURL)
                
        switch projectType {
        case "LegacySDK3Avatar": return .legacyAvatar
        case "LegacySDK3World": return .legacyWorld
        case "LegacySDK3UdonSharp": return .legacyUdonSharp
        case "LegacySDK3Base": return .legacyBase
        case "AvatarVPM": return .avatarVPM
            
        case "WorldVPM":
            if udonsharpExists { return .udonSharpVPM }
            return .worldVPM
            
        case "StarterVPM": return .baseVPM
            
        default: return .unkown(String(projectType))
        }
    }
    
    func migrateProject(at url: URL, inplace: Bool) async throws {
        if inplace {
            try await catalyst.run(["migrate", "project", "--inplace", url.path])
        } else {
            try await catalyst.run(["migrate", "project", url.path])
        }
    }
    
    // MARK: - Package -
    
//    func getPackage(at url: URL) async throws -> VPMPackage {
//        let result = try await catalyst.run(["check", "project", url.path])
//        
//        guard let name = result.firstMatch(of: /name: (.*)/)?.1 else {
//            throw VPMError.checkFailed("Cannot get package name.")
//        }
//        guard let displayName = result.firstMatch(of: /displayName: (.*)/)?.1 else {
//            throw VPMError.checkFailed("Cannot get package displayName.")
//        }
//        guard let version = result.firstMatch(of: /version: (.*)/)?.1 else {
//            throw VPMError.checkFailed("Cannot get package version.")
//        }
//        guard let description = result.firstMatch(of: /description: (.*)/)?.1 else {
//            throw VPMError.checkFailed("Cannot get package description.")
//        }
//        
//        return VPMPackage(name: String(name), displayName: String(displayName), version: String(version), packageDescription: String(description))
//    }
    
    func addPackage(_ packageVersion: PackageVersion, to projectURL: URL) async throws {
        try await catalyst.run(["add", "package", packageVersion.name, "--project", projectURL.path])
    }
    
    // MARK: - Templates -
    
    func installTemplates() async throws {
        try await catalyst.run(["install", "templates"])
    }
    
    func listTemplates() async throws -> [VPMTemplate] {
        let result = try await catalyst.run(["list", "templates"])
        let list = result.split(separator: "\n")
            .compactMap{ $0.firstMatch(of: /\[\d\d:\d\d:\d\d INF\] (.*): (\/.+)/) }
        
        var templates = [VPMTemplate]()
        for template in list {
            templates.append(VPMTemplate(
                name: String(template.1),
                url: URL(filePath: String(template.2))
            ))
        }
        
        return templates.sorted(by: { $0.priority < $1.priority })
    }
    
    // TODO: - Repos -
    
    // MARK: - Requirements -
    
    func checkHub() async throws {
        try await catalyst.run(["check", "hub"])
    }
    
    func checkUnity() async throws {
        try await catalyst.run(["check", "unity"])
    }
}
