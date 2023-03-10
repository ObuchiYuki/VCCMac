//
//  BodyViewController.swift
//  DevToys
//
//  Created by yuki on 2022/01/29.
//

import CoreUtil

final class BodyViewController: NSViewController {
    private let placeholderView = NSPlaceholderView()
    private var contentViewController: NSViewController?
    
    override func loadView() { self.view = placeholderView }
    
    override func chainObjectDidLoad() {
        self.appModel.$tool
            .sink{[unowned self] in replaceTool($0) }.store(in: &objectBag)
    }
    
    private func replaceTool(_ tool: Tool) {
        self.contentViewController?.removeFromParent()
        self.addChild(tool.viewController)
        self.contentViewController = tool.viewController
        self.placeholderView.contentView = tool.viewController.view
    }
}
