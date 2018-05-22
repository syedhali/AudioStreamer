//
//  Parsable.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation

/// The `Parsable` protocol represents a generic parser that can be used for converting binary data into audio packets.
public protocol Parsable: class {
    
    // MARK: - Properties
        
    /// The data format of the audio
    var dataFormat: AVAudioFormat? { get }
    
    /// The total duration of the audio. For certain formats such as AAC this my be a guess or only equal to as many packets as have been processed.
    var duration: TimeInterval? { get }
    
    var isParsingComplete: Bool { get }
    
    /// The total number of frames (expressed in the data format)
    var totalFrameCount: AVAudioFrameCount? { get }
    
    /// The total packet count (expressed in the data format)
    var totalPacketCount: AVAudioPacketCount? { get }
    
    /// The file format of the audio (this is the on-disk format). For compressed formats such as MP3 or AAC this will represent the on-disk format, while the `dataFormat` property represents the audio data as it exists in memory)
    var fileFormat: AVAudioFormat? { get }
    
    /// An array of duples, each index presenting a parsed audio packet. For compressed formats each packet of data should contain a `AudioStreamPacketDescription`, which describes the start offset and length of the audio data)
    var packets: [(Data, AudioStreamPacketDescription?)] { get }
    
    // MARK: - Methods
    
    /// Given some data the parser should attempt to convert it into to audio packets.
    ///
    /// - Parameter data: A `Data` instance representing some binary data corresponding to an audio stream.
    func parse(data: Data)
    
    /// Given a frame this method will attempt to provide the packet that frame belongs to for a safe seek operation.
    ///
    /// - Parameter frame: An `AVAudioFrameCount` representing the desired frame
    /// - Returns: An optional `AVAudioPacketCount` representing the packet the frame belongs to. If the `dataFormat` is unknown (not enough data has been provided) then this will return nil.
    func packetOffset(forFrame frame: AVAudioFramePosition) -> AVAudioPacketCount?
    
}

extension Parsable {
    
    public var isParsingComplete: Bool {
        guard let totalPacketCount = totalPacketCount else {
            return false
        }
        
        return packets.count == totalPacketCount
    }
    
}
