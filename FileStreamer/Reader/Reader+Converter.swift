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
                             _ ioPacketCount: UnsafeMutablePointer<UInt32>,
                             _ ioData: UnsafeMutablePointer<AudioBufferList>,
                             _ outPacketDescriptions: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?,
                             _ context: UnsafeMutableRawPointer?) -> OSStatus {
    let reader = Unmanaged<Reader>.fromOpaque(context!).takeUnretainedValue()

    let inPacketCount = Int(ioPacketCount.pointee)
    let currentPacketIndex = Int(reader.currentPacket)
    let packets = reader.parser.packets
    let packetCount = packets.count
    
    //
    guard currentPacketIndex != packetCount - 1 else {
        os_log("End of data", log: Reader.loggerConverter, type: .debug)
        return ReaderReachedEndOfDataError
    }
    
    var outPacketCount: Int
    if currentPacketIndex + inPacketCount <= packetCount - 1 {
        outPacketCount = inPacketCount
    } else {
        outPacketCount = packetCount - 1 - currentPacketIndex
    }
    
    /// Copy over packet data (outPacketCount number of packets)
    var dataCount = 0
    var data = Data()
    
    let startPacketIndex = currentPacketIndex
    let endPacketIndex = Int(currentPacketIndex + outPacketCount)
    let packetSubset = packets[startPacketIndex..<endPacketIndex]

    for packet in packetSubset {
        dataCount = dataCount + packet.0.count
        data.append(packet.0)
    }
    
    ioData.pointee.mBuffers.mData = UnsafeMutableRawPointer.allocate(bytes: dataCount, alignedTo: 0)
    _ = data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
        memcpy((ioData.pointee.mBuffers.mData?.assumingMemoryBound(to: UInt8.self))!, bytes, dataCount)
    }
    ioData.pointee.mBuffers.mDataByteSize = UInt32(dataCount)
    
    os_log("%@ - %d [totalPackets: %i, inPackets: %i, outPackets: %i, current: %i, subset count: %i, data count: %i]", log: Reader.loggerConverter, type: .debug, #function, #line, reader.parser.packets.count, inPacketCount, outPacketCount ,reader.currentPacket, packetSubset.count, dataCount)
    
    ioPacketCount.pointee = UInt32(outPacketCount)
    reader.currentPacket = AVAudioPacketCount(endPacketIndex)

    return noErr
}
