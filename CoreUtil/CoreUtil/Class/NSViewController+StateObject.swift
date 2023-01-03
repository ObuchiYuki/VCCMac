//
//  NSViewController+StateObject.swift
//  CoreUtil
//
//  Created by yuki on 2021/06/24.
//  Copyright © 2021 yuki. All rights reserved.
//

import Cocoa
import Combine

public protocol StateChannelType {
    var rawValue: String { get }
}

public struct StateChannel<Value>: StateChannelType {
    public let rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

extension NSViewController {
    public func state<Value>(for channel: StateChannel<Value?>) -> Value? {
        state(for: channel).flatMap{ $0 }
    }
    public func state<Value>(for channel: StateChannel<Value>) -> Value? {
        publisher(for: channel.rawValue).value as? Value
    }

    public func setState<Value>(_ value: Value?, for channel: StateChannel<Value>) {
        Self.activateStateObject()
        _setState(value, for: channel.rawValue)
    }
    
    public func statePublisher<Value>(for channel: StateChannel<Value>) -> some Publisher<Value, Never> {
        publisher(for: channel.rawValue).compactMap{ $0 as? Value }
    }
    public func statePublisher<Value>(for channel: StateChannel<Value>) -> some Publisher<Value, Never> where Value: AnyObject {
        publisher(for: channel.rawValue).compactMap{ $0 as? Value }.removeDuplicates(by: ===)
    }
    public func statePublisher<Value>(for channel: StateChannel<Value?>) -> some Publisher<Value?, Never> where Value: AnyObject {
        publisher(for: channel.rawValue).map{ $0 as? Value }.removeDuplicates(by: ===)
    }
    
    /// 親子関係のないViewControllerをChainに繋ぐ
    public func linkState<Value>(for channel: StateChannel<Value>, to viewController: NSViewController) {
        statePublisher(for: channel).sink{ viewController.setState($0, for: channel) }.store(in: &self.objectBag)
    }
    
    public func linkState<Value>(for channel: StateChannel<Value>, to viewControllers: [NSViewController]) {
        for viewController in viewControllers {
            self.linkState(for: channel, to: viewController)
        }
    }
}

// Link
extension NSViewController {
    public func linkViewController(_ viewController: NSViewController) {
        self.linkingViewControllers.append(viewController)
        viewController.chainObject = self.chainObject
        transferAllState(to: viewController)
    }
    public func linkViewControllers(_ viewControllers: [NSViewController]) {
        viewControllers.forEach{ linkViewController($0) }
    }
    
    private static var linkingViewControllersKey = 0
    
    private struct WeakBox {
        weak var value: NSViewController?
    }
    
    internal var linkingViewControllers: [NSViewController] {
        set { objc_setAssociatedObject(self, &Self.linkingViewControllersKey, newValue.map{ WeakBox(value: $0) }, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { (objc_getAssociatedObject(self, &Self.linkingViewControllersKey) as? [WeakBox] ?? []).compactMap{ $0.value } }
    }
}

extension NSViewController {
    private static func activateStateObject() {
        enum __ {
            static let __: () = method_exchangeImplementations(
                class_getInstanceMethod(NSViewController.self, #selector(addChild))!,
                class_getInstanceMethod(NSViewController.self, #selector(_addChild))!
            )
        }
        __.__
    }
    
    private func _setState(_ value: Any?, for channel: String) {
        publisher(for: channel).send(value)
        
        for child in children {
            child._setState(value, for: channel)
        }
        for link in linkingViewControllers {
            link._setState(value, for: channel)
        }
    }
    
    private static var stateContainerKey = 0
    
    private var stateContainer: [String: CurrentValueSubject<Any?, Never>] {
        get { objc_getAssociatedObject(self, &Self.stateContainerKey) as? [String: CurrentValueSubject<Any?, Never>] ?? [:] }
        set { objc_setAssociatedObject(self, &Self.stateContainerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private func publisher(for channel: String) -> CurrentValueSubject<Any?, Never> {
        return stateContainer[channel] ?? CurrentValueSubject(nil) => { stateContainer[channel] = $0 }
    }
    
    private func transferAllState(to viewController: NSViewController) {
        for channel in stateContainer.keys {
            guard let value = publisher(for: channel).value else { continue }
            viewController._setState(value, for: channel)
        }
    }
    
    @objc private dynamic func _addChild(_ childViewController: NSViewController) {
        self.transferAllState(to: childViewController)
        self._addChild(childViewController)
    }
}
