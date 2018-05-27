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
    static let logger = OSLog(subsystem: "com.fastlearner.streamer", category: "Reader")
    static let loggerConverter = OSLog(subsystem: "com.fastlearner.streamer", category: "Reader.Converter")
    
    // MARK: - Properties
    
    /// An `AudioConverterRef` used to do the conversion from the source format of the `parser` (i.e. the `sourceFormat`) to the read destination (i.e. the `destinationFormat`).
    var converter: AudioConverterRef? = nil
    
    /// <#Description#>
    var sourceFormat: AudioStreamBasicDescription
    
    /// <#Description#>
    var destinationFormat: AudioStreamBasicDescription
    
    // MARK: - Properties (Readable)
    
    /// <#Description#>
    let parser: Parsable
    
    /// <#Description#>
    public var currentPacket: AVAudioPacketCount = 0
    
    // MARK: - Lifecycle
    
    deinit {
        guard AudioConverterDispose(converter!) == noErr else {
            os_log("Failed to dispose of audio converter", log: Reader.logger, type: .error)
            return
        }
    }
    
    public required init(parser: Parsable, readFormat: AVAudioFormat) throws {
        self.parser = parser
        
        guard let dataFormat = parser.dataFormat else {
            throw ReaderError.parserMissingDataFormat
        }

        let sourceFormat = dataFormat.streamDescription
        let destinationFormat = readFormat.streamDescription
        let result = AudioConverterNew(sourceFormat, destinationFormat, &converter)
        guard result == noErr else {
            throw ReaderError.unableToCreateConverter(result)
        }
        
        self.sourceFormat = sourceFormat.pointee
        self.destinationFormat = destinationFormat.pointee
        
        os_log("%@ - %d [sourceFormat: %@, destinationFormat: %@]", log: Reader.logger, type: .debug, #function, #line, String(describing: dataFormat), String(describing: readFormat))
    }
    
    // MARK: - Methods
    
    public func read(_ frames: AVAudioFrameCount) throws -> AVAudioPCMBuffer {
        var packets = frames / destinationFormat.mFramesPerPacket
        
        guard currentPacket != parser.packets.count - 1 else {
            throw ReaderError.notEnoughData
        }
        
        guard let format = AVAudioFormat(streamDescription: &destinationFormat) else {
            throw ReaderError.failedToCreateDestinationFormat
        }
        
        /// This should not be allocated everytime
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else {
            throw ReaderError.failedToCreatePCMBuffer
        }
        buffer.frameLength = frames
        
//        os_log("%@ - %d [converter: %@, packets: %i, format: %@, buffer: %@]", log: Reader.logger, type: .debug, #function, #line, String(describing: converter!), packets, String(describing: format), String(describing: buffer))
        
        let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        let status = AudioConverterFillComplexBuffer(converter!, ReaderConverterCallback, context, &packets, buffer.mutableAudioBufferList, nil)
        guard status == noErr else {
            switch status {
            case ReaderReachedEndOfDataError:
                throw ReaderError.reachedEndOfFile
            case ReaderNotEnoughDataError:
                throw ReaderError.notEnoughData
            default:
                throw ReaderError.converterFailed(status)
            }
        }
        
        return buffer
    }
    
    public func seek(_ packet: AVAudioPacketCount) {
        os_log("%@ - %d [packet: %i]", log: Parser.logger, type: .debug, #function, #line, packet)
        
        currentPacket = packet
    }
}
