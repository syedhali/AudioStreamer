//
//  ParserError.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation

/// Possible errors that can result from the `Parser` class.
///
/// - streamCouldNotOpen: The file stream could not be opened. This will only occur if the underlying `AudioFileStreamOpen` method fails.
public enum ParserError: Error {
    case streamCouldNotOpen
}
