//
//  DownloadableDelegate.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation

protocol DownloadableDelegate: class {
    
    func download(_ download: Downloadable, completedWithError: Error?)
    
    func download(_ download: Downloadable, didReceiveData: Data, progress: Float)
    
}
