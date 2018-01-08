//
//  Downloadable.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation

///
public protocol Downloadable: class {
    
    // MARK: - Properties
    
    /// <#Description#>
    weak var delegate: DownloadableDelegate? { get set }
    
    /// <#Description#>
    var completionHandler: ((Error?) -> Void)? { get set }
    
    /// <#Description#>
    var progress: Float { get }
    
    /// <#Description#>
    var state: DownloadableState { get }
    
    /// <#Description#>
    var totalBytesReceived: Int64 { get }
    
    /// <#Description#>
    var totalBytesLength: Int64 { get }
    
    /// <#Description#>
    var url: URL? { get }
    
    // MARK: - Methods
    
    /// <#Description#>
    func start()
    
    /// <#Description#>
    func pause()
    
    /// <#Description#>
    func stop()
}
