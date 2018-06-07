//
//  StreamableDelegate.swift
//  AudioStreamer
//
//  Created by Syed Haris Ali on 6/5/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation

/// The `StreamableDelegate` provides an interface for responding to changes to a `Streamable` instance. These include whenever the streamer state changes, when the download progress changes, as well as the current time and duration changes.
public protocol StreamableDelegate: class {

    /// Triggered when the downloader fails
    ///
    /// - Parameters:
    ///   - streamer: The current `Streamable` instance
    ///   - error: An `Error` representing the reason the download failed
    ///   - url: A `URL` representing the current resource the progress value is for.
    func streamer(_ streamer: Streamable, failedDownloadWithError error: Error, forURL url: URL)
    
    /// Triggered when the downloader's progress value changes.
    ///
    /// - Parameters:
    ///   - streamer: The current `Streamable` instance
    ///   - progress: A `Float` representing the current progress ranging from 0 - 1.
    ///   - url: A `URL` representing the current resource the progress value is for.
    func streamer(_ streamer: Streamable, updatedDownloadProgress progress: Float, forURL url: URL)
    
    /// Triggered when the playback `state` changes.
    ///
    /// - Parameters:
    ///   - streamer: The current `Streamable` instance
    ///   - state: A `StreamableState` representing the new state value.
    func streamer(_ streamer: Streamable, changedState state: StreamableState)
    
    /// Triggered when the current play time is updated.
    ///
    /// - Parameters:
    ///   - streamer: The current `Streamable` instance
    ///   - currentTime: A `TimeInterval` representing the new current time value.
    func streamer(_ streamer: Streamable, updatedCurrentTime currentTime: TimeInterval)
    
    /// Triggered when the duration is updated.
    ///
    /// - Parameters:
    ///   - streamer: The current `Streamable` instance
    ///   - duration: A `TimeInterval` representing the new duration value.
    func streamer(_ streamer: Streamable, updatedDuration duration: TimeInterval)
    
}
