//
//  Downloader.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import os.log

/// <#Description#>
public class Downloader: NSObject, Downloadable {
    static let logger = OSLog(subsystem: "com.ausomeapps.fstreamer", category: "Downloader")
    
    public static var shared: Downloader = Downloader()
    
    // MARK: - Properties
    
    /// <#Description#>
    public var delegate: DownloadableDelegate?
    
    /// <#Description#>
    public var completionHandler: ((Error?) -> Void)?
    
    /// <#Description#>
    public var progressHandler: ((Data, Float) -> Void)?
    
    /// <#Description#>
    public var data: Data = Data()
    
    /// <#Description#>
    public var progress: Float = 0
    
    /// <#Description#>
    public var state: DownloadableState = .notStarted {
        didSet {
            delegate?.download(self, changedState: state)
        }
    }
    
    /// <#Description#>
    public var totalBytesReceived: Int64 = 0
    
    /// <#Description#>
    public var totalBytesLength: Int64 = 0
    
    /// <#Description#>
    public var url: URL? {
        didSet {
            if let url = url {
                data = Data()
                progress = 0.0
                state = .notStarted
                totalBytesLength = 0
                totalBytesReceived = 0
                task = session.dataTask(with: url)
            } else {
                task = nil
            }
        }
    }
    
    /// <#Description#>
    public var useCache = false {
        didSet {
            session.configuration.urlCache = useCache ? URLCache.shared : nil
        }
    }
    
    /// <#Description#>
    fileprivate lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    /// <#Description#>
    fileprivate var task: URLSessionDataTask?
    
    // MARK: - Initializers
    
    deinit {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line)
    }
    
    // MARK: - Methods
    
    /// <#Description#>
    public func start() {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line)
        
        guard let task = task else {
            return
        }
        
        switch state {
        case .completed, .started:
            return
        default:
            state = .started
            task.resume()
        }
    }
    
    /// <#Description#>
    public func pause() {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line)
        
        guard let task = task else {
            return
        }
        
        guard state == .started else {
            return
        }
        
        state = .paused
        task.suspend()
    }
    
    /// <#Description#>
    public func stop() {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line)
        
        guard let task = task else {
            return
        }
        
        guard state == .started else {
            return
        }
        
        state = .stopped
        task.cancel()
    }
}
