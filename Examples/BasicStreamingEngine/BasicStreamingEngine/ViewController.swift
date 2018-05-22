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
    static let logger = OSLog(subsystem: "com.ausomeapps.fstreamer", category: "ViewController")

    struct TapReader {
        static let bufferSize: AVAudioFrameCount = 8192
        static let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                          sampleRate: 44100,
                                          channels: 2,
                                          interleaved: false)!
    }
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationTimeLabel: UILabel!
    @IBOutlet weak var progressSlider: ProgressSlider!
    @IBOutlet weak var formatSegmentControl: UISegmentedControl!
    @IBOutlet weak var startDownloadButton: UIButton!
    @IBOutlet weak var downloadProgressView: UIProgressView!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var rateSlider: UISlider!
    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var pitchSlider: UISlider!
    var isSeeking: Bool = false
    
    var parser: Parser?
    var reader: Reader?
    
    let engine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
    let pitchShifterNode = AVAudioUnitTimePitch()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        /// Download
        let url = URL(string: "https://res.cloudinary.com/drvibcm45/video/upload/v1526487111/bensound-creativeminds_iey0tr.mp3")!
        Downloader.shared.url = url
        Downloader.shared.delegate = self
     
        /// Parse
        do {
            self.parser = try Parser()
        } catch {
            os_log("Failed to create parser: %@", log: ViewController.logger, type: .error, error.localizedDescription)
        }
        
        /// Engine
        setupEngine()
        
        resetPitch(self)
        resetRate(self)
        
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) {
            [weak self] (timer) in
            
            if let currentTime = self?.currentTime, let duration = self?.duration {
                
                if let isSeeking = self?.isSeeking, !isSeeking {
                    self?.progressSlider.value = Float(currentTime)
                    self?.currentTimeLabel.text = self?.formatToMMSS(currentTime)
                }
                
                if currentTime >= duration {
                    self?.playerNode.pause()
                    self?.playButton.setTitle("Play", for: .normal)
                }
            }
        }
        
        Downloader.shared.start()
    }
    
    func setupEngine() {
        /// Setup session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
            try session.setActive(true)
        } catch {
            os_log("Failed to activate audio session: %@", log: ViewController.logger, type: .default, #function, #line, error.localizedDescription)
        }

        /// Make connections
        engine.attach(playerNode)
        engine.attach(pitchShifterNode)
        engine.connect(playerNode, to: pitchShifterNode, format: TapReader.format)
        engine.connect(pitchShifterNode, to: engine.mainMixerNode, format: TapReader.format)
        engine.prepare()
        
        /// Use timer to schedule the buffers (this is not ideal)
        let interval = 1 / (TapReader.format.sampleRate / Double(TapReader.bufferSize))
        Timer.scheduledTimer(withTimeInterval: interval / 2, repeats: true) {
            [weak self] (timer) in
            
            guard let playerNode = self?.playerNode else {
                return
            }
            
            guard let reader = self?.reader else {
                os_log("No reader yet...", log: ViewController.logger, type: .debug)
                return
            }

            guard let nextScheduledBuffer = reader.read(TapReader.bufferSize) else {
                os_log("No next scheduled buffer yet...", log: ViewController.logger, type: .debug)
                return
            }

            // This is copying the buffer internally in some kind of circular buffer
            playerNode.scheduleBuffer(nextScheduledBuffer)
        }
    }

    @IBAction func togglePlayback(_ sender: UIButton) {
        os_log("%@ - %d", log: ViewController.logger, type: .debug, #function, #line)
        
        if playerNode.isPlaying {
            playerNode.pause()
            engine.pause()
            playButton.setTitle("Play", for: .normal)
        } else {
            if !engine.isRunning {
                do {
                    try engine.start()
                } catch {
                    os_log("Failed to start engine: %@", log: ViewController.logger, type: .error, error.localizedDescription)
                }
            }
            playerNode.play()
            playButton.setTitle("Pause", for: .normal)
        }
    }
    
    @IBAction func seek(_ sender: UISlider) {
        os_log("%@ - %d [%.1f]", log: ViewController.logger, type: .debug, #function, #line, progressSlider.value)
        
        let isPlaying = playerNode.isPlaying
        
        guard let parser = parser, let reader = reader else {
            return
        }

        let currentTime = TimeInterval(progressSlider.value)
        guard let frameOffset = parser.frameOffset(forTime: currentTime),
              let packetOffset = parser.packetOffset(forFrame: frameOffset) else {
            return
        }
        
        currentTimeOffset = currentTime
        
        playerNode.stop()
        
        reader.seek(packetOffset)
        
        if isPlaying {
            playerNode.play()
        }
    }
    
    @IBAction func progressSliderTouchedDown(_ sender: UISlider) {
        os_log("Slider touched down")
        
        isSeeking = true
    }
    
    @IBAction func progressSliderValueChanged(_ sender: UISlider) {
        os_log("Slider value changed")
        
        let currentTime = TimeInterval(sender.value)
        currentTimeLabel.text = formatToMMSS(currentTime)
    }
    
    @IBAction func progressSliderTouchedUp(_ sender: UISlider) {
        os_log("Slider touched up")
        
        seek(sender)
        isSeeking = false
    }
    
    @IBAction func changePitch(_ sender: UISlider) {
        os_log("%@ - %d [%.1f]", log: ViewController.logger, type: .debug, #function, #line, sender.value)
        
        let pitch = roundf(sender.value)
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
    
    @IBAction func changeRate(_ sender: UISlider) {
        os_log("%@ - %d [%.1f]", log: ViewController.logger, type: .debug, #function, #line, sender.value)
        
        let rate = sender.value
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
    
    func formatToMMSS(_ time: TimeInterval) -> String {
        let ts = Int(time)
        let s = ts % 60
        let m = (ts / 60) % 60
        return String(format: "%02d:%02d", m, s)
    }
    
}

