//
//  TabButtonCell.swift
//  KPCTabsControl
//
//  Created by Cédric Foellmi on 14/06/16.
//  Licensed under the MIT License (see LICENSE file)
//

import Foundation
import AppKit


let titleMargin: CGFloat = 5.0

public class TabButtonCell: NSButtonCell {
    
    var hasTitleAlternativeIcon: Bool = false

    var selectionState: TabSelectionState {
        return self.isEnabled == false ? TabSelectionState.unselectable : (self.isSelected ? TabSelectionState.selected : TabSelectionState.normal)
    }

    var showsIcon: Bool {
        get { return (self.controlView as! TabButton).image != nil }
    }
    
    var closeButtonSize: CGFloat {
        get { return (self.controlView as! TabButton).closeButtonSize }
    }

    var showsMenu: Bool {
        get { return self.menu?.items.count > 0 }
    }

    var buttonPosition: TabPosition = .middle {
        didSet { self.controlView?.needsDisplay = true }
    }

    var requiredMinimumWidth: CGFloat {
        let title = self.style.attributedTitle(self)
        return title.size().width + 2.0*titleMargin
    }
  
    var style: Style!

    public var isSelected: Bool {
        get { return self.state == NSControl.StateValue.on }
    }

    public var dragging: Bool = false

    // MARK: - Initializers & Copy
    
    override init(textCell aString: String) {
        super.init(textCell: aString)

        self.isBordered = true
        self.backgroundStyle = .light
        self.highlightsBy = NSCell.StyleMask.changeBackgroundCellMask
        self.lineBreakMode = .byTruncatingTail
        self.focusRingType = .none
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func copy() -> Any {
        let copy = TabButtonCell(textCell: self.title)

        copy.style = style
        copy.buttonPosition = self.buttonPosition
        copy.hasTitleAlternativeIcon = self.hasTitleAlternativeIcon

        copy.state = self.state
        copy.isHighlighted = self.isHighlighted
        
        return copy
    }
    
    // MARK: - Properties & Rects

    static func popupImage() -> NSImage {
        let path = Bundle(for: self).pathForImageResource("KPCPullDownTemplate")!
        return NSImage(contentsOfFile: path)!.imageWithTint(NSColor.darkGray)
    }

    func hasRoomToDrawFullTitle(inRect rect: NSRect) -> Bool {
        let titleDrawRect = self.titleRect(forBounds: rect)
        return self.requiredMinimumWidth <= NSWidth(titleDrawRect)
    }

    public override func cellSize(forBounds aRect: NSRect) -> NSSize {
        let title = self.style.attributedTitle(self)
        let titleSize = title.size()
        let popupSize = (self.menu == nil) ? NSZeroSize : TabButtonCell.popupImage().size
        let cellSize = NSMakeSize(titleSize.width + (popupSize.width * 2) + 36, max(titleSize.height, popupSize.height))
        self.controlView?.invalidateIntrinsicContentSize()
        return cellSize
    }
    
    fileprivate func popupRectWithFrame(_ cellFrame: NSRect) -> NSRect {
        var popupRect = NSZeroRect
        popupRect.size = TabButtonCell.popupImage().size
        popupRect.origin = NSMakePoint(NSMaxX(cellFrame) - NSWidth(popupRect) - 8, NSMidY(cellFrame) - NSHeight(popupRect) / 2)
        return popupRect
    }
    
    public override func trackMouse(with theEvent: NSEvent,
                                    in cellFrame: NSRect,
                                    of controlView: NSView,
                                    untilMouseUp flag: Bool) -> Bool {
        if self.hitTest(for: theEvent,
                                in: controlView.superview!.frame,
                                of: controlView.superview!) != NSCell.HitResult()
        {
        
            let popupRect = self.popupRectWithFrame(cellFrame)
            let location = controlView.convert(theEvent.locationInWindow, from: nil)
            
            if self.menu?.items.count > 0 && NSPointInRect(location, popupRect) {
                self.menu?.popUp(positioning: self.menu!.items.first,
                                                    at: NSMakePoint(NSMidX(popupRect), NSMaxY(popupRect)),
                                                    in: controlView)
                
                return true
            }
        }
        
        return super.trackMouse(with: theEvent, in: cellFrame, of: controlView, untilMouseUp: flag)
    }
    
    public override func titleRect(forBounds theRect: NSRect) -> NSRect {
        let title = self.style.attributedTitle(self)
        var rect = self.style.titleRect(title: title, inBounds: theRect, showingIcon: self.showsIcon)        
        rect = rect.offsetBy(dx: titleMargin*2, dy: 0).shrinkBy(dx: titleMargin*2, dy: 0)
        
        if self.dragging {
            rect = rect.shrinkBy(dx: titleMargin*2, dy: 0)
        }
        if self.closeButtonSize != 0 {
            rect.size.width -= closeButtonSize + 2*titleMargin
        }
        if self.showsMenu {
            let popupRect = self.popupRectWithFrame(theRect)
            rect.size.width -= popupRect.width + 2*titleMargin
        }
        if image != nil, let iconFrames = style?.iconFrames(tabRect: theRect) {
            rect = rect.offsetBy(dx: iconFrames.iconFrame.width, dy: 0).shrinkBy(dx: iconFrames.iconFrame.width, dy: 0)
        }
        return rect
    }

    // MARK: - Editing

    func edit(fieldEditor: NSText, inView view: NSView, delegate: NSTextDelegate) {

        self.isHighlighted = true

        let frame = self.editingRectForBounds(view.bounds)
        self.select(withFrame: frame,
                             in: view,
                             editor: fieldEditor,
                             delegate: delegate,
                             start: 0,
                             length: 0)

        fieldEditor.drawsBackground = false
        fieldEditor.isHorizontallyResizable = true
        fieldEditor.isEditable = true

        let editorSettings = self.style.titleEditorSettings()
        fieldEditor.font = editorSettings.font
        fieldEditor.alignment = editorSettings.alignment
        fieldEditor.textColor = editorSettings.textColor

        // Replace content so that resizing is triggered
        fieldEditor.string = ""
        fieldEditor.insertText(self.title ?? "")
        fieldEditor.selectAll(self)

        self.title = ""
    }

    func finishEditing(fieldEditor: NSText, newValue: String) {
        self.endEditing(fieldEditor)
        self.title = newValue
    }

    func editingRectForBounds(_ rect: NSRect) -> NSRect {
        return self.titleRect(forBounds: rect)//.offsetBy(dx: 0, dy: 1))
    }
    
    // MARK: - Drawing

    public override func draw(withFrame frame: NSRect, in controlView: NSView) {
        self.style.drawTabButtonBezel(self, in: frame)

        if self.hasRoomToDrawFullTitle(inRect: frame) || self.hasTitleAlternativeIcon == false {
            let title = self.style.attributedTitle(self)
            _ = self.drawTitle(title, withFrame: frame, in: controlView)
        }

        if self.showsMenu {
            self.drawPopupButtonWithFrame(frame)
        }

        if let image = self.image {
            self.drawImage(image, withFrame: frame, in: controlView)
        }
    }

    public override func drawImage(_ image: NSImage, withFrame frame: NSRect, in controlView: NSView) {
        if let iconFrames = style?.iconFrames(tabRect: frame) {
            let titleRect = self.titleRect(forBounds: frame)
            let titleX: CGFloat
            if self.hasRoomToDrawFullTitle(inRect: frame) {
                titleX = titleRect.origin.x + (titleRect.width - requiredMinimumWidth) / 2.0
            } else {
                titleX = titleRect.origin.x
            }
            

            var iconFrame = iconFrames.iconFrame
            iconFrame.origin.x = titleX - iconFrame.width
            self.image?.draw(in: iconFrame)
        }
    }

    public override func drawTitle(_ title: NSAttributedString,
                                   withFrame frame: NSRect,
                                   in controlView: NSView) -> NSRect {

        let titleRect = self.titleRect(forBounds: frame)
        title.draw(in: titleRect)
        return titleRect
    }

    fileprivate func drawPopupButtonWithFrame(_ frame: NSRect) {
        let image = TabButtonCell.popupImage()
        image.draw(in: self.popupRectWithFrame(frame),
                         from: NSZeroRect,
                         operation: .sourceOver,
                         fraction: 1.0,
                         respectFlipped: true,
                         hints: nil)
    }
}
