//
//  Reader.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation
import os.log

/// <#Description#>
public class Reader: Readable {
    static let logger = OSLog(subsystem: "com.ausomeapps.fstreamer", category: "Reader")
    
    // MARK: - Properties
    
    /// <#Description#>
    let converter: AVAudioConverter
    
    var currentPacket: AVAudioPacketCount = 0
    
    /// <#Description#>
    let parser: Parsable
    
    // MARK: - Initializers
    
    /// <#Description#>
    ///
    /// - Parameter parser: <#parser description#>
    public required init(parser: Parsable, readFormat: AVAudioFormat) throws {
        self.parser = parser
        
        guard let dataFormat = parser.dataFormat else {
            throw ReaderError.parserMissingDataFormat
        }
        
        guard let converter = AVAudioConverter(from: dataFormat, to: readFormat) else {
            throw ReaderError.unableToCreateConverter
        }
        
        self.converter = converter
    }
    
    // MARK: - Methods
    
    /// <#Description#>
    ///
    /// - Returns: <#return value description#>
    public func read(_ frames: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        os_log("%@ - %d", log: Reader.logger, type: .debug, #function, #line)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: frames) else {
            os_log("Failed to create PCM buffer", log: Reader.logger, type: .debug)
            return nil
        }
        
        var error: NSError?
        let status = converter.convert(to: buffer, error: &error, withInputFrom: handleInputBlock)
        
        return buffer
    }
    
    func handleInputBlock(_ packetCount: AVAudioPacketCount, _ inputStatus:
        UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer? {
        os_log("%@ - %d [packetCount: %i]", log: Reader.logger, type: .debug, #function, #line, packetCount)
        
        guard let format = parser.dataFormat else {
            inputStatus.pointee = .endOfStream
            os_log("Missing input format", log: Reader.logger, type: .error, #function, #line, packetCount)
            return nil
        }
        
        if currentPacket + packetCount <= parser.packets.count {
            inputStatus.pointee = .haveData
            
            let buffer = AVAudioCompressedBuffer(format: format, packetCapacity: packetCount, maximumPacketSize: 2048)
            buffer.packetCount = packetCount
            
            /// Need range of values
            let packets = parser.packets[Int(currentPacket)...Int(packetCount)]
            
            /// Need to get data
            
            var data = Data()
            var packetDescriptions = [AudioStreamPacketDescription?]()
            for packet in packets {
                data.append(packet.0)
                packetDescriptions.append(packet.1)
            }
            _ = data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
                memcpy(buffer.data, bytes, Int(packetCount))
            }
            
            /// Packet descriptions
            memcpy(buffer.packetDescriptions, &packetDescriptions, Int(packetCount))
            
            currentPacket += packetCount
            
            return buffer
        } else {
            if parser.isComplete {
                inputStatus.pointee = .endOfStream
                os_log("End of stream", log: Reader.logger, type: .debug, #function, #line, packetCount)
            } else {
                inputStatus.pointee = .noDataNow
                os_log("No Data Now", log: Reader.logger, type: .debug, #function, #line, packetCount)
            }
        }

        return nil
    }
}
