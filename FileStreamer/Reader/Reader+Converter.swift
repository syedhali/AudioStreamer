//
//  Reader+Converter.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/7/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation
import AudioToolbox
import os.log

let ReaderReachedEndOfDataError: OSStatus = 932332581
let ReaderPartialConversionError: OSStatus = 932332582
let ReaderNotEnoughDataError: OSStatus = 932332583

func ReaderConverterCallback(_ converter: AudioConverterRef,
                             _ packetCount: UnsafeMutablePointer<UInt32>,
                             _ ioData: UnsafeMutablePointer<AudioBufferList>,
                             _ outPacketDescriptions: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?,
                             _ context: UnsafeMutableRawPointer?) -> OSStatus {
    let reader = Unmanaged<Reader>.fromOpaque(context!).takeUnretainedValue()
    
    let packetIndex = Int(reader.currentPacket)
    let packets = reader.parser.packets
    
    //
    // Check if the packet index exceeds the number of packets we currently
    // have (this could occur in a seek operation)
    //
    
    if packetIndex > packets.count {
        return ReaderNotEnoughDataError
    }
    
    //
    // Check if we've reached the end of the packets
    //
    
    let isParsingComplete = reader.parser.isParsingComplete
    if isParsingComplete, packetIndex >= packets.count - 1 {
        packetCount.pointee = 0
        return ReaderReachedEndOfDataError
    }
    
    //
    // Copy data over
    //
    
    let packet = packets[packetIndex]
    ioData.pointee.mNumberBuffers = 1
    
    var data = packet.0
    let dataCount = data.count
    ioData.pointee.mBuffers.mData = UnsafeMutableRawPointer.allocate(byteCount: dataCount, alignment: 0)
    _ = data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
        memcpy((ioData.pointee.mBuffers.mData?.assumingMemoryBound(to: UInt8.self))!, bytes, dataCount)
    }
    ioData.pointee.mBuffers.mDataByteSize = UInt32(dataCount)
    
    //
    // packet descriptions
    //
    if reader.sourceFormat.mFormatID != kAudioFormatLinearPCM {
        struct PacketDescriptionHolder {
            static var lastPacketDescription: UnsafeMutablePointer<AudioStreamPacketDescription>?
        }
        if PacketDescriptionHolder.lastPacketDescription == nil {
            PacketDescriptionHolder.lastPacketDescription = UnsafeMutablePointer<AudioStreamPacketDescription>.allocate(capacity: 1)
        }
        outPacketDescriptions?.pointee = PacketDescriptionHolder.lastPacketDescription
        PacketDescriptionHolder.lastPacketDescription?.pointee.mDataByteSize = UInt32(dataCount)
        PacketDescriptionHolder.lastPacketDescription?.pointee.mStartOffset = 0
        PacketDescriptionHolder.lastPacketDescription?.pointee.mVariableFramesInPacket = 0
    }
    
    packetCount.pointee = 1
    reader.currentPacket = reader.currentPacket + 1
    
    return noErr;
}
