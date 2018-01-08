//
//  DownloadableDelegate.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation

/// <#Description#>
public protocol DownloadableDelegate: class {
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - download: <#download description#>
    ///   - changedState: <#changedState description#>
    func download(_ download: Downloadable, changedState state: DownloadableState)
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - download: <#download description#>
    ///   - completedWithError: <#completedWithError description#>
    func download(_ download: Downloadable, completedWithError error: Error?)
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - download: <#download description#>
    ///   - didReceiveData: <#didReceiveData description#>
    ///   - progress: <#progress description#>
    func download(_ download: Downloadable, didReceiveData data: Data, progress: Float)
}
