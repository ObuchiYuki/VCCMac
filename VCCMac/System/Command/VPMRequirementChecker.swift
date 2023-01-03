//
//  VPMRequirements.swift
//  VCCMac
//
//  Created by yuki on 2022/12/27.
//

import Foundation
import CoreUtil

final class VPMRequirementChecker {
    let command: VPMCommand
    
    init(command: VPMCommand) { self.command = command }
    
    enum FailureReason {
        case binaryNotFound(URL)
        case binaryNotValid(URL)
        case unityHubNotFound
        case unityNotFound
        case unkown(String)
    }
    
    func failureReasons() async -> [FailureReason] {
        var failureReasons = [FailureReason]()
        
        do {
            try command.catalyst.checkExecutable()
        } catch let error as CatalystError {
            switch error {
            case .binaryNotFound(let url):
                failureReasons.append(.binaryNotFound(url))
            case .binaryNotExecutable(let url):
                failureReasons.append(.binaryNotValid(url))
            default:
                failureReasons.append(.unkown("\(error)"))
            }
        } catch {
            failureReasons.append(.unkown("\(error)"))
        }
        
        do {
            try await command.checkHub()
        } catch {
            failureReasons.append(.unityHubNotFound)
        }
        
        do {
            try await command.checkUnity()
        } catch {
            failureReasons.append(.unityNotFound)
        }
        
        return failureReasons
    }
}

