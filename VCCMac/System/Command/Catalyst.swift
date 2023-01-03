//
//  Catalyst.swift
//  VCCMac
//
//  Created by yuki on 2022/12/26.
//

import Foundation

enum CatalystError: Error, CustomStringConvertible {
    case binaryNotFound(URL)
    case binaryNotExecutable(URL)
    case failToStartCommand(Error)
    case commandExitWithNonZeroCode(code: Int32, message: String)
    
    var description: String {
        switch self {
        case .binaryNotExecutable(let url):
            return "Binary at '\(url.path)' is not excutable."
        case .binaryNotFound(let url):
            return "Command binary not found at '\(url.path)'."
        case .failToStartCommand(let error):
            return "Fail to start vpm commad (\(error))"
        case .commandExitWithNonZeroCode(let code, let message):
            if message.isEmpty {
                return "Command exit with non zero code '\(code)'"
            } else {
                return "Command exit with non zero code '\(code)'\n\(message)"
            }
        }
    }
}

protocol CommandCatalyst {
    var executableURL: URL { get }
    var logger: Logger { get }
}

extension CommandCatalyst {
    @discardableResult
    func run(_ argumenets: [String]) async throws -> String {
        try self.checkExecutable()
        
        return try await Task<String, Error>.detached{
            let task = Process()
            task.executableURL = executableURL
            task.arguments = argumenets
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            task.standardOutput = outputPipe
            task.standardError = errorPipe
            
            logger.debug("\(executableURL.lastPathComponent) \(argumenets.joined(separator: " "))")
            
            do {
                try task.run()
                await withCheckedContinuation{ continuation in
                    task.terminationHandler = {_ in
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                throw CatalystError.failToStartCommand(error)
            }
            
            if task.terminationStatus != 0 {
                let errorMessage = errorPipe.readStringToEndOfFile ?? ""
                throw CatalystError.commandExitWithNonZeroCode(code: task.terminationStatus, message: errorMessage)
            }
            let output = outputPipe.readStringToEndOfFile ?? ""
            logger.debug(output.trimmingCharacters(in: .whitespacesAndNewlines))
            return output
        }.value
    }
    
    func checkExecutable() throws {
        if !FileManager.default.fileExists(atPath: executableURL.path) {
            throw CatalystError.binaryNotFound(executableURL)
        }
        if !FileManager.default.isExecutableFile(atPath: executableURL.path) {
            throw CatalystError.binaryNotExecutable(executableURL)
        }
    }
}
