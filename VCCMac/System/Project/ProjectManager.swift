//
//  ProjectManager.swift
//  VCCMac
//
//  Created by yuki on 2022/12/26.
//

import CoreUtil

@MainActor
final class ProjectManager {
    @Observable private(set) var projects = [Project]()
    
    let containerDirectoryURL: URL
    
    private let command: VPMCommand
    private let logger: Logger
    private let manifestCoder: ProjectManifestCoder
    
    private let projectChecker: ProjectChecker
    private let projectIOManager: ProjectIOManager
    private let backupManager: ProjectBackupManager
    
    init(command: VPMCommand, containerDirectoryURL: URL, manifestCoder: ProjectManifestCoder, logger: Logger) {
        self.command = command
        self.containerDirectoryURL = containerDirectoryURL
        self.logger = logger
        self.manifestCoder = manifestCoder
        self.projectChecker = .init(manifestCoder: manifestCoder, logger: logger)
        self.projectIOManager = .init(containerDirectoryURL: containerDirectoryURL, command: command, manifestCoder: manifestCoder, logger: logger)
        self.backupManager = .init()
        
        Task{
            try await reloadProjects()
        }
    }
    
    func openInUnity(_ project: Project) async throws {
        guard let projectURL = project.projectURL else { throw ProjectError.projectOpenFailed }
        let catalyst = UnityCatalyst(logger: self.logger)
        let unityCommand = UnityCommand(catalyst: catalyst)
        try await self.projectIOManager.updateAccessTime(project)
        self.updateProjectSort()
        try await unityCommand.openProject(at: projectURL)
    }
    
    func migrateProject(_ project: Project) async throws {
        guard try await project.projectType.value.isLegacy else { throw ProjectError.migrateFailed("Not a Legacy Project.") }
        guard let projectURL = project.projectURL else { throw ProjectError.migrateFailed("Project not found.") }
        
        try await command.migrateProject(at: projectURL, inplace: false)
        
        #warning("This is not true")
        let migratedProjectFilename = projectURL.lastPathComponent + "-Migrated"
        let migratedProjectURL = projectURL.deletingLastPathComponent().appending(component: migratedProjectFilename)
        
        try await self.addProject(migratedProjectURL)
    }
    
    func addBackupProject(_ backupProjectURL: URL, unpackTo directoryURL: URL, unpackProgress: Progress) async throws {
        assert(backupProjectURL.pathExtension == "zip")
        
        let projectURL = try await self.backupManager.loadBackup(backupProjectURL, to: directoryURL, progress: unpackProgress)
        
        try await self.addProject(projectURL)
    }
    
    func addProject(_ existingProjectURL: URL) async throws {
        let project = try await projectIOManager.new(existingProjectURL, manager: self)
        
        let result = projectChecker.check(project)
        
        do {
            try projectChecker.recoverIfPossible(project, result: result)
            
            if let duplicatedProject = self.projects.first(where: { $0.projectURL == project.projectURL }) {
                try await projectIOManager.updateAccessTime(duplicatedProject)
                self.updateProjectSort()
                throw ProjectError.loadFailed("Duplicated project added.")
            }
            
            self.projects.insert(project, at: 0)
        } catch {
            await self.unlinkProject(project)
            throw error
        }
    }
    
    func reloadProjects() async throws {
        let containerURLs = try FileManager.default.contentsOfDirectory(at: containerDirectoryURL, includingPropertiesForKeys: nil)
        
        var projects = [Project]()
        var errorCount = 0
        
        for containerURL in containerURLs {
            do {
                let project = try await loadProject(at: containerURL)
                guard let projectURL = project.projectURL else { throw ProjectError.loadFailed("No project entity.") }
                if projectURL.inTrash() { continue }
                projects.append(project)
            } catch { // remove broken projects
                await removeProject(containerURL)
                errorCount += 1
                self.logger.debug(String(describing: error))
            }
        }
        
        self.projects = projects.sorted(by: { $0.accessDate > $1.accessDate })
        
        if errorCount != 0 {
            logger.error("\(errorCount) projects has errors & removed.")
        }
    }
    
    func loadProject(at containerURL: URL) async throws -> Project {
        return try await projectIOManager.load(containerURL, manager: self)
    }
    
    func createProject(title: String, templete: VPMTemplate, at url: URL) async throws {
        let projectURL = url.appending(components: title)
        try await command.newProject(name: title, templete: templete, at: url)
        
        let project = try await projectIOManager.new(projectURL, manager: self)
        self.projects.insert(project, at: 0)
    }
    
    func unlinkProject(_ project: Project) async {
        await self.removeProject(project.containerURL)
        self.projects.removeFirst(where: { $0 === project })
    }
    
    func renameProject(_ project: Project, to name: String) async throws {
        guard let projectURL = project.projectURL else { throw ProjectError.loadFailed("Project not found.") }
        try await self.projectIOManager.rename(projectURL, name: name)
        try await project.reload()
    }
    
    func backupProject(_ project: Project, to url: URL) async throws {
        guard let projectURL = project.projectURL else { throw ProjectError.loadFailed("Project not found.") }
        guard url.pathExtension == "zip" else { throw ProjectError.loadFailed("Backup must be zip.") }
        try await backupManager.makeBackup(projectURL, at: url)
    }
    
    private func updateAccessTime(_ project: Project) async throws {
        try await projectIOManager.updateAccessTime(project)
    }
    
    private func updateProjectSort() {
        self.projects.sort(by: { $0.accessDate > $1.accessDate })
    }
    
    private func removeProject(_ containerURL: URL) async {
        await Task.detached{
            do {
                try FileManager.default.removeItem(at: containerURL)
            } catch {
                self.logger.debug(error)
                self.logger.error("Remove Project Failed.")
            }
        }.value
    }
}

extension FileManager {
    public func fileExists(at url: URL) -> Bool {
        self.fileExists(atPath: url.path)
    }
    public func isDirectory(_ url: URL) -> Bool {
        var isDirectory = ObjCBool(false)
        fileExists(atPath: url.path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
}

extension URL {
    func inTrash() -> Bool {
        guard let trashURL = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first else {
            return false
        }
        
        return self.isContained(in: trashURL)
    }
}
