//
//  ProjectBackupManager.swift
//  VCCMac
//
//  Created by yuki on 2023/01/02.
//

import CoreUtil
import ZIPFoundation

enum BackupError: Error, CustomStringConvertible {
    case loadFailed(String)
    
    var description: String {
        switch self {
        case .loadFailed(let string): return "Load failed (\(string))"
        }
    }
}

final class ProjectBackupManager {
    func makeBackup(_ projectURL: URL, at url: URL) async throws {
         try await Task.detached{
            try FileManager.default.zipItem(at: projectURL, to: url)
         }.value
    }
    
    private let temporaryDirectory = URL(filePath: NSTemporaryDirectory())
        .appending(component: "unpacking_backup")
    
    func loadBackup(_ backupURL: URL, to url: URL, progress: Progress) async throws -> URL {
        try await Task.detached{
            let unpackDirectory = self.temporaryDirectory.appending(component: UUID().uuidString)
            
            try FileManager.default.createDirectory(at: unpackDirectory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: unpackDirectory) }
            
            try FileManager.default.unzipItem(at: backupURL, to: unpackDirectory, progress: progress)
            
            let contents = try FileManager.default.contentsOfDirectory(at: unpackDirectory, includingPropertiesForKeys: nil)
            
            guard contents.count == 1 else { throw BackupError.loadFailed("Multiple content unpacked.") }
            
            let projectURL = contents[0]
            let projectTitle = projectURL.lastPathComponent
            let destinationURL = url.appending(component: projectTitle)
            
            try FileManager.default.moveItem(at: projectURL, to: destinationURL)
            
            return destinationURL
        }.value
    }
}
