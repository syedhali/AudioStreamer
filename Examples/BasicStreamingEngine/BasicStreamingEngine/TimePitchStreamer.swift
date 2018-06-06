//
//  TimePitchStreamer.swift
//  BasicStreamingEngine
//
//  Created by Syed Haris Ali on 6/5/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation
import FileStreamer

class TimePitchStreamer: Streamer {
    
    let timePitchNode = AVAudioUnitTimePitch()
    
    var pitch: Float {
        get {
            return timePitchNode.pitch
        }
        set {
            timePitchNode.pitch = newValue
        }
    }
    
    var rate: Float {
        get {
            return timePitchNode.rate
        }
        set {
            timePitchNode.rate = newValue
        }
    }
    
    override func attachNodes() {
        super.attachNodes()
        engine.attach(timePitchNode)
    }
    
    override func connectNodes() {
        engine.connect(playerNode, to: timePitchNode, format: readFormat)
        engine.connect(timePitchNode, to: engine.mainMixerNode, format: readFormat)
    }
    
}
