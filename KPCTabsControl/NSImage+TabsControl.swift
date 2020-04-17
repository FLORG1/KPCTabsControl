//
//  NSImage+KPCTabsControl.swift
//  KPCTabsControl
//
//  Created by Cédric Foellmi on 14/06/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

extension NSImage {
    internal func imageWithTint(_ tint: NSColor) -> NSImage {
        var imageRect = NSZeroRect;
        imageRect.size = self.size;
        
        let highlightImage = NSImage(size: imageRect.size)

        highlightImage.lockFocus()
        self.drawWithTint(tint, in: imageRect)
        highlightImage.unlockFocus()

        return highlightImage;
    }

  internal func drawWithTint(_ tint: NSColor, in rect: NSRect) {
    self.draw(in: rect, from: NSZeroRect, operation: .sourceOver, fraction: 1.0)
    tint.set()
    rect.fill(using: .sourceAtop)
  }
}
