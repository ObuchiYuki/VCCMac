//
//  ProjectIOManager.swift
//  VCCMac
//
//  Created by yuki on 2023/01/02.
//

import CoreUtil

@MainActor
final class ProjectIOManager {
    static let encoder = JSONEncoder()
    static let decoder = JSONDecoder()
    
    private let containerDirectoryURL: URL
    private let command: VPMCommand
    private let manifestCoder: ProjectManifestCoder
    private let logger: Logger
    
    init(containerDirectoryURL: URL, command: VPMCommand, manifestCoder: ProjectManifestCoder, logger: Logger) {
        self.containerDirectoryURL = containerDirectoryURL
        self.command = command
        self.manifestCoder = manifestCoder
        self.logger = logger
    }
    
    func rename(_ projectURL: URL, name: String) async throws {
        try await Task.detached{
            let renamedURL = projectURL.deletingLastPathComponent().appending(component: name)
            try FileManager.default.moveItem(at: projectURL, to: renamedURL)
        }.value
    }
    
    func load(_ containerURL: URL, manager: ProjectManager) async throws -> Project {
        try await Task.detached{
            let linkURL = containerURL.appending(components: Project.projectLinkDirectoryName)
            let projectURL: URL
            do {
                projectURL = try URL(resolvingAliasFileAt: linkURL)
            } catch {
                self.logger.debug(error)
                throw ProjectError.loadFailed("Link not exists.")
            }
        
            do {
                return try await self.loadProject(at: projectURL, containerURL: containerURL, manager: manager)
            } catch {
                self.logger.debug(error)
                throw ProjectError.loadFailed("\(error)")
            }
        }.value
    }
    
    func new(_ projectURL: URL, manager: ProjectManager) async throws -> Project {
        guard FileManager.default.fileExists(atPath: projectURL.path) else {
            throw ProjectError.loadFailed("Project is not exists.")
        }
        
        let projectMeta = ProjectMeta(lastAccessDate: Date())
        let containerURL = containerDirectoryURL.appending(components: UUID().uuidString)
        let linkURL = containerURL.appending(components: Project.projectLinkDirectoryName)
        let metaURL = containerURL.appending(component: Project.projectMetaFileName)
        
        var success = false
        
        defer {
            if !success { try? FileManager.default.removeItem(at: containerURL) }
        }
        do {
            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
            try projectURL.createAlias(at: linkURL)
            try ProjectIOManager.encoder.encode(projectMeta).write(to: metaURL)
        } catch {
            logger.debug(error)
            throw ProjectError.loadFailed("Cannot Create Project Link.")
        }
                
        let project = try await self.loadProject(at: projectURL, containerURL: containerURL, manager: manager)
        success = true
        return project
    }
    
    func updateAccessTime(_ project: Project) async throws {
        try await Task.detached{
            var meta = try await ProjectIOManager.decoder.decode(ProjectMeta.self, from: Data(contentsOf: project.metaFileURL))
            meta.lastAccessDate = Date()
            await project.updateAccessTime()
            try await ProjectIOManager.encoder.encode(meta).write(to: project.metaFileURL)
        }.value
    }
    
    private func loadProject(at projectURL: URL, containerURL: URL, manager: ProjectManager) async throws -> Project {
        do {
            let metaURL = containerURL.appending(component: Project.projectMetaFileName)
            let meta = try Self.decoder.decode(ProjectMeta.self, from: Data(contentsOf: metaURL))
            
            let project = Project(
                containerURL: containerURL,
                accessDate: meta.lastAccessDate,
                manifest: try manifestCoder.readManifest(at: projectURL),
                projectType: Task{ try await command.getProjectType(at: projectURL) },
                projectManager: manager
            )
            
            return project
        } catch {
            throw ProjectError.loadFailed(error.localizedDescription)
        }
    }
}

private extension Project {
    func updateAccessTime() {
        self.accessDate = Date()
    }
}
