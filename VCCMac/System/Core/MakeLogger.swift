//
//  MakeLogger.swift
//  VCCMac
//
//  Created by yuki on 2023/01/02.
//

import Foundation


func applicationLogfileURL() -> URL? {
    guard let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
        return nil
    }
    
    let logDirectory = libraryURL.appending(component: "Logs")
    let applicationLogDirectoryURL = logDirectory.appending(component: Bundle.appid)
    
    try? FileManager.default.createDirectory(at: applicationLogDirectoryURL, withIntermediateDirectories: true)
    
    enum __ { static let ltime = Date().formatted(date: .numeric, time: .standard)
        .replacingOccurrences(of: ":", with: "-")
        .replacingOccurrences(of: "/", with: "-")
    }
    
    print(__.ltime)
    
    let applicationLogURL = applicationLogDirectoryURL.appending(component: "\(__.ltime).log")
    
    return applicationLogURL
}

func makeApplicationLogger() -> Logger {
    let logger = Logger()
    logger.subscribe(minimumLevel: .error) { log in
        Task{ await Toast(error: log.message).show() }
    }
    #if DEBUG
    logger.subscribe(minimumLevel: .debug, fileHandle: FileHandle.standardOutput)
    #endif
    
//    guard let applicationLogURL = applicationLogfileURL() else {
//        print("applicationLogURL error")
//        return logger
//    }
//
//    if !FileManager.default.fileExists(at: applicationLogURL) {
//        try? Data().write(to: applicationLogURL)
//    }
//
//    guard let fileHandle = try? FileHandle(forWritingTo: applicationLogURL) else {
//        print("Cannot get filehandle")
//        return logger
//    }
//
//    _ = try? fileHandle.seekToEnd()
//
//    logger.subscribe(minimumLevel: .debug, fileHandle: fileHandle)
//
//    logger.log("Logger created.")
    
    return logger
}
