//
//  Command.swift
//  MicrobitScratchKit
//
//  Created by Shinichiro Oba on 17/09/2018.
//  Copyright © 2018 bricklife.com. All rights reserved.
//

import Foundation

public struct PinConfig {
}

public enum DisplayCommand {
    case string(String)
    case matrix([Bool])
    case clear
}

public enum Command {
    case pinConfig(PinConfig)
    case display(DisplayCommand)
}

extension Command {
    
    init?(data: Data) {
        guard data.count > 2 else { return nil }
        
        let commandId = data[0]
        let value = data.suffix(from: 1)
        switch commandId {
        case 0x80:
            self = .pinConfig(PinConfig())
            
        case 0x81:
            guard let string = String(data: value, encoding: .utf8) else { return nil }
            self = .display(.string(string))
            
        case 0x82:
            guard value.count == 5 else { return nil }
            var matrix: [Bool] = []
            for row in value {
                for column in 0..<5 {
                    let mask = UInt8(0x01 << column)
                    matrix.append((row & mask) > 0)
                }
            }
            if matrix.contains(true) {
                self = .display(.matrix(matrix))
            } else {
                self = .display(.clear)
            }
            
        default:
            return nil
        }
    }
}
