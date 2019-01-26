//
//  ViewController.swift
//  TimePitchStreamer
//
//  Created by Haris Ali on 1/26/19.
//  Copyright © 2019 Ausome Apps LLC. All rights reserved.
//

import AudioStreamer
import AVFoundation
import Cocoa
import os.log

class ViewController: NSViewController {
    static let logger = OSLog(subsystem: "com.ausomeapps", category: "ViewController")
    var logger: OSLog {
        return ValueChangeController.logger
    }
    
    // MARK: - Properties
    
    @IBOutlet weak var currentTimeLabel: NSTextField!
    @IBOutlet weak var durationTimeLabel: NSTextField!
    @IBOutlet weak var playbackControlsStackView: NSStackView!
    @IBOutlet weak var playButton: NSButton! {
        willSet {
            newValue.setFilterColor(NSColor(red: 0.18, green: 0.243, blue: 0.345, alpha: 1))
        }
    }
    @IBOutlet weak var progressIndicator: NSProgressIndicator! {
        willSet {
            newValue.isIndeterminate = false
            newValue.setFilterColor(NSColor(red: 0.18, green: 0.243, blue: 0.345, alpha: 1))
        }
    }
    @IBOutlet weak var seekSlider: NSSlider! {
        willSet {
            newValue.doubleValue = 0
            newValue.setFilterColor(NSColor(red: 0.18, green: 0.243, blue: 0.345, alpha: 1))
        }
    }
    @IBOutlet weak var stackView: NSStackView!
    
    var isSeeking = false
    var seekTimer: Timer?
    
    lazy var pitchController: ValueChangeController = {
        let vc = ValueChangeController()
        vc.setup(self,
                 title: "Pitch",
                 subtitle: "0 cents",
                 filterColor: NSColor(red: 0.176, green: 0.667, blue: 0.941, alpha: 1),
                 currentValue: 0,
                 minValue: -600,
                 maxValue: 600)
        return vc
    }()
    
    lazy var rateController: ValueChangeController = {
        let vc = ValueChangeController()
        vc.setup(self,
                 title: "Rate",
                 subtitle: "1.00x",
                 filterColor: NSColor(red: 0.596, green: 0.459, blue: 0.839, alpha: 1),
                 currentValue: 1,
                 minValue: 0.5,
                 maxValue: 2)
        return vc
    }()
    
    lazy var streamer: TimePitchStreamer = {
        let streamer = TimePitchStreamer()
        streamer.delegate = self
        return streamer
    }()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(red: 0.953, green: 0.965, blue: 0.984, alpha: 1).cgColor
        
        /// Setup value change controllers
        stackView.addArrangedSubview(pitchController.view)
        stackView.addArrangedSubview(rateController.view)
        
        /// Download
        let url = URL(string: "https://cdn.fastlearner.media/bensound-rumble.mp3")!
        streamer.url = url
    }
    
    // MARK: - Methods
    
    @IBAction func playButtonPressed(_ sender: NSButton) {
        os_log("%@ - %d", log: logger, type: .debug, #function, #line)
        
        if streamer.state == .playing {
            streamer.pause()
        } else {
            streamer.play()
        }
    }
    
    @IBAction func seekSliderValueChanged(_ sender: NSSlider) {
        os_log("%@ - %d", log: logger, type: .debug, #function, #line)
        
        let currentTime = TimeInterval(seekSlider.doubleValue)
        currentTimeLabel.stringValue = currentTime.toMMSS()
        
        isSeeking = true
        seekTimer?.invalidate()
        seekTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(seek), userInfo: nil, repeats: false)
    }
    
    @objc func seek() {
        os_log("%@ - %d", log: logger, type: .debug, #function, #line)
        
        do {
            let time = TimeInterval(seekSlider.doubleValue)
            try streamer.seek(to: time)
        } catch {
            os_log("Failed to seek: %@", log: logger, type: .error, error.localizedDescription)
        }
        
        isSeeking = false
    }

}
