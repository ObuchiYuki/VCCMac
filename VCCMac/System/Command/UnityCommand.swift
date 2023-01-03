//
//  UnityCommand.swift
//  VCCMac
//
//  Created by yuki on 2023/01/01.
//

import Foundation

final class UnityCommand {
    let catalyst: UnityCatalyst
    
    init(catalyst: UnityCatalyst) { self.catalyst = catalyst }
    
    func openProject(at url: URL) async throws {
        try await catalyst.run(["-projectPath", url.path])
    }
}
