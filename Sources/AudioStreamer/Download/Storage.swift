//
//  File.swift
//  
//
//  Created by Muhammad on 11/02/2023.
//

import Foundation

public protocol Storage {
  func appendDownloadedData(data: Data, _ filePath: String)
  func finalizeDownload(_ filePath: String)
}
