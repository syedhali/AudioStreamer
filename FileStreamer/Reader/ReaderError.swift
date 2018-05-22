//
//  ReaderError.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation

public enum ReaderError: Error {
    case converterFailed(OSStatus,String)
    case failedToCreateDestinationFormat
    case parserMissingDataFormat
    case unableToCreateConverter(OSStatus)
}
