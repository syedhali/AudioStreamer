//
//  Parser.swift
//  AudioStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation
import os.log

/// The `Parser` is a concrete implementation of the `Parsing` protocol used to convert binary data into audio packet data. This class uses the Audio File Stream Services to progressively parse the properties and packets of the incoming audio data.
public class Parser: Parsing {
    static let logger = OSLog.disabled // OSLog(subsystem: "com.fastlearner.streamer", category: "Parser")
    static let loggerPacketCallback = OSLog.disabled //= OSLog(subsystem: "com.fastlearner.streamer", category: "Parser.Packets")
    static let loggerPropertyListenerCallback = OSLog.disabled //= OSLog(subsystem: "com.fastlearner.streamer", category: "Parser.PropertyListener")
    
    // MARK: - Parsing props
    
    public internal(set) var dataFormat: AVAudioFormat?
    public internal(set) var packets = [(Data, AudioStreamPacketDescription?)]()
    public var totalPacketCount: AVAudioPacketCount? {
        guard let _ = dataFormat else {
            return nil
        }
        
        return max(AVAudioPacketCount(packetCount), AVAudioPacketCount(packets.count))
    }
        
    // MARK: - Properties
    
    /// A `UInt64` corresponding to the total frame count parsed by the Audio File Stream Services
    public internal(set) var frameCount: UInt64 = 0
    
    /// A `UInt64` corresponding to the total packet count parsed by the Audio File Stream Services
    public internal(set) var packetCount: UInt64 = 0
    
    /// The `AudioFileStreamID` used by the Audio File Stream Services for converting the binary data into audio packets
    fileprivate var streamID: AudioFileStreamID?

    // MARK: - Lifecycle
    
    /// Initializes an instance of the `Parser`
    ///
    /// - Throws: A `ParserError.streamCouldNotOpen` meaning a file stream instance could not be opened
    public init() throws {
        let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        guard AudioFileStreamOpen(context, ParserPropertyChangeCallback, ParserPacketCallback, kAudioFileM4AType, &streamID) == noErr else {
            throw ParserError.streamCouldNotOpen
        }
    }
    
    deinit {
        os_log("🗑 DELETE PARSER", log: Streamer.logger, type: .debug)
    }
    
    // MARK: - Methods
    
    public func parse(data: Data) throws {
        let streamID = self.streamID!
        let count = data.count
        _ = try data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
            let result = AudioFileStreamParseBytes(streamID, UInt32(count), bytes, [])
            guard result == noErr else {
                if result == kAudioFileStreamError_UnsupportedFileType {
                    throw ParserError.fileTypeUnsupported
                } else {
                    throw ParserError.failedToParseBytes(result)
                }
            }
        }
    }
    
    public func add(packet: (Data, AudioStreamPacketDescription?)) {
        packets.append(packet)
    }
}
