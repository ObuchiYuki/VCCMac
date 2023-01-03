//
//  PackageManager.swift
//  VCCMac
//
//  Created by yuki on 2023/01/01.
//

import CoreUtil

@MainActor
final class PackageManager {
    let command: VPMCommand
    let logger: Logger
    let manifestCoder: ProjectManifestCoder
    
    private let repogitoryLoader: RepogitoryLoader
    private let officialRepogitory: Task<RepogitoryJSON, Error>
    private let curatedRepogitory: Task<RepogitoryJSON, Error>
    
    init(command: VPMCommand, manifestCoder: ProjectManifestCoder, logger: Logger) {
        self.command = command
        self.manifestCoder = manifestCoder
        self.logger = logger
        
        let repogitoryLoader = RepogitoryLoader()
        self.repogitoryLoader = repogitoryLoader
        
        self.officialRepogitory = .detached{
            try await repogitoryLoader.load(URL(filePath: "/Users/yuki/.local/share/VRChatCreatorCompanion/Repos/vrc-official.json"))
        }
        self.curatedRepogitory = .detached{
            try await repogitoryLoader.load(URL(filePath: "/Users/yuki/.local/share/VRChatCreatorCompanion/Repos/vrc-curated.json"))
        }
    }
    
    func installedPackages(for project: Project) async throws -> [Package] {
        guard let manifest = project.manifest else {
            logger.debug("Cannot Manipulate Packages of Legacy Project."); return []
        }
        var packages = [Package]()
        
        for package in try await getOfficialPackages() {
            if manifest.locked.keys.contains(where: { $0 == package.versions[0].name }) {
                packages.append(package)
            }
        }
        
        for package in try await getCuratedPackages() {
            if manifest.locked.keys.contains(where: { $0 == package.versions[0].name }) {
                packages.append(package)
            }
        }
        return packages

    }
    
    func removePackage(_ package: Package, from project: Project) async throws {
        guard let manifest = project.manifest else { return logger.debug("Cannot Manipulate Packages of Legacy Project.") }

        try await Task.detached{
            guard let projectURL = await project.projectURL else { return }
            
            let topVersion = package.versions[0]
            let identifier = topVersion.name
            
            let packageFileURL = projectURL.appending(component: "Packages/\(identifier)")
            try FileManager.default.removeItem(at: packageFileURL)
            
            var manifest = manifest
            manifest.dependencies.removeValue(forKey: identifier)
            manifest.locked.removeValue(forKey: identifier)
            try self.manifestCoder.writeManifest(manifest, projectURL: projectURL)
            try await project.reload()
        }.value
    }
    
    func addPackage(_ package: PackageVersion, to project: Project) async throws {
        guard let projectURL = project.projectURL else { return }
        try await command.addPackage(package, to: projectURL)
        try await project.reload()
    }
    
    func getOfficialPackages() async throws -> [Package] {
        try await self.officialRepogitory.value.packageList.map{
            try model(for: $0)
        }
    }
    
    func getCuratedPackages() async throws -> [Package] {
        try await self.curatedRepogitory.value.packageList.map{
            try model(for: $0)
        }
    }
    
    private func model(for package: PackageJSON) throws -> Package {
        let versions = package.versions.sorted(by: { key, _ in key }).map{ $0.value }
        guard !versions.isEmpty else { throw PackageError.noVersions }
        return Package(
            versions: versions,
            displayName: versions[0].displayName,
            selectedVersion: versions[0]
        )
    }
}


@MainActor
final class Package {
    let versions: [PackageVersion]
    let displayName: String
    
    @Observable var selectedVersion: PackageVersion
    
    init(versions: [PackageVersion], displayName: String, selectedVersion: PackageVersion) {
        self.versions = versions
        self.displayName = displayName
        self.selectedVersion = selectedVersion
    }
}

private struct RepogitoryJSON: Codable {
    let name: String
    let author: String
    let url: URL
    let packages: [String: PackageJSON]
    
    var packageList: [PackageJSON] {
        self.packages.values.sorted(by: { $0.displayName })
    }
}

private struct PackageJSON: Codable {
    let versions: [String: PackageVersion]
    var displayName: String { versions.values.first?.displayName ?? "No Name" }
}

@MainActor
final class PackageVersion: Codable {
    let name: String
    let displayName: String
    let version: String
    let unity: String?
    let description: String
    let repo: URL
    let url: URL
}

final private class RepogitoryLoader {
    private static let decoder = JSONDecoder()
    
    func load(_ localRepogitoryURL: URL) async throws -> RepogitoryJSON {
        struct LocalFile: Codable {
            let repo: RepogitoryJSON
        }
        
        return try await Task.detached{
            let data = try Data(contentsOf: localRepogitoryURL)
            return try Self.decoder.decode(LocalFile.self, from: data)
        }.value.repo
    }
}

enum PackageError: Error, CustomStringConvertible {
    case noVersions
    
    var description: String {
        switch self {
        case .noVersions: return "No versions"
        }
    }
}
