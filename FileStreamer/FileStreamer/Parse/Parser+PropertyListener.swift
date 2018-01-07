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
    
    /// Generic getter
    func get<T>(value: inout T) {
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
    
    /// Parse the various properties
    switch propertyID {
    case kAudioFileStreamProperty_ReadyToProducePackets:
        info.isReadyToProducePackets = true
        os_log("Ready to produce packets!", log: Parser.loggerPropertyListenerCallback, type: .debug)
        
    case kAudioFileStreamProperty_FileFormat:
        var format = AudioStreamBasicDescription()
        get(value: &format)
        info.fileFormat = AVAudioFormat(streamDescription: &format)
        os_log("File format: %@", log: Parser.loggerPropertyListenerCallback, type: .error, String(describing: info.fileFormat))
        
    case kAudioFileStreamProperty_DataFormat:
        var format = AudioStreamBasicDescription()
        get(value: &format)
        info.dataFormat = AVAudioFormat(streamDescription: &format)
        os_log("Data format: %@", log: Parser.loggerPropertyListenerCallback, type: .error, String(describing: info.dataFormat))
        
    case kAudioFileStreamProperty_FormatList:
        os_log("kAudioFileStreamProperty_FormatList", log: Parser.loggerPropertyListenerCallback, type: .debug)
        
    case kAudioFileStreamProperty_MagicCookieData:
        os_log("kAudioFileStreamProperty_MagicCookieData", log: Parser.loggerPropertyListenerCallback, type: .debug)
        
    case kAudioFileStreamProperty_AudioDataByteCount:
        var byteCount: UInt64 = 0
        get(value: &byteCount)
        info.byteCount = byteCount
        os_log("Byte count: %i", log: Parser.loggerPropertyListenerCallback, type: .error, byteCount)
        
    case kAudioFileStreamProperty_AudioDataPacketCount:
        var packetCount: UInt64 = 0
        get(value: &packetCount)
        info.packetCount = packetCount
        os_log("Packet count: %i", log: Parser.loggerPropertyListenerCallback, type: .error, packetCount)
        
    case kAudioFileStreamProperty_MaximumPacketSize:
        os_log("kAudioFileStreamProperty_MaximumPacketSize", log: Parser.loggerPropertyListenerCallback, type: .debug)
        
    case kAudioFileStreamProperty_DataOffset:
        var dataOffset: Int64 = 0
        get(value: &dataOffset)
        info.dataOffset = dataOffset
        os_log("Data Offset: %i", log: Parser.loggerPropertyListenerCallback, type: .error, dataOffset)
        
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
        
    case kAudioFileStreamProperty_BitRate:
        var bitRate: UInt32 = 0
        get(value: &bitRate)
        info.bitRate = bitRate
        os_log("Bit Rate: %i", log: Parser.loggerPropertyListenerCallback, type: .error, bitRate)
        
    case kAudioFileStreamProperty_InfoDictionary:
        os_log("kAudioFileStreamProperty_InfoDictionary", log: Parser.loggerPropertyListenerCallback, type: .debug)
        
    default:
        os_log("Unkown Property: [%@]", log: Parser.loggerPropertyListenerCallback, type: .debug, String(describing: propertyID))
    }
}
