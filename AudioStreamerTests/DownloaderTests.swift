//
//  DownloaderTests.swift
//  DownloaderTests
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import XCTest
@testable import AudioStreamer

class DownloaderTests: XCTestCase {
    
    func testInitialState() {
        let url = RemoteFileURL.claire.mp3
        Downloader.shared.url = url
        XCTAssertEqual(Downloader.shared.url, url)
        XCTAssertEqual(Downloader.shared.progress, 0.0)
        XCTAssertEqual(Downloader.shared.totalBytesReceived, 0)
        XCTAssertEqual(Downloader.shared.totalBytesCount, 0)
        XCTAssertEqual(Downloader.shared.state, .notStarted)
    }
    
    func testDownloadMP3() {
        let expectation = XCTestExpectation(description: "Download MP3")
        
        let url = RemoteFileURL.theLastOnes.mp3
        Downloader.shared.url = url
        Downloader.shared.start()
        Downloader.shared.completionHandler = {
            XCTAssertEqual(Downloader.shared.state, .completed)
            XCTAssertNil($0)
            expectation.fulfill()
        }
        XCTAssertEqual(Downloader.shared.state, .started)
        
        self.wait(for: [expectation], timeout: 10)
    }
    
    func testDownloadAAC() {
        let expectation = XCTestExpectation(description: "Download AAC")
        
        let url = RemoteFileURL.theLastOnes.aac
        Downloader.shared.url = url
        Downloader.shared.start()
        Downloader.shared.completionHandler = {
            XCTAssertEqual(Downloader.shared.state, .completed)
            XCTAssertNil($0)
            expectation.fulfill()
        }
        XCTAssertEqual(Downloader.shared.state, .started)
        
        self.wait(for: [expectation], timeout: 10)
    }
    
    func testDownloadWAV() {
        let expectation = XCTestExpectation(description: "Download WAV")
        
        let url = RemoteFileURL.theLastOnes.wav
        Downloader.shared.url = url
        Downloader.shared.start()
        Downloader.shared.completionHandler = {
            XCTAssertEqual(Downloader.shared.state, .completed)
            XCTAssertNil($0)
            expectation.fulfill()
        }
        XCTAssertEqual(Downloader.shared.state, .started)
        
        self.wait(for: [expectation], timeout: 30)
    }
}
