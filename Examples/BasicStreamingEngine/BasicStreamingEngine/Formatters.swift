//
//  Formatters.swift
//  BasicStreamingEngine
//
//  Created by Syed Haris Ali on 1/7/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation

public class MMSSFormatter: NumberFormatter {
    override public func string(from number: NSNumber) -> String? {
        let totalSeconds = Int(ceil(number.floatValue))
        let secondsComponent = totalSeconds % 60
        let minutesComponent = (totalSeconds / 60) % 60;
        return String(format: "%02d:%02d", minutesComponent, secondsComponent)
    }
}
