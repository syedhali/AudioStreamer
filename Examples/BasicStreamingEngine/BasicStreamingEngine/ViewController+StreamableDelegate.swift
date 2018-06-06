//
//  ViewController+Streamer.swift
//  BasicStreamingEngine
//
//  Created by Syed Haris Ali on 6/5/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import FileStreamer
import os.log

extension ViewController: StreamableDelegate {
    
    func streamer(_ streamer: Streamable, updatedDownloadProgress progress: Float, forURL url: URL) {
        os_log("%@ - %d [%.2f]", log: ViewController.logger, type: .debug, #function, #line, progress)
        
        progressSlider.progress = progress
    }
    
    func streamer(_ streamer: Streamable, changedState state: StreamableState) {
        os_log("%@ - %d [%@]", log: ViewController.logger, type: .debug, #function, #line, String(describing: state))
        
        switch state {
        case .playing:
            playButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        case .paused, .stopped:
            playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        }
    }
    
    func streamer(_ streamer: Streamable, updatedCurrentTime currentTime: TimeInterval) {
        os_log("%@ - %d [%@]", log: ViewController.logger, type: .debug, #function, #line, currentTime.toMMSS())
        
        if !isSeeking {
            progressSlider.value = Float(currentTime)
            currentTimeLabel.text = currentTime.toMMSS()
        }
    }
    
    func streamer(_ streamer: Streamable, updatedDuration duration: TimeInterval) {
        let formattedDuration = duration.toMMSS()
        os_log("%@ - %d [%@]", log: ViewController.logger, type: .debug, #function, #line, formattedDuration)
        
        durationTimeLabel.text = formattedDuration
        durationTimeLabel.isEnabled = true
        progressSlider.isEnabled = true
        progressSlider.minimumValue = 0.0
        progressSlider.maximumValue = Float(duration)
    }
    
}
