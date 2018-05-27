//
//  ViewController.swift
//  BasicStreamingEngine
//
//  Created by Syed Haris Ali on 1/7/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import UIKit
import AVFoundation
import FileStreamer
import os.log

class ViewController: UIViewController {
    static let logger = OSLog(subsystem: "com.fastlearner.streamer", category: "ViewController")
    
    // UI props
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationTimeLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var rateSlider: UISlider!
    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var pitchSlider: UISlider!
    @IBOutlet weak var progressSlider: ProgressSlider!
    var isSeeking: Bool = false
    var reachedEndOfFile: Bool = false
    
    // Streamer props
    var parser: Parser?
    var reader: Reader?
    
    // AVAudioEngine related props
    let engine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
    let pitchShifterNode = AVAudioUnitTimePitch()
    let readBufferSize: AVAudioFrameCount = 8192
    let readFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)!
    
    // Playback state props
    var currentTimeOffset: TimeInterval = 0
    var currentTime: TimeInterval? {
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
                return nil
        }
        let currentTime = TimeInterval(playerTime.sampleTime) / playerTime.sampleRate
        return currentTime + currentTimeOffset
    }
    var duration: TimeInterval? {
        return parser?.duration
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /// Download
        let url = URL(string: "http://cdn.staging.fastlearner.media/do-it-alone.mp3")!
        Downloader.shared.url = url
        Downloader.shared.delegate = self
     
        /// Parse
        do {
            self.parser = try Parser()
        } catch {
            os_log("Failed to create parser: %@", log: ViewController.logger, type: .error, error.localizedDescription)
        }
        
        // Setup the AVAudioSession and AVAudioEngine
        setupAudioSession()
        setupAudioEngine()
        
        // Reset the pitch and rate
        resetPitch(self)
        resetRate(self)
        
        // Start downloading the file
        Downloader.shared.start()
    }
    
    // MARK: - Setting Up The Engine
    
    func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
            try session.setActive(true)
        } catch {
            os_log("Failed to activate audio session: %@", log: ViewController.logger, type: .default, #function, #line, error.localizedDescription)
        }
    }
    
    func setupAudioEngine() {
        // Attach nodes
        engine.attach(playerNode)
        engine.attach(pitchShifterNode)
        
        // Node nodes
        engine.connect(playerNode, to: pitchShifterNode, format: readFormat)
        engine.connect(pitchShifterNode, to: engine.mainMixerNode, format: readFormat)
        
        // Prepare the engine
        engine.prepare()
        
        /// Use timer to schedule the buffers (this is not ideal, wish AVAudioEngine provided a pull-model for scheduling buffers)
        let interval = 1 / (readFormat.sampleRate / Double(readBufferSize))
        Timer.scheduledTimer(withTimeInterval: interval / 2, repeats: true) {
            [weak self] (timer) in
            self?.scheduleNextBuffer()
            self?.updateTimeDisplay()
        }
    }
    
    // MARK: - Scheduling Buffers
    
    func scheduleNextBuffer() {
        guard let reader = reader else {
            os_log("No reader yet...", log: ViewController.logger, type: .debug)
            return
        }
        
        guard !reachedEndOfFile else {
            return
        }
        
        do {
            let nextScheduledBuffer = try reader.read(readBufferSize)
            playerNode.scheduleBuffer(nextScheduledBuffer)
        } catch ReaderError.reachedEndOfFile {
            os_log("Scheduler reached end of file", log: ViewController.logger, type: .debug)
            reachedEndOfFile = true
        } catch {
            os_log("Cannot schedule buffer: %@", log: ViewController.logger, type: .debug, error.localizedDescription)
        }
    }
    
    // MARK: - Updating The Time Display
    
    func updateTimeDisplay() {
        guard let currentTime = currentTime, let duration = duration else {
            return
        }
        
        if currentTime >= duration {
            playerNode.pause()
            playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        }
        
        if !isSeeking {
            progressSlider.value = Float(currentTime)
            currentTimeLabel.text = formatToMMSS(currentTime)
        }
    }

    // MARK: - Playback
    
    @IBAction func togglePlayback(_ sender: UIButton) {
        os_log("%@ - %d", log: ViewController.logger, type: .debug, #function, #line)
        
        if playerNode.isPlaying {
            playerNode.pause()
            engine.pause()
            playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        } else {
            if !engine.isRunning {
                do {
                    try engine.start()
                } catch {
                    os_log("Failed to start engine: %@", log: ViewController.logger, type: .error, error.localizedDescription)
                }
            }
            playerNode.play()
            playButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        }
    }
    
    /// MARK: - Handle Seeking
    
    @IBAction func seek(_ sender: UISlider) {
        os_log("%@ - %d [%.1f]", log: ViewController.logger, type: .debug, #function, #line, progressSlider.value)
        
        guard let parser = parser, let reader = reader else {
            return
        }

        // Get the proper time and packet offset for the seek operation
        let currentTime = TimeInterval(progressSlider.value)
        guard let frameOffset = parser.frameOffset(forTime: currentTime),
              let packetOffset = parser.packetOffset(forFrame: frameOffset) else {
            return
        }
        currentTimeOffset = currentTime
        reachedEndOfFile = false
        
        // We need to store whether or not the player node is currently playing to properly resume playback after
        let isPlaying = playerNode.isPlaying
        
        // Stop the player node to reset the time offset to 0
        playerNode.stop()
        
        // Perform the seek to the proper packet offset
        reader.seek(packetOffset)
        
        // If the player node was previous playing then resume playback
        if isPlaying {
            playerNode.play()
        }
    }
    
    @IBAction func progressSliderTouchedDown(_ sender: UISlider) {
        os_log("%@ - %d", log: ViewController.logger, type: .debug, #function, #line)
        
        isSeeking = true
    }
    
    @IBAction func progressSliderValueChanged(_ sender: UISlider) {
        os_log("%@ - %d", log: ViewController.logger, type: .debug, #function, #line)
        
        let currentTime = TimeInterval(sender.value)
        currentTimeLabel.text = formatToMMSS(currentTime)
    }
    
    @IBAction func progressSliderTouchedUp(_ sender: UISlider) {
        os_log("%@ - %d", log: ViewController.logger, type: .debug, #function, #line)
        
        seek(sender)
        isSeeking = false
    }
    
    /// MARK: - Change Pitch
    
    @IBAction func changePitch(_ sender: UISlider) {
        os_log("%@ - %d [%.1f]", log: ViewController.logger, type: .debug, #function, #line, sender.value)
        
        let step: Float = 100
        var pitch = roundf(sender.value)
        let newStep = roundf(pitch / step)
        pitch = newStep * step
        sender.value = pitch
        pitchShifterNode.pitch = pitch
        pitchLabel.text = String(format: "%i cents", Int(pitch))
    }
    
    @IBAction func resetPitch(_ sender: Any) {
        os_log("%@ - %d [%.1f]", log: ViewController.logger, type: .debug, #function, #line)
        
        let pitch: Float = 0
        pitchShifterNode.pitch = pitch
        pitchLabel.text = String(format: "%i cents", Int(pitch))
        pitchSlider.value = pitch
    }
    
    /// MARK: - Change Rate
    
    @IBAction func changeRate(_ sender: UISlider) {
        os_log("%@ - %d [%.1f]", log: ViewController.logger, type: .debug, #function, #line, sender.value)
        
        let step: Float = 0.25
        var rate = sender.value
        let newStep = roundf(rate / step)
        rate = newStep * step
        sender.value = rate
        pitchShifterNode.rate = rate
        rateLabel.text = String(format: "%.2fx", rate)
    }
    
    @IBAction func resetRate(_ sender: Any) {
        os_log("%@ - %d [%.1f]", log: ViewController.logger, type: .debug, #function, #line)
        
        let rate: Float = 1
        pitchShifterNode.rate = rate
        rateLabel.text = String(format: "%.2fx", rate)
        rateSlider.value = rate
    }
    
    /// MARK: - Utils
    
    func formatToMMSS(_ time: TimeInterval) -> String {
        let ts = Int(time)
        let s = ts % 60
        let m = (ts / 60) % 60
        return String(format: "%02d:%02d", m, s)
    }
    
}

