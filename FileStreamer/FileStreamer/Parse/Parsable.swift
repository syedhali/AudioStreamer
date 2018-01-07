//
//  Parsable.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation

protocol Parsable: class {
   
    func parse(data: Data)
    
}
