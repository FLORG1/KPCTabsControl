//
//  Style.swift
//  KPCTabsControl
//
//  Created by Christian Tietze on 10/08/16.
//  Licensed under the MIT License (see LICENSE file)
//

import Cocoa

public typealias IconFrames = (iconFrame: NSRect, alternativeTitleIconFrame: NSRect)

public typealias TitleEditorSettings = (textColor: NSColor, font: NSFont, alignment: NSTextAlignment)

/**
 *  The Style protocol defines all the necessary things to let KPCTabsControl draw itself with tabs.
 */
public protocol Style {
    // Tab Buttons
    var tabButtonWidth: TabWidth { get }
    var tabButtonsMargin: (left: CGFloat, right: CGFloat) { get }
    var tabButtonCloseButtonPosition: CloseButtonPosition { get }

    func tabButtonOffset(_ button: TabButtonCell) -> Offset
    func tabButtonBorderMask(_ button: TabButtonCell) -> BorderMask?
    func tabButtonBackgroundColor(_ button: TabButtonCell) -> NSColor
    func tabButtonTitleColor(_ button: TabButtonCell) -> NSColor
  
    // Tab Button Titles
    func iconFrames(tabRect rect: NSRect) -> IconFrames
    func titleRect(title: NSAttributedString, inBounds rect: NSRect, showingIcon: Bool) -> NSRect
    func titleEditorSettings() -> TitleEditorSettings
    func attributedTitle(_ button: TabButtonCell) -> NSAttributedString

    // Tabs Control
    var tabsControlRecommendedHeight: CGFloat { get }
    func tabsControlBorderMask() -> BorderMask?
    
    // Drawing
    func drawTabButtonBezel(_ button: TabButtonCell, in frame: NSRect)
    func drawTabsControlBezel(frame: NSRect)
}

/**
 *  The default Style protocol doesn't necessary have a theme associated with it, for custom styles.
 *  However, provided styles (Numbers.app-like, Safari and Chrome) have an associated theme.
 */
public protocol ThemedStyle : Style {
    var theme: Theme { get }
}

