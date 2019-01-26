//
//  ViewController+Streamer.swift
//  TimePitchStreamer-macOS
//
//  Created by Haris Ali on 1/26/19.
//  Copyright © 2019 Ausome Apps LLC. All rights reserved.
//

import AudioStreamer
import AVFoundation
import Cocoa
import os.log

extension ViewController: StreamingDelegate {
    
    func streamer(_ streamer: Streaming, failedDownloadWithError error: Error, forURL url: URL) {
        os_log("%@ - %d [%@]", log: ViewController.logger, type: .debug, #function, #line, error.localizedDescription)
        
//        let alert = UIAlertController(title: "Download Failed", message: error.localizedDescription, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
//            alert.dismiss(animated: true, completion: nil)
//        }))
//        show(alert, sender: self)
    }
    
    func streamer(_ streamer: Streaming, updatedDownloadProgress progress: Float, forURL url: URL) {
        os_log("%@ - %d [%.2f]", log: ViewController.logger, type: .debug, #function, #line, progress)
        
        progressIndicator.doubleValue = Double(progress * 100)
        if progress >= 1 {
            progressIndicator.isHidden = true
            playbackControlsStackView.setVisibilityPriority(.notVisible, for: progressIndicator)
        }
    }
    
    func streamer(_ streamer: Streaming, changedState state: StreamingState) {
        os_log("%@ - %d [%@]", log: ViewController.logger, type: .debug, #function, #line, String(describing: state))

        switch state {
        case .playing:
            playButton.image = NSImage(named: "Pause")
        case .paused, .stopped:
            playButton.image = NSImage(named: "Play")
        }
    }
    
    func streamer(_ streamer: Streaming, updatedCurrentTime currentTime: TimeInterval) {
        os_log("%@ - %d [%@]", log: ViewController.logger, type: .debug, #function, #line, currentTime.toMMSS())
        
        if !isSeeking {
            seekSlider.doubleValue = Double(currentTime)
            currentTimeLabel.stringValue = currentTime.toMMSS()
        }
    }
    
    func streamer(_ streamer: Streaming, updatedDuration duration: TimeInterval) {
        let formattedDuration = duration.toMMSS()
        os_log("%@ - %d [%@]", log: ViewController.logger, type: .debug, #function, #line, formattedDuration)

        seekSlider.minValue = 0
        seekSlider.maxValue = Double(duration)
        currentTimeLabel.isEnabled = true
        durationTimeLabel.stringValue = formattedDuration
        durationTimeLabel.isEnabled = true
        playButton.isEnabled = true
    }
    
}
