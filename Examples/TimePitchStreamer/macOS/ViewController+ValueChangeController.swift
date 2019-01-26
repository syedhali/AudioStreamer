//
//  ViewController+ValueChangeController.swift
//  TimePitchStreamer-macOS
//
//  Created by Haris Ali on 1/26/19.
//  Copyright © 2019 Ausome Apps LLC. All rights reserved.
//

import Cocoa
import os.log

extension ViewController: ValueChangeControllerDelegate {
    
    func valueChangeControllerTappedResetButton(_ controller: ValueChangeController) {
        switch controller {
        case pitchController:
            let pitch: Float = 0
            streamer.pitch = pitch
            pitchController.subtitleLabel.stringValue = String(format: "%i cents", Int(pitch))
            pitchController.slider.floatValue = pitch
        case rateController:
            let rate: Float = 1
            streamer.rate = rate
            rateController.subtitleLabel.stringValue = String(format: "%.2fx", rate)
            rateController.slider.floatValue = rate
        default:
            break
        }
    }
    
    func valueChangeController(_ controller: ValueChangeController, changedValue value: Float) {
        switch controller {
        case pitchController:
            let step: Float = 100
            var pitch = roundf(pitchController.slider.floatValue)
            let newStep = roundf(pitch / step)
            pitch = newStep * step
            streamer.pitch = pitch
            pitchController.slider.floatValue = pitch
            pitchController.subtitleLabel.stringValue = String(format: "%i cents", Int(pitch))
        case rateController:
            let step: Float = 0.25
            var rate = rateController.slider.floatValue
            let newStep = roundf(rate / step)
            rate = newStep * step
            streamer.rate = rate
            rateController.slider.floatValue = rate
            rateController.subtitleLabel.stringValue = String(format: "%.2fx", rate)
        default:
            break
        }
    }
    
}
