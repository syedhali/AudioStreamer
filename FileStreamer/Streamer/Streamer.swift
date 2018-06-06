//
//  Streamer.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 6/5/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import AVFoundation
import Foundation
import os.log

open class Streamer: Streamable {
    static let logger = OSLog(subsystem: "com.fastlearner.streamer", category: "Streamer")

    public var currentTime: TimeInterval? {
        guard let nodeTime = playerNode.lastRenderTime,
            let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
            return nil
        }
        let currentTime = TimeInterval(playerTime.sampleTime) / playerTime.sampleRate
        return currentTime + currentTimeOffset
    }

    public var delegate: StreamableDelegate?

    public var duration: TimeInterval?

    public let engine = AVAudioEngine()

    public let playerNode = AVAudioPlayerNode()

    public let readBufferSize: AVAudioFrameCount = 8192

    public let readFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)!

    public var state: StreamableState = .stopped

    public var url: URL? {
        didSet {
            stop()
            duration = nil
            reader = nil
            do {
                parser = try Parser()
            } catch {
                os_log("Failed to create parser: %@", log: Streamer.logger, type: .error, error.localizedDescription)
            }
            isFileSchedulingComplete = false
            state = .stopped

            if let url = url {
                downloader.url = url
                downloader.start()
            }
        }
    }

    public var volume: Float {
        get {
            return engine.mainMixerNode.volume
        }
        set {
            engine.mainMixerNode.volume = newValue
        }
    }

    //
    var currentTimeOffset: TimeInterval = 0
    var isFileSchedulingComplete = false
    let downloader: Downloader
    var parser: Parser?
    var reader: Reader?

    public init() {
        downloader = Downloader()
        downloader.delegate = self

        setupAudioEngine()
    }

    // MARK: - Methods

    public func play() {
        os_log("%@ - %d", log: Streamer.logger, type: .debug, #function, #line)

        guard !playerNode.isPlaying else {
            return
        }

        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                os_log("Failed to start engine: %@", log: Streamer.logger, type: .error, error.localizedDescription)
                return
            }
        }

        playerNode.play()

        state = .playing
        delegate?.streamer(self, changedState: state)
    }

    public func pause() {
        os_log("%@ - %d", log: Streamer.logger, type: .debug, #function, #line)

        guard playerNode.isPlaying else {
            return
        }

        playerNode.pause()
        engine.pause()

        state = .paused
        delegate?.streamer(self, changedState: state)
    }

    public func stop() {
        os_log("%@ - %d", log: Streamer.logger, type: .debug, #function, #line)

        downloader.stop()
        playerNode.stop()
        engine.stop()

        state = .stopped
        delegate?.streamer(self, changedState: state)
    }

    public func seek(to time: TimeInterval) throws {
        os_log("%@ - %d [%.1f]", log: Streamer.logger, type: .debug, #function, #line, time)

        guard let parser = parser, let reader = reader else {
            return
        }

        // Get the proper time and packet offset for the seek operation
        guard let frameOffset = parser.frameOffset(forTime: time),
            let packetOffset = parser.packetOffset(forFrame: frameOffset) else {
            return
        }
        currentTimeOffset = time
        isFileSchedulingComplete = false

        // We need to store whether or not the player node is currently playing to properly resume playback after
        let isPlaying = playerNode.isPlaying

        // Stop the player node to reset the time offset to 0
        playerNode.stop()

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

        delegate?.streamer(self, updatedCurrentTime: time)
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
        Timer.scheduledTimer(withTimeInterval: interval / 2, repeats: true) {
            [weak self] _ in
            self?.scheduleNextBuffer()
            self?.handleTimeUpdate()
            self?.notifyTimeUpdated()
        }
    }

    // Subclass can override this to attach additional nodes to the engine before it is prepared. Default implementation attaches the `playerNode`. Subclass should call super or be sure to attach the playerNode.
    open func attachNodes() {
        engine.attach(playerNode)
    }

    // Subclass can override this to make custom node connections in the engine before it is prepared. Default implementation connects the playerNode to the mainMixerNode on the `AVAudioEngine` using the default `readFormat`. Subclass should use the `readFormat` property when connecting nodes.
    open func connectNodes() {
        engine.connect(playerNode, to: engine.mainMixerNode, format: readFormat)
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

        do {
            let nextScheduledBuffer = try reader.read(readBufferSize)
            playerNode.scheduleBuffer(nextScheduledBuffer)
        } catch ReaderError.reachedEndOfFile {
            os_log("Scheduler reached end of file", log: Streamer.logger, type: .debug)
            isFileSchedulingComplete = true
        } catch {
            os_log("Cannot schedule buffer: %@", log: Streamer.logger, type: .debug, error.localizedDescription)
        }
    }

    /// Handles the current time relative to the duration to make sure current time does not exceed the duration
    func handleTimeUpdate() {
        guard let currentTime = currentTime, let duration = duration else {
            return
        }

        if currentTime >= duration {
            try? seek(to: 0)
            stop()
        }
    }

    // MARK: - Notifying stuff

    func notifyDownloadProgress(_ progress: Float) {
        guard let url = url else {
            return
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
