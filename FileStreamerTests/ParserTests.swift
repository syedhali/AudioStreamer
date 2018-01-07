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
        
        var parserOrNil: Parser?
        do {
            parserOrNil = try Parser()
        } catch {
            XCTFail("Could not create parser")
            return
        }
        
        guard let parser = parserOrNil else {
            XCTFail("Did not create parser")
            return
        }
        
        downloader.progressHandler = { (data, progress) in
            parser.parse(data: data)
        }
        
        downloader.completionHandler = {
            XCTAssertEqual(downloader.state, .completed)
            XCTAssertNil($0)
            
            XCTAssertEqual(parser.bitRate, 8000)
            XCTAssertEqual(parser.byteCount, 180245)
            XCTAssertEqual(parser.dataOffset, 757)
            XCTAssertNotEqual(parser.dataFormat, nil)
            XCTAssertNotEqual(parser.fileFormat, nil)
            XCTAssertEqual(parser.packets.count, 3450)
            
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
        
        var parserOrNil: Parser?
        do {
            parserOrNil = try Parser()
        } catch {
            XCTFail("Could not create parser")
            return
        }
        
        guard let parser = parserOrNil else {
            XCTFail("Did not create parser")
            return
        }
        
        downloader.progressHandler = { (data, progress) in
            parser.parse(data: data)
        }
        
        downloader.completionHandler = {
            XCTAssertEqual(downloader.state, .completed)
            XCTAssertNil($0)
            
            XCTAssertEqual(parser.dataOffset, 0)
            XCTAssertNotEqual(parser.dataFormat, nil)
            XCTAssertNotEqual(parser.fileFormat, nil)
            XCTAssertEqual(parser.packets.count, 1942)
            
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
        
        var parserOrNil: Parser?
        do {
            parserOrNil = try Parser()
        } catch {
            XCTFail("Could not create parser")
            return
        }
        
        guard let parser = parserOrNil else {
            XCTFail("Did not create parser")
            return
        }
        
        downloader.progressHandler = { (data, progress) in
            parser.parse(data: data)
        }
        
        downloader.completionHandler = {
            XCTAssertEqual(downloader.state, .completed)
            XCTAssertNil($0)
            
            XCTAssertEqual(parser.byteCount, 7943040)
            XCTAssertEqual(parser.dataOffset, 498)
            XCTAssertNotEqual(parser.dataFormat, nil)
            XCTAssertNotEqual(parser.fileFormat, nil)
            XCTAssertEqual(parser.packets.count, 3971520)
            
            expectation.fulfill()
        }
        XCTAssertEqual(downloader.state, .started)
        
        self.wait(for: [expectation], timeout: 10)
    }
    
}
