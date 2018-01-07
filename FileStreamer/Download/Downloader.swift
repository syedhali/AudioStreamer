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
    public var url: URL
    
    /// <#Description#>
    var useCache = true {
        didSet {
            session.configuration.urlCache = useCache ? URLCache.shared : nil
        }
    }
    
    /// <#Description#>
    fileprivate lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    /// <#Description#>
    fileprivate lazy var task: URLSessionDataTask = {
        return session.dataTask(with: url)
    }()
    
    // MARK: - Initializers
    
    /// <#Description#>
    ///
    /// - Parameter url: <#url description#>
    public required init(url: URL) {
        self.url = url
    }
    
    // MARK: - Methods
    
    /// <#Description#>
    public func start() {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line)
        
        state = .started
        task.resume()
    }
    
    /// <#Description#>
    public func pause() {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line)
        
        state = .paused
        task.suspend()
    }
    
    /// <#Description#>
    public func stop() {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line)
        
        state = .stopped
        task.cancel()
    }
}
