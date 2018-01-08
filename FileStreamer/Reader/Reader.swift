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
    static let loggerConverter = OSLog(subsystem: "com.ausomeapps.fstreamer", category: "Reader.Converter")
    
    // MARK: - Properties
    
    /// <#Description#>
    var converter: AudioConverterRef? = nil
    
    /// <#Description#>
    public var currentPacket: AVAudioPacketCount = 0
    
    /// <#Description#>
    let parser: Parsable
    
    /// <#Description#>
    var sourceFormat: AudioStreamBasicDescription
    
    /// <#Description#>
    var destinationFormat: AudioStreamBasicDescription
    
    // MARK: - Initializers
    
    deinit {
        guard AudioConverterDispose(converter!) == noErr else {
            os_log("Failed to dispose of audio converter", log: Reader.logger, type: .error)
            return
        }
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - parser: <#parser description#>
    ///   - readFormat: <#readFormat description#>
    /// - Throws: <#throws value description#>
    public required init(parser: Parsable, readFormat: AVAudioFormat) throws {
        self.parser = parser
        
        guard let dataFormat = parser.dataFormat else {
            throw ReaderError.parserMissingDataFormat
        }

        let sourceFormat = dataFormat.streamDescription
        let destinationFormat = readFormat.streamDescription
        guard AudioConverterNew(sourceFormat, destinationFormat, &converter) == noErr else {
            throw ReaderError.unableToCreateConverter
        }
        
        self.sourceFormat = sourceFormat.pointee
        self.destinationFormat = destinationFormat.pointee
        
        os_log("%@ - %d [sourceFormat: %@, destinationFormat: %@]", log: Reader.logger, type: .debug, #function, #line, String(describing: dataFormat), String(describing: readFormat))
    }
    
    // MARK: - Methods
    
    /// <#Description#>
    ///
    /// - Returns: <#return value description#>
    public func read(_ frames: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        var packets = frames / destinationFormat.mFramesPerPacket
        
        guard currentPacket != parser.packets.count - 1 else {
            return nil
        }
        
        guard let format = AVAudioFormat(streamDescription: &destinationFormat) else {
            os_log("Failed to create destination format", log: Reader.logger, type: .error)
            return nil
        }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else {
            os_log("Failed to create PCM buffer", log: Reader.logger, type: .error)
            return nil
        }
        buffer.frameLength = frames
        
        os_log("%@ - %d [converter: %@, packets: %i, format: %@, buffer: %@]", log: Reader.logger, type: .debug, #function, #line, String(describing: converter!), packets, String(describing: format), String(describing: buffer))
        
        let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        let result = AudioConverterFillComplexBuffer(converter!, ReaderConverterCallback, context, &packets, buffer.mutableAudioBufferList, nil)
        guard result == noErr else {
            var localizedError = ""
            switch result {
            case kAudioConverterErr_FormatNotSupported:
                localizedError = "kAudioConverterErr_FormatNotSupported"
            case kAudioConverterErr_OperationNotSupported:
                localizedError = "kAudioConverterErr_OperationNotSupported"
            case kAudioConverterErr_PropertyNotSupported:
                localizedError = "kAudioConverterErr_PropertyNotSupported"
            case kAudioConverterErr_InvalidInputSize:
                localizedError = "kAudioConverterErr_InvalidInputSize"
            case kAudioConverterErr_InvalidOutputSize:
                localizedError = "kAudioConverterErr_InvalidOutputSize"
            case kAudioConverterErr_UnspecifiedError:
                localizedError = "kAudioConverterErr_UnspecifiedError"
            case kAudioConverterErr_BadPropertySizeError:
                localizedError = "kAudioConverterErr_BadPropertySizeError"
            case kAudioConverterErr_RequiresPacketDescriptionsError:
                localizedError = "kAudioConverterErr_RequiresPacketDescriptionsError"
            case kAudioConverterErr_InputSampleRateOutOfRange:
                localizedError = "kAudioConverterErr_InputSampleRateOutOfRange"
            case kAudioConverterErr_OutputSampleRateOutOfRange:
                localizedError = "kAudioConverterErr_OutputSampleRateOutOfRange"
            case kAudioConverterErr_HardwareInUse:
                localizedError = "kAudioConverterErr_HardwareInUse"
            case kAudioConverterErr_NoHardwarePermission:
                localizedError = "kAudioConverterErr_NoHardwarePermission"
            default:
                localizedError = "Unknown"
            }
            os_log("Failed to fill complex buffer [error: %@]", log: Reader.logger, type: .error, localizedError)
            return nil
        }
        
        return buffer
    }
}
