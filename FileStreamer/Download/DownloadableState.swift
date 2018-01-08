//
//  DownloadableState.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation

/// <#Description#>
///
/// - completed: <#completed description#>
/// - started: <#started description#>
/// - paused: <#paused description#>
/// - notStarted: <#notStarted description#>
/// - stopped: <#stopped description#>
public enum DownloadableState: String {
    case completed
    case started
    case paused
    case notStarted
    case stopped
}
