//
//  DefaultStyle.swift
//  KPCTabsControl
//
//  Created by Christian Tietze on 10/08/16.
//  Licensed under the MIT License (see LICENSE file)
//

import Cocoa

public enum TitleDefaults {
    static let alignment = NSTextAlignment.center
    static let lineBreakMode = NSLineBreakMode.byTruncatingMiddle
}

/// Default implementation of Themed Style

extension ThemedStyle {
    
    // MARK: - Tab Buttons
    public var tabButtonsMargin: (left: CGFloat, right: CGFloat) { (0.0, 0.0)}

    public var tabButtonCloseButtonPosition: CloseButtonPosition { .left }

    public func tabButtonOffset(_ button: TabButtonCell) -> Offset {
        return NSPoint()
    }

    public func tabButtonBorderMask(_ button: TabButtonCell) -> BorderMask? {
        return BorderMask.all()
    }
    
    public func tabButtonBackgroundColor(_ button: TabButtonCell) -> NSColor {
        if button.isSelected {
            return self.theme.selectedTabButtonTheme.backgroundColor
        } else {
            return self.theme.tabButtonTheme.backgroundColor
        }
    }
  
    public func tabButtonTitleColor(_ button: TabButtonCell) -> NSColor {
        if button.isSelected {
            return self.theme.selectedTabButtonTheme.titleColor
        } else {
            return self.theme.tabButtonTheme.titleColor
        }
    }
  
    // MARK: - Tab Button Titles

    public func iconFrames(tabRect rect: NSRect) -> IconFrames {
        let verticalPadding: CGFloat = 5.0
        let paddedHeight = rect.height - 2*verticalPadding
        let x = rect.width / 2.0 - paddedHeight / 2.0
        
        return (NSMakeRect(10.0, verticalPadding, paddedHeight, paddedHeight),
                NSMakeRect(x, verticalPadding, paddedHeight, paddedHeight))
    }
        
    public func titleRect(title: NSAttributedString, inBounds rect: NSRect, showingIcon: Bool) -> NSRect {
        
        let titleSize = title.size()
        let fullWidthRect = NSRect(x: NSMinX(rect),
                                   y: NSMidY(rect) - titleSize.height/2.0 - 0.5,
                                   width: NSWidth(rect),
                                   height: titleSize.height)
        
        return self.paddedRectForIcon(fullWidthRect, showingIcon: showingIcon)
    }
    
    fileprivate func paddedRectForIcon(_ rect: NSRect, showingIcon: Bool) -> NSRect {
        guard showingIcon else {
            return rect
        }
        
        let iconRect = self.iconFrames(tabRect: rect).iconFrame
        let pad = NSMaxX(iconRect)+titleMargin
        return rect.offsetBy(dx: pad, dy: 0.0).shrinkBy(dx: pad, dy: 0.0)
    }
    
    public func titleEditorSettings() -> TitleEditorSettings {
        return (textColor: NSColor(calibratedWhite: 1.0/6, alpha: 1.0),
                font: self.theme.tabButtonTheme.titleFont,
                alignment: TitleDefaults.alignment)
    }
    
    public func attributedTitle(_ button: TabButtonCell) -> NSAttributedString {
        let activeTheme = self.theme.tabButtonTheme(fromSelectionState: button.selectionState)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = TitleDefaults.alignment
        paragraphStyle.lineBreakMode = TitleDefaults.lineBreakMode
        
        let attributes = [NSAttributedString.Key.foregroundColor : activeTheme.titleColor,
                          NSAttributedString.Key.font : activeTheme.titleFont,
                          NSAttributedString.Key.paragraphStyle : paragraphStyle]
        
        return NSAttributedString(string: button.title, attributes: attributes)
    }

    // MARK: - Tabs Control
    
    public func tabsControlBorderMask() -> BorderMask? {
        return BorderMask.top.union(BorderMask.bottom)
    }

    // MARK: - Drawing

    public func drawTabsControlBezel(frame: NSRect) {
        self.theme.tabsControlTheme.backgroundColor.setFill()
        
        frame.fill()
        
        let borderDrawing = BorderDrawing.fromMask(frame, borderMask: self.tabsControlBorderMask())
        self.drawBorder(borderDrawing, color: self.theme.tabsControlTheme.borderColor)
    }
    
    public func drawTabButtonBezel(_ button: TabButtonCell, in frame: NSRect) {
        let activeTheme = button.isSelected ? self.theme.selectedTabButtonTheme : self.theme.tabButtonTheme

        if let gradTheme = activeTheme as? GradientTabButtonTheme {
          let gradient = NSGradient(colors: [gradTheme.topBackgroundColor, gradTheme.bottomBackgroundColor])
          gradient?.draw(in: frame, angle: 90.0)
        } else {
          tabButtonBackgroundColor(button).setFill()
          frame.fill()
        }

        let borderDrawing = BorderDrawing.fromMask(frame, borderMask: self.tabButtonBorderMask(button))
        self.drawBorder(borderDrawing, color: activeTheme.borderColor)
    }

    fileprivate func drawBorder(_ border: BorderDrawing, color: NSColor) {
        switch border {
        case let .draw(borderRects: borderRects, rectCount: _):
            color.setFill()
            color.setStroke()
            borderRects.fill()
        default:
            return
        }
    }
}

// MARK: -

private enum BorderDrawing {
    case empty
    case draw(borderRects: [NSRect], rectCount: Int)
    
    fileprivate static func fromMask(_ sourceRect: NSRect, borderMask: BorderMask?) -> BorderDrawing {
        
        guard let mask = borderMask else { return .empty }

        var outputCount: Int = 0
        var remainderRect = NSZeroRect
        var borderRects: [NSRect] = [NSZeroRect, NSZeroRect, NSZeroRect, NSZeroRect]
        
        if mask.contains(.top) {
            NSDivideRect(sourceRect, &borderRects[outputCount], &remainderRect, 1.0, .minY)
            outputCount += 1
        }
        if mask.contains(.left) {
            NSDivideRect(sourceRect, &borderRects[outputCount], &remainderRect, 1.0, .minX)
            outputCount += 1
        }
        if mask.contains(.right) {
            NSDivideRect(sourceRect, &borderRects[outputCount], &remainderRect, 1.0, .maxX)
            outputCount += 1
        }
        if mask.contains(.bottom) {
            NSDivideRect(sourceRect, &borderRects[outputCount], &remainderRect, 1.0, .maxY)
            outputCount += 1
        }
        
        guard outputCount > 0 else { return .empty }
        
        return .draw(borderRects: borderRects, rectCount: outputCount)
    }
}

// MARK: - 

/**
 *  The default TabsControl style. Used with the DefaultTheme, it provides an experience similar to Apple's Numbers.app.
 */
public struct DefaultStyle: ThemedStyle {
    public let theme: Theme
    public let tabButtonWidth: TabWidth
    public let tabsControlRecommendedHeight: CGFloat = 24.0

    public init(theme: Theme = DefaultTheme(),
                tabButtonWidth: TabWidth = .flexible(min: 50, max: 150),
                tabButtonsMargin: (CGFloat, CGFloat) = (0.0, 0.0)) {
        self.theme = theme
        self.tabButtonWidth = tabButtonWidth
    }
}

