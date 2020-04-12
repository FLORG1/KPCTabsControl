//
//  TabButton.swift
//  KPCTabsControl
//
//  Created by Cédric Foellmi on 06/07/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

open class TabButton: NSButton {

    fileprivate var iconView: NSImageView?
    fileprivate var alternativeTitleIconView: NSImageView?
    fileprivate var trackingArea: NSTrackingArea?
    fileprivate var closeButton: CloseButton?
    
    fileprivate var tabButtonCell: TabButtonCell? {
        get { return self.cell as? TabButtonCell }
    }

    open var item: AnyObject? {
        get { return self.cell?.representedObject as AnyObject? }
        set { self.cell?.representedObject = newValue }
    }

    open var style: Style! {
        didSet {
            self.tabButtonCell?.style = self.style
        }
    }

    /// The button is aware of its last known index in the tab bar.
    var index: Int? = nil

    open var buttonPosition: TabPosition! {
        get { return tabButtonCell?.buttonPosition }
        set { self.tabButtonCell?.buttonPosition = newValue }
    }
    
    open var closeButtonSize: CGFloat {
        return closeButton?.frame.width ?? 0
    }

    open var representedObject: AnyObject? {
        get { return self.tabButtonCell?.representedObject as AnyObject? }
        set { self.tabButtonCell?.representedObject = newValue }
    }

    open var editable: Bool {
        get { return self.tabButtonCell?.isEditable ?? false }
        set { self.tabButtonCell?.isEditable = newValue }
    }

    open var icon: NSImage? = nil {
        didSet {
            if self.icon != nil && self.iconView == nil {
                self.iconView = NSImageView(frame: .zero)
                self.iconView?.imageFrameStyle = .none
                self.iconView?.imageScaling = .scaleProportionallyUpOrDown
                
                self.addSubview(self.iconView!)
            }
            else if (self.icon == nil && self.iconView != nil) {
                self.iconView?.removeFromSuperview()
                self.iconView = nil
            }
            self.iconView?.image = self.icon
            self.needsDisplay = true
        }
    }
    
    open var alternativeTitleIcon: NSImage? = nil {
        didSet {
            self.tabButtonCell?.hasTitleAlternativeIcon = (self.alternativeTitleIcon != nil)
            
            if self.alternativeTitleIcon != nil && self.alternativeTitleIconView == nil {
                self.alternativeTitleIconView = NSImageView(frame: .zero)
                self.alternativeTitleIconView?.imageFrameStyle = .none
                self.alternativeTitleIconView?.imageScaling = .scaleProportionallyUpOrDown

                self.addSubview(self.alternativeTitleIconView!)
            }
            else if self.alternativeTitleIcon == nil && self.alternativeTitleIconView != nil {
                self.alternativeTitleIconView?.removeFromSuperview()
                self.alternativeTitleIconView = nil
            }
            self.alternativeTitleIconView?.image = self.alternativeTitleIcon
            self.needsDisplay = true
        }
    }
    
    open var closeTabCallBack : ((AnyObject?, AnyObject?) -> Void)? = {_, _ in }

    open var dragging: Bool {
        get { return tabButtonCell?.dragging ?? false }
        set { tabButtonCell?.dragging = newValue }
    }

    // MARK: - Init

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.cell = TabButtonCell(textCell: "")
        
    }
    
    convenience init(frame frameRect: NSRect, style: Style, closeCallBack:((AnyObject? ,AnyObject?) -> Void)?) {
        self.init(frame: frameRect)
        self.style = style
        self.cell = TabButtonCell(textCell: "")
        createCloseButton(closeCallBack: closeCallBack)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(index: Int, item: AnyObject, target: AnyObject?, action:Selector, style: Style) {
        super.init(frame: NSZeroRect)

        self.index = index
        self.style = style

        let tabCell = TabButtonCell(textCell: "")
        
        tabCell.representedObject = item
        tabCell.imagePosition = .noImage
        
        tabCell.target = target
        tabCell.action = action
        tabCell.style = style
        
        tabCell.sendAction(on: NSEvent.EventTypeMask(rawValue: UInt64(Int(NSEvent.EventTypeMask.leftMouseDown.rawValue))))
        self.cell = tabCell
    }
    
    convenience init(index: Int, item: AnyObject, target: AnyObject?, action:Selector, style: Style, closeCallBack: ((AnyObject?, AnyObject?) -> Void)?) {
        self.init(index: index, item:  item, target:  target, action:  action, style: style)
        createCloseButton(closeCallBack: closeCallBack)
        
    }
    
    override open func copy() -> Any {
        let copy = TabButton(frame: self.frame, style: self.style!, closeCallBack: self.closeTabCallBack)
        copy.cell = self.cell?.copy() as? NSCell
        copy.icon = self.icon
        copy.alternativeTitleIcon = self.alternativeTitleIcon
        copy.state = self.state
        copy.index = self.index
        copy.closeTabCallBack = self.closeTabCallBack
        return copy
    }
        
    open override var menu: NSMenu? {
        get { return self.cell?.menu }
        set {
            self.cell?.menu = newValue
            self.updateTrackingAreas()
        }
    }
    
    // MARK: - Drawing

    open override func updateTrackingAreas() {
        if let ta = self.trackingArea {
            self.removeTrackingArea(ta)
        }
        
        let item: AnyObject? = self.cell?.representedObject as AnyObject?
        
        let userInfo: [String: AnyObject]? = (item != nil) ? ["item": item!] : nil
        let opts: NSTrackingArea.Options = [.inVisibleRect, .activeInActiveApp, .mouseEnteredAndExited]
        self.trackingArea = NSTrackingArea(rect: self.bounds,
                                           options: opts,
                                           owner: self,
                                           userInfo: userInfo)
        self.addTrackingArea(self.trackingArea!)
        
        if let w = self.window, let e = NSApp.currentEvent {
            let mouseLocation = w.mouseLocationOutsideOfEventStream
            let convertedMouseLocation = self.convert(mouseLocation, from: nil)
        
            if NSPointInRect(convertedMouseLocation, self.bounds) {
                self.mouseEntered(with: e)
            }
            else {
                self.mouseExited(with: e)
            }
        }
        
        super.updateTrackingAreas()
    }
    
    open override func mouseEntered(with theEvent: NSEvent) {
        if NSEvent.pressedMouseButtons == 0 {
            closeButton?.isHidden = false
        }
        super.mouseEntered(with: theEvent)
        self.needsDisplay = true
    }
    
    open override func mouseExited(with theEvent: NSEvent) {
        closeButton?.isHidden = true
        super.mouseExited(with: theEvent)
        self.needsDisplay = true
    }

    open override func mouseDown(with theEvent: NSEvent) {
        super.mouseDown(with: theEvent)
        if self.isEnabled == false {
            NSSound.beep()
        }
    }

    open override func resetCursorRects() {
        self.addCursorRect(self.bounds, cursor: NSCursor.arrow)
    }

    open func updateVisuals() {
        guard let tabButtonCell = self.tabButtonCell else {
            assertionFailure("TabButtonCell expected in drawRect(_:)"); return
        }

        // Layout close button first as title rect depends on it
        let closeButtonHeight = self.bounds.height - 8
        switch style.tabButtonCloseButtonPosition {
        case .left:
            closeButton?.frame = NSRect(x: 4, y: 4, width: closeButtonHeight, height:closeButtonHeight)
        case .right:
            closeButton?.frame = NSRect(x: self.bounds.width - closeButtonHeight - 4,
                                        y: 4, width: closeButtonHeight, height:closeButtonHeight)
        }

        if let iconFrames = self.style?.iconFrames(tabRect: self.frame) {
            let titleRect = tabButtonCell.titleRect(forBounds: self.bounds)
            let titleX = titleRect.origin.x + (titleRect.width - tabButtonCell.requiredMinimumWidth) / 2.0

            var iconFrame = iconFrames.iconFrame
            iconFrame.origin.x = titleX - iconFrame.width

            self.iconView?.frame = iconFrame
            self.alternativeTitleIconView?.frame = iconFrames.alternativeTitleIconFrame
        }

        let hasRoom = tabButtonCell.hasRoomToDrawFullTitle(inRect: self.bounds)
        self.alternativeTitleIconView?.isHidden = hasRoom
        self.toolTip = (hasRoom == true) ? nil : self.title
    }

    
    // MARK: - Editing
    
    internal func edit(fieldEditor: NSText, delegate: NSTextDelegate) {
        self.tabButtonCell?.edit(fieldEditor: fieldEditor, inView: self, delegate: delegate)
    }
    
    internal func finishEditing(fieldEditor: NSText, newValue: String) {
        self.tabButtonCell?.finishEditing(fieldEditor: fieldEditor, newValue: newValue)
    }
    
    //MARK: Closing
    
    @objc fileprivate func closeButtonPressed(){
        closeTabCallBack!(self, item)
    }
    
    func createCloseButton(closeCallBack : ((AnyObject?, AnyObject?) -> Void)?) {
        guard let callBack = closeCallBack else { return }
        closeTabCallBack = callBack
                
        closeButton = CloseButton()
        closeButton?.cell = CloseButtonCell()
        closeButton?.tabButton = self
        closeButton?.isBordered = false
                    
        closeButton?.wantsLayer = true
        closeButton?.layer?.cornerRadius = 2
        closeButton?.layer?.masksToBounds = true

        closeButton?.target = self
        closeButton?.action = #selector(closeButtonPressed)

        if let style = style, let cell = tabButtonCell {
            let img = NSImage(named: NSImage.stopProgressTemplateName)
            closeButton?.image = img?.imageWithTint(style.tabButtonTitleColor(cell))
        }

        closeButton?.imageScaling = .scaleProportionallyDown
        
        self.addSubview(closeButton!)
        
//        closeButton?.translatesAutoresizingMaskIntoConstraints = false
//        closeButton?.topAnchor.constraint(equalTo: self.topAnchor, constant: 4).isActive = true
//        closeButton?.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4).isActive = true
//        closeButton?.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4).isActive = true
//        closeButton?.heightAnchor.constraint(equalTo: closeButton!.widthAnchor, multiplier: 1).isActive = true
    }
}


class CloseButton: NSButton {
    weak var tabButton: TabButton!
    var trackingArea: NSTrackingArea? = nil
    
    private var highlightColor: NSColor? {
        guard let style = tabButton.style, let cell = tabButton.tabButtonCell  else { return nil }
        let color = style.tabButtonBackgroundColor(cell)
        return color.isDark ? color.lighterColor() : color.darkerColor()
    }
    
    override func updateTrackingAreas() {
        if let ta = trackingArea {
            self.removeTrackingArea(ta)
        }
        
        let opts: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        trackingArea = NSTrackingArea(rect: self.bounds, options: opts, owner: self)
        
        self.addTrackingArea(trackingArea!)
    }
            
    open override func mouseEntered(with theEvent: NSEvent) {
        (cell as? NSButtonCell)?.backgroundColor = highlightColor
    }
    
    open override func mouseExited(with event: NSEvent) {
        (cell as? NSButtonCell)?.backgroundColor = .clear
    }
}

class CloseButtonCell: NSButtonCell {
  override func drawImage(_ image: NSImage, withFrame frame: NSRect, in controlView: NSView) {
    super.drawImage(image, withFrame: frame.insetBy(dx: 1, dy: 1), in: controlView)
  }
}


// MARK: - TabButton+Style

extension Style {
    func tabButtonOffset(_ button: TabButton) -> Offset {
        guard let cell = button.tabButtonCell else { return .zero }
        return tabButtonOffset(cell)
    }

    func tabButtonBorderMask(_ button: TabButton) -> BorderMask? {
        guard let cell = button.tabButtonCell else { return nil }
        return tabButtonBorderMask(cell)
    }

    func tabButtonBackgroundColor(_ button: TabButton) -> NSColor {
        guard let cell = button.tabButtonCell else { return .clear }
        return tabButtonBackgroundColor(cell)
    }

    func tabButtonTitleColor(_ button: TabButton) -> NSColor {
        guard let cell = button.tabButtonCell else { return .clear }
        return tabButtonTitleColor(cell)
    }
}
