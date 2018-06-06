//
//  Streamer+DownloadableDelegate.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 6/5/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import os.log

extension Streamer: DownloadableDelegate {
    
    public func download(_ download: Downloadable, completedWithError error: Error?) {
        os_log("%@ - %d [error: %@]", log: Streamer.logger, type: .debug, #function, #line, String(describing: error?.localizedDescription))
    }
    
    public func download(_ download: Downloadable, changedState downloadState: DownloadableState) {
        os_log("%@ - %d [state: %@]", log: Streamer.logger, type: .debug, #function, #line, String(describing: downloadState))
    }
    
    public func download(_ download: Downloadable, didReceiveData data: Data, progress: Float) {
        os_log("%@ - %d", log: Streamer.logger, type: .debug, #function, #line)

        guard let parser = parser else {
            os_log("Expected parser, bail...", log: Streamer.logger, type: .error)
            return
        }
        
        /// Parse the incoming audio into packets
        do {
            try parser.parse(data: data)
        } catch {
            os_log("Failed to parse: %@", log: Streamer.logger, type: .error, error.localizedDescription)
        }
        
        /// Once there's enough data to start producing packets we can use the data format
        if reader == nil, let _ = parser.dataFormat {
            do {
                reader = try Reader(parser: parser, readFormat: readFormat)
            } catch {
                os_log("Failed to create reader: %@", log: Streamer.logger, type: .error, error.localizedDescription)
            }
        }
        
        /// Update the progress UI
        DispatchQueue.main.async {
            [weak self] in
            
            // Notify the delegate of the new progress value of the download
            self?.notifyDownloadProgress(progress)
            
            // Check if we have the duration
            self?.checkDurationUpdated()
        }
    }
    
    func checkDurationUpdated() {
        func update(_ newDuration: TimeInterval) {
            self.duration = newDuration
            notifyDurationUpdate(newDuration)
        }
        
        if let newDuration = parser?.duration {
            if duration == nil {
                update(newDuration)
            } else if let oldDuration = duration, oldDuration < newDuration {
                update(newDuration)
            }
        }
    }
    
}
