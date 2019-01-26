//
//  NSView+Filter.swift
//  TimePitchStreamer-iOS
//
//  Created by Haris Ali on 1/26/19.
//  Copyright © 2019 Ausome Apps LLC. All rights reserved.
//

import Cocoa

extension NSView {
    
    /// <#Description#>
    ///
    /// - Parameter color: <#color description#>
    func setFilterColor(_ color: NSColor) {
        let colorFilter = CIFilter(name: "CIFalseColor")!
        colorFilter.setDefaults()
        colorFilter.setValue(CIColor(cgColor: color.cgColor), forKey: "inputColor0")
        colorFilter.setValue(CIColor(cgColor: color.cgColor), forKey: "inputColor1")
        contentFilters = [colorFilter]
    }
    
}
