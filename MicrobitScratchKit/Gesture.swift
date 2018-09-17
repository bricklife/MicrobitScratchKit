//
//  Gesture.swift
//  MicrobitScratchKit
//
//  Created by Shinichiro Oba on 17/09/2018.
//  Copyright © 2018 bricklife.com. All rights reserved.
//

import Foundation

public struct Gesture: OptionSet {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    public static let shaken    = Gesture(rawValue: 1 << 0)
    public static let jumped    = Gesture(rawValue: 1 << 1)
    public static let moved     = Gesture(rawValue: 1 << 2)
}
