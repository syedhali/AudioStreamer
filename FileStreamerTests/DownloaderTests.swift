//
//  DownloaderTests.swift
//  DownloaderTests
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import XCTest
@testable import FileStreamer

class DownloaderTests: XCTestCase {
    
    func testInitialState() {
        let url = RemoteFileURL.claire.mp3
        let downloader = Downloader(url: url)
        XCTAssertEqual(downloader.url, url)
        XCTAssertNotNil(downloader.data)
        XCTAssertEqual(downloader.data.count, 0)
        XCTAssertEqual(downloader.progress, 0.0)
        XCTAssertEqual(downloader.totalBytesReceived, 0)
        XCTAssertEqual(downloader.totalBytesLength, 0)
        XCTAssertEqual(downloader.state, .notStarted)
    }
    
    func testDownloadMP3() {
        let expectation = XCTestExpectation(description: "Download MP3")
        
        let url = RemoteFileURL.theLastOnes.mp3
        let downloader = Downloader(url: url)
        downloader.start()
        downloader.completionHandler = {
            XCTAssertEqual(downloader.state, .completed)
            XCTAssertNil($0)
            expectation.fulfill()
        }
        XCTAssertEqual(downloader.state, .started)
        
        self.wait(for: [expectation], timeout: 10)
    }
    
    func testDownloadAAC() {
        let expectation = XCTestExpectation(description: "Download AAC")
        
        let url = RemoteFileURL.theLastOnes.aac
        let downloader = Downloader(url: url)
        downloader.start()
        downloader.completionHandler = {
            XCTAssertEqual(downloader.state, .completed)
            XCTAssertNil($0)
            expectation.fulfill()
        }
        XCTAssertEqual(downloader.state, .started)
        
        self.wait(for: [expectation], timeout: 10)
    }
    
    func testDownloadWAV() {
        let expectation = XCTestExpectation(description: "Download WAV")
        
        let url = RemoteFileURL.theLastOnes.wav
        let downloader = Downloader(url: url)
        downloader.start()
        downloader.completionHandler = {
            XCTAssertEqual(downloader.state, .completed)
            XCTAssertNil($0)
            expectation.fulfill()
        }
        XCTAssertEqual(downloader.state, .started)
        
        self.wait(for: [expectation], timeout: 10)
    }
}
