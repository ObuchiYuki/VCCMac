//
//  Project+Data.swift
//  VCCMac
//
//  Created by yuki on 2022/12/29.
//

import CoreUtil

enum ProjectType: Equatable, Hashable {
    case legacyUdonSharp
    case legacyAvatar
    case legacyWorld
    case legacyBase
    
    case udonSharpVPM
    case avatarVPM
    case worldVPM
    case baseVPM
    
    case unkown(String)
    
    case community
    case notUnityProject
}

struct ProjectManifest: Codable {
    struct Package: Codable {
        let version: String
        let dependencies: [String: String]?
    }
    var dependencies: [String: Package]
    var locked: [String: Package]
}


struct ProjectMeta: Codable {
    var lastAccessDate: Date
}

@MainActor
final class Project {
    static let projectLinkDirectoryName = "project_link"
    static let projectMetaFileName = "meta.json"
    
    let containerURL: URL
    
    @Observable var accessDate: Date
    @Observable var manifest: ProjectManifest?
    @Observable var projectType: Task<ProjectType, Error>
    
    @Observable var title: String
    @Observable var linkURL: URL
    @Observable var projectURL: URL?
    
    var metaFileURL: URL { containerURL.appending(component: Project.projectMetaFileName) }
    
    private unowned let projectManager: ProjectManager
    
    func reload() async throws {
        let nproject = try await projectManager.loadProject(at: containerURL)
        self.accessDate = nproject.accessDate
        self.manifest = nproject.manifest
        self.projectType = nproject.projectType
        self.title = nproject.title
        self.linkURL = nproject.linkURL
        self.projectURL = nproject.projectURL
    }
    
    init(containerURL: URL, accessDate: Date, manifest: ProjectManifest?, projectType: Task<ProjectType, Error>, projectManager: ProjectManager) {
        self.containerURL = containerURL
        self.accessDate = accessDate
        self.manifest = manifest
        self.projectType = projectType
        self.projectManager = projectManager

        (linkURL, projectURL, title) = Self.loadEntity(at: containerURL)
    }
    
    private static func loadEntity(at containerURL: URL) -> (linkURL: URL, projectURL: URL?, title: String) {
        let linkURL = containerURL.appending(component: Project.projectLinkDirectoryName)
        let projectURL = try? URL(resolvingAliasFileAt: linkURL)
        let title = projectURL?.lastPathComponent ?? "Broken Project"
        
        return (linkURL, projectURL, title)
    }
}

