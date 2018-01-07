//
//  ParserTests.swift
//  FileStreamerTests
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import XCTest
import os.log
@testable import FileStreamer

class ParserTests: XCTestCase {
    
    func testParseDownloadedMP3() {
        let expectation = XCTestExpectation(description: "Download & Parse MP3")
        
        let url = RemoteFileURL.theLastOnes.mp3
        let downloader = Downloader(url: url)
        downloader.start()
        
        do {
            let parser = try Parser()
            downloader.progressHandler = { (data, progress) in
                parser.parse(data: data)
            }
        } catch {
            XCTFail("Could not create parser")
        }
        
        downloader.completionHandler = {
            XCTAssertEqual(downloader.state, .completed)
            XCTAssertNil($0)
            expectation.fulfill()
        }
        XCTAssertEqual(downloader.state, .started)
        
        self.wait(for: [expectation], timeout: 10)
    }
    
    func testParseDownloadedAAC() {
        let expectation = XCTestExpectation(description: "Download & Parse AAC")
        
        let url = RemoteFileURL.theLastOnes.aac
        let downloader = Downloader(url: url)
        downloader.start()
        
        do {
            let parser = try Parser()
            downloader.progressHandler = { (data, progress) in
                parser.parse(data: data)
            }
        } catch {
            XCTFail("Could not create parser")
        }
        
        downloader.completionHandler = {
            XCTAssertEqual(downloader.state, .completed)
            XCTAssertNil($0)
            expectation.fulfill()
        }
        XCTAssertEqual(downloader.state, .started)
        
        self.wait(for: [expectation], timeout: 10)
    }
    
    func testParseDownloadedWAV() {
        let expectation = XCTestExpectation(description: "Download & Parse WAV")
        
        let url = RemoteFileURL.theLastOnes.wav
        let downloader = Downloader(url: url)
        downloader.start()
        
        do {
            let parser = try Parser()
            downloader.progressHandler = { (data, progress) in
                parser.parse(data: data)
            }
        } catch {
            XCTFail("Could not create parser")
        }
        
        downloader.completionHandler = {
            XCTAssertEqual(downloader.state, .completed)
            XCTAssertNil($0)
            expectation.fulfill()
        }
        XCTAssertEqual(downloader.state, .started)
        
        self.wait(for: [expectation], timeout: 10)
    }
    
}
