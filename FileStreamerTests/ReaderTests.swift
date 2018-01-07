//
//  ReaderTests.swift
//  FileStreamerTests
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import XCTest
import AVFoundation
import os.log
@testable import FileStreamer

class ReaderTests: XCTestCase {

    func testParseDownloadedMP3() {
        let expectation = XCTestExpectation(description: "Download & Parse & Read MP3")
        expectation.expectedFulfillmentCount = 2
        
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
            
            //
            let readFormatOrNil = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)
            guard let readFormat = readFormatOrNil else {
                XCTFail("Could not create read format")
                return
            }

            //
            var readerOrNil: Reader?
            do {
                readerOrNil = try Reader(parser: parser, readFormat: readFormat)
            } catch {
                XCTFail("Could not create reader: \(error.localizedDescription)")
                return
            }

            guard let reader = readerOrNil else {
                XCTFail("Did not create reader")
                return
            }

            testRead(10, reader)
        }
        XCTAssertEqual(downloader.state, .started)
        
        func testRead(_ ticks: Int, _ reader: Reader) {
            guard ticks != 0 else {
                expectation.fulfill()
                return
            }
            
            let buffer = reader.read(22050)
            XCTAssertNotNil(buffer)
            
            usleep(250000)
            testRead(ticks - 1, reader)
        }
        
        self.wait(for: [expectation], timeout: 20)
    }
    
    func testParseDownloadedWAV() {
        let expectation = XCTestExpectation(description: "Download & Parse & Read WAV")
        expectation.expectedFulfillmentCount = 2
        
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
            
            expectation.fulfill()
            
            //
            let readFormatOrNil = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)
            guard let readFormat = readFormatOrNil else {
                XCTFail("Could not create read format")
                return
            }
            
            //
            var readerOrNil: Reader?
            do {
                readerOrNil = try Reader(parser: parser, readFormat: readFormat)
            } catch {
                XCTFail("Could not create reader: \(error.localizedDescription)")
                return
            }
            
            guard let reader = readerOrNil else {
                XCTFail("Did not create reader")
                return
            }
            
            testRead(10, reader)
        }
        XCTAssertEqual(downloader.state, .started)
        
        func testRead(_ ticks: Int, _ reader: Reader) {
            guard ticks != 0 else {
                expectation.fulfill()
                return
            }
            
            let buffer = reader.read(4096)
            XCTAssertNotNil(buffer)
            
            usleep(250000)
            testRead(ticks - 1, reader)
        }
        
        self.wait(for: [expectation], timeout: 20)
    }
    
}
