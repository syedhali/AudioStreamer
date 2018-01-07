//
//  Parser+Packets.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation
import os.log

func ParserPacketCallback(_ context: UnsafeMutableRawPointer, _ byteCount: UInt32, _ packetCount: UInt32, _ data: UnsafeRawPointer, _ packetDescriptions: UnsafeMutablePointer<AudioStreamPacketDescription>) {
    let packetDescriptionsOrNil: UnsafeMutablePointer<AudioStreamPacketDescription>? = packetDescriptions
    let isCompressed = packetDescriptionsOrNil != nil
    os_log("%@ - %d [bytes: %i, packets: %i, compressed: %@]", log: Parser.loggerPacketCallback, type: .debug, #function, #line, byteCount, packetCount, "\(isCompressed)")
    
    /// Cast back our context to the info object
    let info = context.assumingMemoryBound(to: Parser.Info.self).pointee
    
    /// At this point we should definitely have a data format
    guard let dataFormat = info.dataFormat else {
        return
    }
    
    /// Iterate through the packets and store the data appropriately
    if isCompressed {
        for i in 0 ..< Int(packetCount) {
            let packetStart = Int(packetDescriptions[i].mStartOffset)
            let packetSize = Int(packetDescriptions[i].mDataByteSize)
            let packetData = Data(bytes: data.advanced(by: packetStart), count: packetSize)
            info.packets.append(packetData)
        }
    } else {
        let format = dataFormat.streamDescription.pointee
        let bytesPerFrame = format.mBytesPerPacket
        for i in 0 ..< Int(packetCount) {
            let packetStart = Int(i)
            let packetSize = Int(bytesPerFrame)
            let packetData = Data(bytes: data.advanced(by: packetStart), count: packetSize)
            info.packets.append(packetData)
        }
    }
}
