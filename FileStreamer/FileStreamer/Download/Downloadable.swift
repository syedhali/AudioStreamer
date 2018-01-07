//
//  Downloadable.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation

protocol Downloadable: class {
    
    weak var delegate: DownloadableDelegate? { get set }
    
    var completionHandler: ((Error?) -> Void)? { get set }
    
    var data: Data { get }
    
    var progress: Float { get }
    
    var state: DownloadableState { get }
    
    var totalBytesReceived: Int64 { get }
    
    var totalBytesLength: Int64 { get }
    
    var url: URL { get }
    
    func start()
    
    func pause()
    
    func stop()
    
    init(url: URL)
}
