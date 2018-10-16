//
//  ReaderTests.swift
//  AudioStreamerTests
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import XCTest
import AVFoundation
import os.log
@testable import AudioStreamer

class ReaderTests: XCTestCase {

    func testReadDownloadedMP3() {
        let expectation = XCTestExpectation(description: "Download & Parse & Read MP3")
        expectation.expectedFulfillmentCount = 2
        
        let url = RemoteFileURL.theLastOnes.mp3
        Downloader.shared.url = url
        Downloader.shared.start()
        XCTAssertEqual(Downloader.shared.state, .started)
        
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
        
        Downloader.shared.progressHandler = { (data, progress) in
            try! parser.parse(data: data)
        }
        
        Downloader.shared.completionHandler = {
            XCTAssertEqual(Downloader.shared.state, .completed)
            XCTAssertNil($0)
            
            XCTAssertNotEqual(parser.dataFormat, nil)
            XCTAssertEqual(parser.packets.count, 6897)
            
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
        
        func testRead(_ ticks: Int, _ reader: Reader) {
            guard ticks != 0 else {
                expectation.fulfill()
                return
            }
            
            let buffer = try! reader.read(22050)
            XCTAssertNotNil(buffer)
            
            usleep(250000)
            testRead(ticks - 1, reader)
        }
        
        self.wait(for: [expectation], timeout: 20)
    }
    
    func testReadDownloadedAAC() {
        let expectation = XCTestExpectation(description: "Download & Parse & Read AAC")
        expectation.expectedFulfillmentCount = 2
        
        let url = RemoteFileURL.theLastOnes.aac
        Downloader.shared.url = url
        Downloader.shared.start()
        XCTAssertEqual(Downloader.shared.state, .started)
        
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
        
        Downloader.shared.progressHandler = { (data, progress) in
            try! parser.parse(data: data)
        }
        
        Downloader.shared.completionHandler = {
            XCTAssertEqual(Downloader.shared.state, .completed)
            XCTAssertNil($0)
            
            XCTAssertEqual(parser.packets.count, 3881)
            
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
        
        func testRead(_ ticks: Int, _ reader: Reader) {
            guard ticks != 0 else {
                expectation.fulfill()
                return
            }
            
            let buffer = try! reader.read(22050)
            XCTAssertNotNil(buffer)
            
            usleep(250000)
            testRead(ticks - 1, reader)
        }
        
        self.wait(for: [expectation], timeout: 20)
    }
    
    func testReadDownloadedWAV() {
        let expectation = XCTestExpectation(description: "Download & Parse & Read WAV")
        expectation.expectedFulfillmentCount = 2
        
        let url = RemoteFileURL.theLastOnes.wav
        Downloader.shared.url = url
        Downloader.shared.start()
        
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
        
        Downloader.shared.progressHandler = { (data, progress) in
            try! parser.parse(data: data)
        }
        
        Downloader.shared.completionHandler = {
            XCTAssertEqual(Downloader.shared.state, .completed)
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
        XCTAssertEqual(Downloader.shared.state, .started)
        
        func testRead(_ ticks: Int, _ reader: Reader) {
            guard ticks != 0 else {
                expectation.fulfill()
                return
            }
            
            let buffer = try! reader.read(1024)
            XCTAssertNotNil(buffer)
            
            usleep(250000)
            testRead(ticks - 1, reader)
        }
        
        self.wait(for: [expectation], timeout: 60)
    }
    
}
