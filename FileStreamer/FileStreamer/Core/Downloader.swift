//
//  Downloader.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import os.log

public class Downloader: NSObject {
    static let logger = OSLog(subsystem: "com.ausomeapps.fstreamer", category: "Downloader")
    
    var delegate: DownloadableDelegate?
    var completionHandler: ((Error?) -> Void)?
    
    var data: Data?
    var progress: Float = 0
    var state: DownloadableState = .notStarted
    var totalBytesReceived: Int64 = 0
    var totalBytesLength: Int64 = 0
    var url: URL
    
    lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    lazy var task: URLSessionDataTask = {
        return session.dataTask(with: url)
    }()
    
    public required init(url: URL) {
        self.url = url
    }
}
