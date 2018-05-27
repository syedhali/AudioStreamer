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

/// The `Parser` is a concrete implementation of the `Parsable` protocol used to convert binary data into audio packet data. This class uses the Audio File Stream Services to progressively parse the properties and packets of the incoming audio data.
public class Parser: Parsable {
    static let logger = OSLog(subsystem: "com.fastlearner.streamer", category: "Parser")
    static let loggerPacketCallback = OSLog(subsystem: "com.fastlearner.streamer", category: "Parser.Packets")
    static let loggerPropertyListenerCallback = OSLog(subsystem: "com.fastlearner.streamer", category: "Parser.PropertyListener")
    
    public var bitRate: UInt32 = 0
    public var byteCount: UInt64 = 0
    public var dataOffset: Int64 = 0
    public var frameCount: UInt64 = 0
    public var packetCount: UInt64 = 0
    public var fileFormat: AVAudioFormat?
    public var dataFormat: AVAudioFormat?
    public var isReadyToProducePackets: Bool = false
    public var packets = [(Data, AudioStreamPacketDescription?)]()
    
    /// The `AudioFileStreamID` used by the Audio File Stream Services for converting the binary data into audio packets
    fileprivate var streamID: AudioFileStreamID?
    
    ///
    public var duration: TimeInterval? {
        guard let dataFormat = dataFormat?.streamDescription.pointee else {
            return nil
        }
        
        guard let totalFrameCount = totalFrameCount else {
            return nil
        }
        
        return TimeInterval(totalFrameCount) / TimeInterval(dataFormat.mSampleRate)
    }
    
    public var totalFrameCount: AVAudioFrameCount? {
        guard let dataFormat = dataFormat?.streamDescription.pointee else {
            return nil
        }
        
        guard let totalPacketCount = totalPacketCount else {
            return nil
        }
        
        return AVAudioFrameCount(totalPacketCount) * AVAudioFrameCount(dataFormat.mFramesPerPacket)
    }
    
    public var totalPacketCount: AVAudioPacketCount? {
        guard let _ = dataFormat?.streamDescription.pointee else {
            return nil
        }
        
        return max(AVAudioPacketCount(packetCount), AVAudioPacketCount(packets.count))
    }
    
    // MARK: - Lifecycle
    
    /// <#Description#>
    ///
    /// - Throws: <#throws value description#>
    public init() throws {
        let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        guard AudioFileStreamOpen(context, ParserPropertyChangeCallback, ParserPacketCallback, kAudioFileMP3Type, &streamID) == noErr else {
            throw ParserError.streamCouldNotOpen
        }
    }
    
    // MARK: - Methods
    
    public func parse(data: Data) throws {
        os_log("%@ - %d", log: Parser.logger, type: .debug, #function, #line)
        
        let streamID = self.streamID!
        let count = data.count
        _ = try data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
            let result = AudioFileStreamParseBytes(streamID, UInt32(count), bytes, [])
            guard result == noErr else {
                os_log("Failed to parse bytes", log: Parser.logger, type: .error)
                throw ParserError.failedToParseBytes(result)
            }
        }
    }
    
    public func packetOffset(forFrame frame: AVAudioFramePosition) -> AVAudioPacketCount? {
        os_log("%@ - %d", log: Parser.logger, type: .debug, #function, #line)
        
        guard let dataFormat = dataFormat?.streamDescription.pointee else {
            return nil
        }
        
        return AVAudioPacketCount(frame) / AVAudioPacketCount(dataFormat.mFramesPerPacket)
    }
    
    public func timeOffset(forFrame frame: AVAudioFrameCount) -> TimeInterval? {
        os_log("%@ - %d", log: Parser.logger, type: .debug, #function, #line)
        
        guard let _ = dataFormat?.streamDescription.pointee,
              let frameCount = totalFrameCount,
              let duration = duration else {
            return nil
        }
        
        return TimeInterval(frame) / TimeInterval(frameCount) * duration
    }
    
    public func frameOffset(forTime time: TimeInterval) -> AVAudioFramePosition? {
        os_log("%@ - %d", log: Parser.logger, type: .debug, #function, #line)
        
        guard let _ = dataFormat?.streamDescription.pointee,
            let frameCount = totalFrameCount,
            let duration = duration else {
                return nil
        }
            
        let ratio = time / duration
        return AVAudioFramePosition(Double(frameCount) * ratio)
    }
}
