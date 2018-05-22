//
//  ViewController+DownloaderDelegate.swift
//  BasicStreamingEngine
//
//  Created by Syed Haris Ali on 1/7/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import FileStreamer
import os.log

extension ViewController: DownloadableDelegate {
    func download(_ download: Downloadable, completedWithError error: Error?) {
        os_log("%@ - %d [error: %@]", log: ViewController.logger, type: .debug, #function, #line, String(describing: error?.localizedDescription))
    }
    
    func download(_ download: Downloadable, changedState state: DownloadableState) {
        os_log("%@ - %d [state: %@]", log: ViewController.logger, type: .debug, #function, #line, String(describing: state))
    }
    
    func download(_ download: Downloadable, didReceiveData data: Data, progress: Float) {
        os_log("%@ - %d", log: ViewController.logger, type: .debug, #function, #line)
        
        guard let parser = parser else {
            os_log("Expected parser, bail...", log: ViewController.logger, type: .error)
            return
        }
        
        /// Parse the incoming audio into packets
        parser.parse(data: data)
        
        /// Once there's enough data to start producing packets we can use the data format
        if let _ = parser.dataFormat, reader == nil {
            do {
                reader = try Reader(parser: parser, readFormat: TapReader.format)
            } catch ReaderError.unableToCreateConverter(let status) {
                os_log("Failed to create converter for reader [OSStatus: %i]", log: ViewController.logger, type: .error, status)
            } catch {
                os_log("Failed to create reader: %@", log: ViewController.logger, type: .error, error.localizedDescription)
            }
        }
        
        /// Update the progress UI
        DispatchQueue.main.async {
            [weak self] in
            self?.progressSlider.progress = progress
            
            if let duration = self?.parser?.duration {
                let formattedDuration = self?.timeFormatter.string(from: duration)
                self?.durationTimeLabel.text = formattedDuration
                self?.durationTimeLabel.isEnabled = true
            }
            
            if let totalFrames = self?.parser?.totalFrameCount {
                self?.progressSlider.isEnabled = true
                self?.progressSlider.minimumValue = 0.0
                self?.progressSlider.maximumValue = Float(totalFrames)
            }
        }
    }
}
