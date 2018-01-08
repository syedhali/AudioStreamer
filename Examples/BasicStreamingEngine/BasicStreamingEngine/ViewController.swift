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

    @IBOutlet weak var startDownloadButton: UIButton!
    @IBOutlet weak var downloadProgressView: UIProgressView!
    
    var parser: Parser?
    var reader: Reader?
    
    let engine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
    var readFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: 44100,
                                   channels: 2,
                                   interleaved: false)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        /// Download
        let url = RemoteFileURL.theLastOnes.mp3
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
        engine.connect(playerNode, to: engine.mainMixerNode, format: readFormat)
        engine.prepare()
        
        /// Install tap
//        do {
//            try engine.enableManualRenderingMode(.realtime, format: readFormat, maximumFrameCount: 4096)
//        } catch {
//            os_log("Failed to enable manual rendering mode: %@", log: ViewController.logger, type: .default, #function, #line, error.localizedDescription)
//        }
//
//        guard engine.isInManualRenderingMode else {
//            return
//        }
        
        playerNode.installTap(onBus: 0, bufferSize: 4096, format: readFormat) {
            [weak self] (buffer, time) in

            guard let reader = self?.reader else {
                os_log("No reader yet...", log: ViewController.logger, type: .debug)
                return
            }

            guard let nextScheduledBuffer = reader.read(22050) else {
                os_log("No next scheduled buffer yet...", log: ViewController.logger, type: .debug)
                return
            }

            // This is copying the buffer internally in some kind of circular buffer
            self?.playerNode.scheduleBuffer(nextScheduledBuffer)
            
            
        }
        
        do {
            try engine.start()
            playerNode.play()
        } catch {
            os_log("Engine start failed: %@", log: ViewController.logger, type: .error, error.localizedDescription)
        }
    }
    
    func handleTap(_ buffer: AVAudioPCMBuffer, _ time: AVAudioTime) {
        os_log("%@ - %d", log: ViewController.logger, type: .debug, #function, #line)
        
//        guard let reader = reader else {
//            os_log("No reader yet...", log: ViewController.logger, type: .debug)
//            return
//        }
//
//        guard let nextScheduledBuffer = reader.read(11025) else {
//            os_log("No next scheduled buffer yet...", log: ViewController.logger, type: .debug)
//            return
//        }
//
//
    }
    
    @IBAction func startDownload(_ sender: UIButton) {
        os_log("%@ - %d", log: ViewController.logger, type: .debug, #function, #line)

        Downloader.shared.start()
    }
    
}

