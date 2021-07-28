//
//  Streamer+DownloadingDelegate.swift
//  AudioStreamer
//
//  Created by Syed Haris Ali on 6/5/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import os.log

extension Streamer: DownloadingDelegate {
    
    public func download(_ download: Downloading, completedWithError error: Error?) {
        if let error = error, let url = download.url {
            self.delegate?.streamer(self, failedDownloadWithError: error, forURL: url)
        }
    }
    
    public func download(_ download: Downloading, changedState downloadState: DownloadingState) {
    }
    
    public func download(_ download: Downloading, didReceiveData data: Data, progress: Float) {
        guard let parser = parser else {
            return
        }
        
        /// Parse the incoming audio into packets
        do {
            try parser.parse(data: data)
        } catch ParserError.fileTypeUnsupported {
            let currentUrl = url
            url = currentUrl
            play()
        } catch {
        }
        
        /// Once there's enough data to start producing packets we can use the data format
        if reader == nil, let _ = parser.dataFormat {
            do {
                reader = try Reader(parser: parser, readFormat: readFormat)
            } catch {
            }
        }
        /// Update the progress UI
        DispatchQueue.main.async { [weak self] in
            // Notify the delegate of the new progress value of the download
            self?.notifyDownloadProgress(progress)
        }
    }
    
}
