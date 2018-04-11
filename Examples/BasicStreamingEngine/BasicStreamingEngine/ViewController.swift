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
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var formatSegmentControl: UISegmentedControl!
    @IBOutlet weak var startDownloadButton: UIButton!
    @IBOutlet weak var downloadProgressLabel: UILabel!
    @IBOutlet weak var downloadProgressView: UIProgressView!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var rateSlider: UISlider!
    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var pitchSlider: UISlider!
    
    lazy var timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        /// Download
        let url = URL(string: "https://res.cloudinary.com/drvibcm45/video/upload/v1515808303/05_Ro%CC%88yksopp_Forever_chz27m.mp3")!
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
            if let currentTime = self?.currentTime {       
                self?.currentTimeLabel.text = self?.timeFormatter.string(from: currentTime)
            }
        }
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
        
        /// Install tap
        playerNode.installTap(onBus: 0, bufferSize: TapReader.bufferSize/2, format: TapReader.format) {
            [weak self] (buffer, time) in

            guard let reader = self?.reader else {
                os_log("No reader yet...", log: ViewController.logger, type: .debug)
                return
            }

            guard let nextScheduledBuffer = reader.read(TapReader.bufferSize) else {
                os_log("No next scheduled buffer yet...", log: ViewController.logger, type: .debug)
                return
            }

            // This is copying the buffer internally in some kind of circular buffer
            self?.playerNode.scheduleBuffer(nextScheduledBuffer)
        }
    }
    
    @IBAction func changeFormat(_ sender: UISegmentedControl) {
        os_log("%@ - %d", log: ViewController.logger, type: .debug, #function, #line)
        
    }
    
    @IBAction func startDownload(_ sender: UIButton) {
        os_log("%@ - %d", log: ViewController.logger, type: .debug, #function, #line)

        Downloader.shared.start()
        
        startDownloadButton.setTitle("Downloading...", for: .normal)
        startDownloadButton.isEnabled = false
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
        
        let frameOffset = AVAudioFrameCount(round(progressSlider.value))
        guard let packetOffset = parser.packetOffset(forFrame: frameOffset),
              let timeOffset = parser.timeOffset(forFrame: frameOffset)
            else {
            return
        }
        
        currentTimeOffset = timeOffset
        
        playerNode.stop()
        
        reader.currentPacket = packetOffset
        
        if isPlaying {
            playerNode.play()
        }
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
}

