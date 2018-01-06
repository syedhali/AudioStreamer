//
//  Downloader+Downloadable.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import os.log

extension Downloader: Downloadable {    
    func start() {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line)
        
        state = .started
        task.resume()
    }
    
    func pause() {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line)
     
        state = .paused
        task.suspend()
    }
    
    func stop() {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line)
        
        state = .stopped
        task.cancel()
    }
}
