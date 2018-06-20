//
//  TimePitchStreamer.swift
//  TimePitchStreamer
//
//  Created by Syed Haris Ali on 6/5/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation
import AudioStreamer

/// The `TimePitchStreamer` demonstrates how to subclass the `Streamer` and add a time/pitch shift effect.
final class TimePitchStreamer: Streamer {
    
    /// An `AVAudioUnitTimePitch` used to perform the time/pitch shift effect
    let timePitchNode = AVAudioUnitTimePitch()
    
    /// A `Float` representing the pitch of the audio
    var pitch: Float {
        get {
            return timePitchNode.pitch
        }
        set {
            timePitchNode.pitch = newValue
        }
    }
    
    /// A `Float` representing the playback rate of the audio
    var rate: Float {
        get {
            return timePitchNode.rate
        }
        set {
            timePitchNode.rate = newValue
        }
    }
    
    // MARK: - Methods
    
    override func attachNodes() {
        super.attachNodes()
        engine.attach(timePitchNode)
    }
    
    override func connectNodes() {
        engine.connect(playerNode, to: timePitchNode, format: readFormat)
        engine.connect(timePitchNode, to: engine.mainMixerNode, format: readFormat)
    }
    
}
