//
//  Parser.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation
import os.log

public class Parser: Parsable {
    static let logger = OSLog(subsystem: "com.ausomeapps.fstreamer", category: "Parser")
    static let loggerPropertyListenerCallback = OSLog(subsystem: "com.ausomeapps.fstreamer", category: "Parser.PropertyListener")
    static let loggerPacketCallback = OSLog(subsystem: "com.ausomeapps.fstreamer", category: "Parser.Packets")
    
    class Info {
        var bitRate: UInt32 = 0
        var byteCount: UInt64 = 0
        var dataOffset: Int64 = 0
        var packetCount: UInt64 = 0
        var fileFormat: AVAudioFormat?
        var dataFormat: AVAudioFormat?
        var isReadyToProducePackets: Bool = false
        var packets = [Data]()
    }
    
    var info = Info()
    var streamID: AudioFileStreamID?
    
    init() throws {
        guard AudioFileStreamOpen(&self.info, ParserPropertyChangeCallback, ParserPacketCallback, kAudioFileMP3Type, &self.streamID) == noErr else {
            throw ParserError.streamCouldNotOpen
        }
    }
    
    func parse(data: Data) {
        os_log("%@ - %d", log: Parser.logger, type: .debug, #function, #line)
        
        guard let streamID = streamID else {
            os_log("Failed to open stream", log: Parser.logger, type: .error)
            return
        }
        
        let count = data.count
        let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        data.copyBytes(to: bytes, count: count)
        AudioFileStreamParseBytes(streamID, UInt32(count), bytes, [])
        bytes.deallocate(capacity: count)
    }
    
}
