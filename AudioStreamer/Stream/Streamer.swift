//
//  Streamer.swift
//  AudioStreamer
//
//  Created by Syed Haris Ali on 6/5/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import AVFoundation
import Foundation
import os.log

/// The `Streamer` is a concrete implementation of the `Streaming` protocol and is intended to provide a high-level, extendable class for streaming an audio file living at a URL on the internet. Subclasses can override the `attachNodes` and `connectNodes` methods to insert custom effects.
open class Streamer: Streaming {
    static let logger = OSLog(subsystem: "com.fastlearner.streamer", category: "Streamer")

    /// A `DispatchQueue` used to ensure any operations we do changing the current packet index is thread-safe
    static let queue = DispatchQueue(label: "com.fastlearner.streamer")

    // MARK: - Properties (Streaming)
    
    public var currentTime: TimeInterval? {
        guard let nodeTime = playerNode.lastRenderTime,
            let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
            return currentTimeOffset
        }
        let currentTime = TimeInterval(playerTime.sampleTime) / playerTime.sampleRate
        return currentTime + currentTimeOffset
    }
    public var delegate: StreamingDelegate?
    public internal(set) var duration: TimeInterval?
    public lazy var downloader: Downloading = {
        let downloader = Downloader()
        downloader.delegate = self
        return downloader
    }()
    public internal(set) var parser: Parsing?
    public internal(set) var reader: Reading?
    public var engine = AVAudioEngine()
    public let playerNode = AVAudioPlayerNode()
    public internal(set) var state: StreamingState = .stopped {
        didSet {
            delegate?.streamer(self, changedState: state)
        }
    }
    public var url: URL? {
        didSet {
            reset()

            if let url = url {
                downloader.url = url
                downloader.start()
            }
        }
    }
    public var volume: Float {
        get {
            return engine.mainMixerNode.outputVolume
        }
        set {
            engine.mainMixerNode.outputVolume = newValue
        }
    }
    var volumeRampTimer: Timer?
    var volumeRampTargetValue: Float?

    // MARK: - Properties
    
    /// A `TimeInterval` used to calculate the current play time relative to a seek operation.
    var currentTimeOffset: TimeInterval = 0
    
    /// A `Bool` indicating whether the file has been completely scheduled into the player node.
    var isFileSchedulingComplete = false

    /// A `TimeInterval` used to calculate the current play time relative to a seek operation.
    var previousTimeOffset: TimeInterval = 0

    // MARK: - Lifecycle
    
    public init() {        
        // Setup the audio engine (attach nodes, connect stuff, etc). No playback yet.
        setupAudioEngine()
    }

    // MARK: - Setup

    func setupAudioEngine() {
        os_log("%@ - %d", log: Streamer.logger, type: .debug, #function, #line)

        // Attach nodes
        attachNodes()

        // Node nodes
        connectNodes()

        // Prepare the engine
        engine.prepare()
        
        /// Use timer to schedule the buffers (this is not ideal, wish AVAudioEngine provided a pull-model for scheduling buffers)
        let interval = 1 / (readFormat.sampleRate / Double(readBufferSize))
        let timer = Timer(timeInterval: interval / 2, repeats: true) {
            [weak self] _ in
            guard self?.state == .playing else {
                return
            }
            
            self?.scheduleNextBuffer()
            self?.handleTimeUpdate()
            self?.notifyTimeUpdated()
        }
        RunLoop.current.add(timer, forMode: .common)
    }

    /// Subclass can override this to attach additional nodes to the engine before it is prepared. Default implementation attaches the `playerNode`. Subclass should call super or be sure to attach the playerNode.
    open func attachNodes() {
        engine.attach(playerNode)
    }

    /// Subclass can override this to make custom node connections in the engine before it is prepared. Default implementation connects the playerNode to the mainMixerNode on the `AVAudioEngine` using the default `readFormat`. Subclass should use the `readFormat` property when connecting nodes.
    open func connectNodes() {
        engine.connect(playerNode, to: engine.mainMixerNode, format: readFormat)
    }

    open func resume() {

        os_log("🌶 Previous Time was %d", log: Streamer.logger, type: .debug, previousTimeOffset)
        currentTimeOffset = previousTimeOffset

        engine.disconnectNodeInput(playerNode)
        engine.detach(playerNode)

        engine = AVAudioEngine()

        attachNodes()
        connectNodes()
        
        
        os_log("%@ - %d", log: Streamer.logger, type: .debug, #function, #line)

        // Attach nodes
//        attachNodes()

        // Node nodes
//        connectNodes()

        // Prepare the engine
        engine.prepare()
        
        
        if engine.isRunning == false {
            os_log("🌶 Starting back engine", log: Streamer.logger, type: .debug)
            do {
                try engine.start()
            } catch {
                os_log("🌶 Can not start engine", log: Streamer.logger, type: .debug)
            }
        } else {
            os_log("🌶 Already running", log: Streamer.logger, type: .debug)
        }
    }
    
    // MARK: - Reset
    
    func reset() {
        os_log("%@ - %d", log: Streamer.logger, type: .debug, #function, #line)
        
        // Reset the playback state
        stop()
        duration = nil
        reader = nil
        isFileSchedulingComplete = false
        previousTimeOffset = 0
        currentTimeOffset = 0
        
        // Create a new parser
        do {
            parser = try Parser()
        } catch {
            os_log("Failed to create parser: %@", log: Streamer.logger, type: .error, error.localizedDescription)
        }
    }
    
    // MARK: - Methods
    
    public func play() {
        os_log("%@ - %d", log: Streamer.logger, type: .debug, #function, #line)
        
        // Check we're not already playing
        guard !playerNode.isPlaying else {
            os_log("%@ - %d // Already playing", log: Streamer.logger, type: .debug, #function, #line)
            return
        }
        
        if !engine.isRunning {
            os_log("🌶 Engine not running", log: Streamer.logger, type: .debug)
            do {
                try engine.start()
            } catch {
                os_log("Failed to start engine: %@", log: Streamer.logger, type: .debug, error.localizedDescription)
            }
        } else {
            os_log("🌶 Engine running", log: Streamer.logger, type: .debug)
        }
        
        os_log("🌶 Wait", log: Streamer.logger, type: .debug)
        
        // To make the volume change less harsh we mute the output volume
        let lastVolume = volumeRampTargetValue ?? volume
        volume = 0
        
        // Start playback on the player node
        playerNode.play()
        
        // After 250ms we restore the volume to where it was
        swellVolume(to: lastVolume)
        
        // Update the state
        state = .playing
    }
    
    public func pause() {
        os_log("%@ - %d", log: Streamer.logger, type: .debug, #function, #line)
        
        // Check if the player node is playing
        guard playerNode.isPlaying else {
            return
        }

        // Pause the player node and the engine
        engine.pause()
        playerNode.pause()
        
        // Update the state
        state = .paused
    }
    
    public func stop() {
        os_log("%@ - %d", log: Streamer.logger, type: .debug, #function, #line)
        
        // Stop the downloader, the player node, and the engine
        downloader.stop()
        playerNode.stop()
        engine.stop()
        
        // Update the state
        state = .stopped
    }
    
    public func seek(to time: TimeInterval) throws {
        os_log("%@ - %d [%.1f]", log: Streamer.logger, type: .debug, #function, #line, time)
        
        // Make sure we have a valid parser and reader
        guard let parser = parser, let reader = reader else {
            return
        }
        
        // Get the proper time and packet offset for the seek operation
        guard let frameOffset = parser.frameOffset(forTime: time),
            let packetOffset = parser.packetOffset(forFrame: frameOffset) else {
                return
        }
        print("🌶 Seek Frame [\(frameOffset)] -- Packet [\(packetOffset)]")
        currentTimeOffset = time
        isFileSchedulingComplete = false
        
        // We need to store whether or not the player node is currently playing to properly resume playback after
        let isPlaying = playerNode.isPlaying
        let lastVolume = volumeRampTargetValue ?? volume
        
        // Stop the player node to reset the time offset to 0
        playerNode.stop()
        volume = 0
        
        // Perform the seek to the proper packet offset
        do {
            try reader.seek(packetOffset)
        } catch {
            os_log("Failed to seek: %@", log: Streamer.logger, type: .error, error.localizedDescription)
            return
        }
        
        // If the player node was previous playing then resume playback
        if isPlaying {
            playerNode.play()
        }
        
        // Update the current time
        delegate?.streamer(self, updatedCurrentTime: time)
        
        // After 250ms we restore the volume back to where it was
        swellVolume(to: lastVolume)
    }
    
    func swellVolume(to newVolume: Float, duration: TimeInterval = 0.5) {
        volumeRampTargetValue = newVolume
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(duration*1000/2))) { [unowned self] in
            self.volumeRampTimer?.invalidate()
            let timer = Timer(timeInterval: Double(Float((duration/2.0))/(newVolume * 10)), repeats: true) { timer in
                if self.volume != newVolume {
                    self.volume = min(newVolume, self.volume + 0.1)
                } else {
                    self.volumeRampTimer = nil
                    self.volumeRampTargetValue = nil
                    timer.invalidate()
                }
            }
            RunLoop.current.add(timer, forMode: .common)
            self.volumeRampTimer = timer
        }
    }

    // MARK: - Scheduling Buffers

    func scheduleNextBuffer() {
        guard let reader = reader else {
            os_log("No reader yet...", log: Streamer.logger, type: .debug)
            return
        }
        
        guard !isFileSchedulingComplete else {
            return
        }
        
         if engine.isRunning == false {
            do {
                os_log("👻 Engine not running - trying to launch", log: Streamer.logger, type: .debug)
                try engine.start()
                return
            } catch {
//                os_log("🌶 Engine Error", log: Streamer.logger, type: .debug)
            }
        }
        
        guard playerNode.isPlaying else {
            os_log("👻 Player node not running - restart it", log: Streamer.logger, type: .debug)
            playerNode.play()
            return
        }

        do {
//            if engine.isRunning {
//                os_log("🌶 Engine running - Read next buffer", log: Streamer.logger, type: .debug)
//            } else {
//                os_log("🌶 Engine not running - Read next buffer", log: Streamer.logger, type: .debug)
//            }
            let nextScheduledBuffer = try reader.read(readBufferSize)
            playerNode.scheduleBuffer(nextScheduledBuffer)
        } catch ReaderError.reachedEndOfFile {
            if downloader.state == .completed {
                os_log("🌶 Scheduler reached end of file", log: Streamer.logger, type: .debug)
                isFileSchedulingComplete = true
            } else if downloader.state == .started {
                pause()
                state = .buffering
                os_log("🌶 Buffering", log: Streamer.logger, type: .debug)
            } else {
                os_log("🌶 Downloader in weird state", log: Streamer.logger, type: .debug)
            }
        } catch {
            os_log("Cannot schedule buffer: %@", log: Streamer.logger, type: .debug, error.localizedDescription)
        }
    }

    // MARK: - Handling Time Updates
    
    /// Handles the duration value, explicitly checking if the duration is greater than the current value. For indeterminate streams we can accurately estimate the duration using the number of packets parsed and multiplying that by the number of frames per packet.
    func handleDurationUpdate() {
        if let newDuration = parser?.duration {
            // Check if the duration is either nil or if it is greater than the previous duration
            var shouldUpdate = false
            if duration == nil {
                shouldUpdate = true
            } else if let oldDuration = duration, oldDuration < newDuration {
                shouldUpdate = true
            }
            
            // Update the duration value
            if shouldUpdate {
                self.duration = newDuration
                notifyDurationUpdate(newDuration)
            }
        }
    }
    
    /// Handles the current time relative to the duration to make sure current time does not exceed the duration
    func handleTimeUpdate() {
        guard let currentTime = currentTime, let duration = duration else {
            return
        }
        
        previousTimeOffset = currentTime

//        if currentTime >= duration {
//            try? seek(to: 0)
//            pause()
//        }
    }

    // MARK: - Notifying The Delegate

    func notifyDownloadProgress(_ progress: Float) {
        guard let url = url else {
            return
        }
        if state == .buffering {
            isFileSchedulingComplete = false
            os_log("Reset file scheduling - Downloading not finished", log: Streamer.logger, type: .debug)
        }
        delegate?.streamer(self, updatedDownloadProgress: progress, forURL: url)
    }

    func notifyDurationUpdate(_ duration: TimeInterval) {
        guard let _ = url else {
            return
        }

        delegate?.streamer(self, updatedDuration: duration)
    }

    func notifyTimeUpdated() {
        guard engine.isRunning, playerNode.isPlaying else {
            return
        }

        guard let currentTime = currentTime else {
            return
        }

        delegate?.streamer(self, updatedCurrentTime: currentTime)
    }
}
