//
//  ACToast.swift
//  AxComponents
//
//  Created by yuki on 2021/09/13.
//  Copyright © 2021 yuki. All rights reserved.
//

import Cocoa
import CoreUtil
import DequeModule
import UserNotifications

@MainActor
final public class Toast {
    public var message: String {
        get { toastWindow.toastView.message } set { toastWindow.toastView.message = newValue }
    }
    public var action: Action? {
        get { toastWindow.toastView.action } set { toastWindow.toastView.action = newValue }
    }
    public var color: NSColor? {
        get { toastWindow.toastView.color } set { toastWindow.toastView.color = newValue }
    }
    
    private let toastWindow = ToastWindow()
    
    private static var showingToast: Toast?
    private static var pendingToasts = Deque<Toast>()
    
    public convenience init(message: String, action: Action? = nil, color: NSColor? = nil) {
        self.init()
        self.message = message
        self.action = action
        self.color = color
    }
    
    public enum AttributeViewPosition { case left, right }
    
    public func addAttributeView(_ view: NSView, position: AttributeViewPosition) {
        toastWindow.toastView.addAttributeView(view, position: position)
    }
    
    public func showForever() {
        if Toast.showingToast != nil { Toast.pendingToasts.append(self); return }
        Toast.showingToast = self
        self.toastWindow.show()
    }
    
    public func show(with duration: TimeInterval = 3) {
        self.showForever()
        
        DispatchQueue.main.asyncAfter(deadline: .now()+duration) {
            self.close()
        }
    }
    
    public func close() {
        self.toastWindow.closeToast()
        Toast.showingToast = nil
        guard let nextToast = Toast.pendingToasts.popFirst() else { return }
        nextToast.show()
    }
}

extension Toast {
    public convenience init(error: Any) {
        self.init(message: String(describing: error), color: .systemRed)
    }
    
    public func addSpinningIndicator() {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.startAnimation(nil)
        indicator.snp.makeConstraints{ make in
            make.size.equalTo(16)
        }
        self.addAttributeView(indicator, position: .right)
    }
    
    public func addProgressIndicator(_ progress: Progress) {
        let indicator = NSProgressIndicator()
        indicator.minValue = 0
        indicator.maxValue = 1
        indicator.style = .spinning
        indicator.isIndeterminate = false
        indicator.controlSize = .small
        
        progress.publisher(for: \.fractionCompleted).receive(on: DispatchQueue.main)
            .sink{[unowned indicator] in indicator.doubleValue = $0 }.store(in: &indicator.objectBag)
        
        self.addAttributeView(indicator, position: .right)
    }
}




final private class ToastWindow: NSPanel {
    let toastView = ToastView()
    
    func show() {
        guard let screen = NSScreen.main else { return NSSound.beep() }
        
        self.layoutIfNeeded()
        let frame = CGRect(centerX: screen.frame.size.width / 2, originY: 120, size: self.frame.size)
        self.setFrame(frame, display: true)
        
        self.level = .floating
        self.appearance = NSAppearance(named: .darkAqua)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.orderFrontRegardless()
        
        self.alphaValue = 0
        self.animator().alphaValue = 1
    }
    
    func closeToast() {
        self.animator().alphaValue = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.close()
        }
    }
    
    init() {
        super.init(contentRect: .zero, styleMask: [.nonactivatingPanel, .fullSizeContentView], backing: .buffered, defer: true)
        self.contentView = toastView
        self.hasShadow = false
        self.backgroundColor = .clear
    }
}

final private class ToastView: NSLoadView {
    
    var message: String {
        get { textField.stringValue } set { textField.stringValue = newValue }
    }
    var action: Action? {
        didSet { reloadAction() }
    }
    var color: NSColor? {
        didSet { reloadColor() }
    }
    
    func addAttributeView(_ view: NSView, position: Toast.AttributeViewPosition) {
        switch position {
        case .right: stackView.addArrangedSubview(view)
        case .left: stackView.insertArrangedSubview(view, at: 0)
        }
    }
    
    private func reloadAction() {
        actionButton.isHidden = action == nil
        actionButton.title = action?.title ?? ""
    }
    
    private func reloadColor() {
        colorView.fillColor = color ?? .clear
    }
    
    private let stackView = NSStackView()
    private let textField = NSTextField(labelWithString: "Title")
    private let backgroundView = NSVisualEffectView()
    private let colorView = NSRectangleView()
    private let actionButton = ToastButton(title: "Button")
        
    convenience init(message: String) {
        self.init()
        self.textField.stringValue = message
    }
    
    @objc private func executeAction(_: Any) {
        action?.action()
    }
    
    override func onAwake() {
        self.wantsLayer = true
        self.layer?.cornerRadius = 10

        self.snp.makeConstraints{ make in
            make.width.lessThanOrEqualTo(420)
        }
        
        self.addSubview(backgroundView)
        self.backgroundView.state = .active
        self.backgroundView.material = .sidebar
        self.backgroundView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        self.addSubview(colorView)
        self.colorView.alphaValue = 0.85
        self.colorView.fillColor = .systemYellow
        self.colorView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        self.addSubview(stackView)
        self.stackView.snp.makeConstraints{ make in
            make.edges.equalToSuperview().inset(16)
        }
        
        self.stackView.addArrangedSubview(textField)
        self.textField.alignment = .center
        self.textField.lineBreakMode = .byWordWrapping
        self.textField.textColor = .white
        
        self.stackView.addArrangedSubview(actionButton)
        self.actionButton.bezelStyle = .inline
        self.actionButton.setTarget(self, action: #selector(executeAction))
        
        self.reloadAction()
    }
}

final private class ToastButton: NSLoadButton {
    override var intrinsicContentSize: NSSize {
        super.intrinsicContentSize + [4, 4]
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        if isHighlighted {
            NSColor.black.withAlphaComponent(0.3).setFill()
        } else {
            NSColor.black.withAlphaComponent(0.2).setFill()
        }
        NSBezierPath(roundedRect: bounds, xRadius: bounds.height/2, yRadius: bounds.height/2).fill()
        
        let nsString = title as NSString
        nsString.draw(center: bounds, attributes: [
            .foregroundColor : NSColor.secondaryLabelColor,
            .font : NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium)
        ])
    }
    
    override func onAwake() {
        self.bezelStyle = .inline
    }
}
