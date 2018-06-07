//
//  Downloader+URLSessionDelegate.swift
//  AudioStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import os.log

extension Downloader: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line)

        totalBytesCount = response.expectedContentLength
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line, data.count)

        totalBytesReceived += Int64(data.count)
        progress = Float(totalBytesReceived) / Float(totalBytesCount)
        delegate?.download(self, didReceiveData: data, progress: progress)
        progressHandler?(data, progress)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line)

        state = .completed
        delegate?.download(self, completedWithError: error)
        completionHandler?(error)
    }
}
