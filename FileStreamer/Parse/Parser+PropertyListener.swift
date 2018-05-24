//
//  Parser+PropertyListener.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation
import os.log

func ParserPropertyChangeCallback(_ context: UnsafeMutableRawPointer, _ streamID: AudioFileStreamID, _ propertyID: AudioFileStreamPropertyID, _ flags: UnsafeMutablePointer<AudioFileStreamPropertyFlags>) {
    /// Cast back our context to the info object
    let info = context.assumingMemoryBound(to: Parser.Info.self).pointee
    
    /// Parse the various properties
    switch propertyID {
    case kAudioFileStreamProperty_ReadyToProducePackets:
        info.isReadyToProducePackets = true
        os_log("Ready to produce packets!", log: Parser.loggerPropertyListenerCallback, type: .debug)
        
    case kAudioFileStreamProperty_FileFormat:
        var format = AudioStreamBasicDescription()
        GetPropertyValue(&format, streamID, propertyID)
        info.fileFormat = AVAudioFormat(streamDescription: &format)
        os_log("File format: %@", log: Parser.loggerPropertyListenerCallback, type: .debug, String(describing: info.fileFormat))
        
    case kAudioFileStreamProperty_DataFormat:
        var format = AudioStreamBasicDescription()
        GetPropertyValue(&format, streamID, propertyID)
        info.dataFormat = AVAudioFormat(streamDescription: &format)
        os_log("Data format: %@", log: Parser.loggerPropertyListenerCallback, type: .debug, String(describing: info.dataFormat))
        
    case kAudioFileStreamProperty_AudioDataByteCount:
        var byteCount: UInt64 = 0
        GetPropertyValue(&byteCount, streamID, propertyID)
        info.byteCount = byteCount
        os_log("Byte count: %i", log: Parser.loggerPropertyListenerCallback, type: .debug, byteCount)
        
    case kAudioFileStreamProperty_AudioDataPacketCount:
        var packetCount: UInt64 = 0
        GetPropertyValue(&packetCount, streamID, propertyID)
        info.packetCount = packetCount
        os_log("Packet count: %i", log: Parser.loggerPropertyListenerCallback, type: .debug, packetCount)
        
    case kAudioFileStreamProperty_DataOffset:
        var dataOffset: Int64 = 0
        GetPropertyValue(&dataOffset, streamID, propertyID)
        info.dataOffset = dataOffset
        os_log("Data offset: %i", log: Parser.loggerPropertyListenerCallback, type: .debug, String(propertyID))
        
    case kAudioFileStreamProperty_BitRate:
        var bitRate: UInt32 = 0
        GetPropertyValue(&bitRate, streamID, propertyID)
        info.bitRate = bitRate
        os_log("Bit Rate: %i", log: Parser.loggerPropertyListenerCallback, type: .debug, bitRate)

    case kAudioFileStreamProperty_FormatList:
        os_log("kAudioFileStreamProperty_FormatList", log: Parser.loggerPropertyListenerCallback, type: .debug)
    case kAudioFileStreamProperty_MagicCookieData:
        os_log("kAudioFileStreamProperty_MagicCookieData", log: Parser.loggerPropertyListenerCallback, type: .debug)
    case kAudioFileStreamProperty_MaximumPacketSize:
        os_log("kAudioFileStreamProperty_MaximumPacketSize", log: Parser.loggerPropertyListenerCallback, type: .debug)
    case kAudioFileStreamProperty_ChannelLayout:
        os_log("kAudioFileStreamProperty_ChannelLayout", log: Parser.loggerPropertyListenerCallback, type: .debug)
    case kAudioFileStreamProperty_PacketToFrame:
        os_log("kAudioFileStreamProperty_PacketToFrame", log: Parser.loggerPropertyListenerCallback, type: .debug)
    case kAudioFileStreamProperty_FrameToPacket:
        os_log("kAudioFileStreamProperty_FrameToPacket", log: Parser.loggerPropertyListenerCallback, type: .debug)
    case kAudioFileStreamProperty_PacketToByte:
        os_log("kAudioFileStreamProperty_PacketToByte", log: Parser.loggerPropertyListenerCallback, type: .debug)
    case kAudioFileStreamProperty_ByteToPacket:
        os_log("kAudioFileStreamProperty_ByteToPacket", log: Parser.loggerPropertyListenerCallback, type: .debug)
    case kAudioFileStreamProperty_PacketTableInfo:
        os_log("kAudioFileStreamProperty_PacketTableInfo", log: Parser.loggerPropertyListenerCallback, type: .debug)
    case kAudioFileStreamProperty_PacketSizeUpperBound:
        os_log("kAudioFileStreamProperty_PacketSizeUpperBound", log: Parser.loggerPropertyListenerCallback, type: .debug)
    case kAudioFileStreamProperty_AverageBytesPerPacket:
        os_log("kAudioFileStreamProperty_AverageBytesPerPacket", log: Parser.loggerPropertyListenerCallback, type: .debug)
    case kAudioFileStreamProperty_InfoDictionary:
        os_log("kAudioFileStreamProperty_InfoDictionary", log: Parser.loggerPropertyListenerCallback, type: .debug)
    default:
        os_log("Unkown Property: [%@]", log: Parser.loggerPropertyListenerCallback, type: .debug, String(describing: propertyID))
    }
}

// MARK: - Utils

/// Generic method for getting an AudioFileStream property. This method takes care of getting the size of the property and takes in the expected value type and reads it into the value provided. Note it is an inout method so the value passed in will be mutated. This is not as functional as we'd like, but allows us to make this method generic.
///
/// - Parameters:
///   - value: A value of the expected type of the underlying property
///   - streamID: An `AudioFileStreamID` representing the current audio file stream parser.
///   - propertyID: An `AudioFileStreamPropertyID` representing the particular property to get.
func GetPropertyValue<T>(_ value: inout T, _ streamID: AudioFileStreamID, _ propertyID: AudioFileStreamPropertyID) {
    var propSize: UInt32 = 0
    guard AudioFileStreamGetPropertyInfo(streamID, propertyID, &propSize, nil) == noErr else {
        os_log("Failed to get info for property: %@", log: Parser.loggerPropertyListenerCallback, type: .error, String(describing: propertyID))
        return
    }
    
    guard AudioFileStreamGetProperty(streamID, propertyID, &propSize, &value) == noErr else {
        os_log("Failed to get value [%@]", log: Parser.loggerPropertyListenerCallback, type: .error, String(describing: propertyID))
        return
    }
}

/// This extension just helps us print out the name of an `AudioFileStreamPropertyID`. Purely for debugging and not essential to the main functionality of the parser.
extension AudioFileStreamPropertyID: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case kAudioFileStreamProperty_ReadyToProducePackets:
            return "Ready to produce packets"
        case kAudioFileStreamProperty_FileFormat:
            return "File format"
        case kAudioFileStreamProperty_DataFormat:
            return "Data format"
        case kAudioFileStreamProperty_AudioDataByteCount:
            return "Byte count"
        case kAudioFileStreamProperty_AudioDataPacketCount:
            return "Packet count"
        case kAudioFileStreamProperty_DataOffset:
            return "Data offset"
        case kAudioFileStreamProperty_BitRate:
            return "Bit rate"
        case kAudioFileStreamProperty_FormatList:
            return "Format list"
        case kAudioFileStreamProperty_MagicCookieData:
            return "Magic cookie"
        case kAudioFileStreamProperty_MaximumPacketSize:
            return "Max packet size"
        case kAudioFileStreamProperty_ChannelLayout:
            return "Channel layout"
        case kAudioFileStreamProperty_PacketToFrame:
            return "Packet to frame"
        case kAudioFileStreamProperty_FrameToPacket:
            return "Frame to packet"
        case kAudioFileStreamProperty_PacketToByte:
            return "Packet to byte"
        case kAudioFileStreamProperty_ByteToPacket:
            return "Byte to packet"
        case kAudioFileStreamProperty_PacketTableInfo:
            return "Packet table"
        case kAudioFileStreamProperty_PacketSizeUpperBound:
            return "Packet size upper bound"
        case kAudioFileStreamProperty_AverageBytesPerPacket:
            return "Average bytes per packet"
        case kAudioFileStreamProperty_InfoDictionary:
            return "Info dictionary"
        default:
            return "Unknown"
        }
    }
}
