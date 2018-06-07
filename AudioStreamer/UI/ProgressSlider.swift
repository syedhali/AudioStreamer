//
//  ProgressSlider.swift
//  AudioStreamer
//
//  Created by Syed Haris Ali on 5/22/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import UIKit
import os.log

/// The `ProgressSlider` is a `UISlider` subclass that adds a `UIProgressView` to show a deterministic loading state. In streaming this is useful for showing how much of the file has been downloaded.
public class ProgressSlider: UISlider {
    
    /// A `UIProgressView` used to display the track progress layer
    fileprivate let progressView = UIProgressView(progressViewStyle: .default)
    
    /// A `Float` representing the progress value
    @IBInspectable public var progress: Float {
        get {
            return progressView.progress
        }
        set {
            progressView.progress = newValue
        }
    }
    
    /// A `UIColor` representing the progress view's track tint color (right region)
    @IBInspectable public var progressTrackTintColor: UIColor {
        get {
            return progressView.trackTintColor ?? .white
        }
        set {
            progressView.trackTintColor = newValue
        }
    }
    
    /// A `UIColor` representing the progress view's progress tint color (left region)
    @IBInspectable public var progressProgressTintColor: UIColor {
        get {
            return progressView.progressTintColor ?? .blue
        }
        set {
            progressView.progressTintColor = newValue
        }
    }
    
    /// Setup / Drawing
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        insertSubview(progressView, at: 0)
        
        let trackFrame = super.trackRect(forBounds: bounds)
        var center = CGPoint(x: 0, y: 0)
        center.y = floor(frame.height / 2 + progressView.frame.height / 2)
        progressView.center = center
        progressView.frame.origin.x = 2
        progressView.frame.size.width = trackFrame.width - 4
        progressView.autoresizingMask = [.flexibleWidth]
        progressView.clipsToBounds = true
        progressView.layer.cornerRadius = 2
    }
    
    public override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var result = super.trackRect(forBounds: bounds)
        result.size.height = 0.01
        return result
    }

    /// Sets the progress on the progress view.
    ///
    /// - Parameters:
    ///   - progress: A float representing the progress value (0 - 1)
    ///   - animated: A bool indicating whether the new progress value is animated
    public func setProgress(_ progress: Float, animated: Bool) {
        progressView.setProgress(progress, animated: animated)
    }
    
}
