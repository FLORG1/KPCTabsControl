//
//  TabsControlCell.swift
//  KPCTabsControl
//
//  Created by Cédric Foellmi on 30/07/16.
//  Licensed under the MIT License (see LICENSE file)
//

import Cocoa

class TabsControlCell: NSCell {
    
    var style: Style! {
        didSet { self.controlView?.needsDisplay = true }
    }
   
    override init(textCell aString: String) {
        super.init(textCell: aString)
        
        self.isBordered = true
        self.backgroundStyle = .light
        self.focusRingType = .none
        self.isEnabled = false
        self.font = NSFont.systemFont(ofSize: 13)        
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func cellSize(forBounds aRect: NSRect) -> NSSize {
        return NSMakeSize(36.0, 0.0)
    }
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        //we don't draw anything before add new tab
    }
}
