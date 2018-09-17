//
//  Microbit.swift
//  MicrobitScratchKit
//
//  Created by Shinichiro Oba on 17/09/2018.
//  Copyright © 2018 bricklife.com. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol MicrobitDelegate: class {
    func microbit(_ microbit: Microbit, didReceiveDisplayCommand displayCommand: DisplayCommand)
}

public class Microbit: NSObject {
    
    public weak var delegate: MicrobitDelegate?
    
    public let serviceUUID = CBUUID(string: "f005")
    public let rxUUID = CBUUID(string: "5261da01-fa7e-42ab-850b-7c80220097cc")
    public let txUUID = CBUUID(string: "5261da02-fa7e-42ab-850b-7c80220097cc")
    
    private var peripheralManager: CBPeripheralManager?
    private var characteristic: CBMutableCharacteristic?
    
    private var tilt: (x: Int16, y: Int16) = (0, 0)
    private var pressing: [Button: Bool] = [:]
    private var connecting: [UInt: Bool] = [:]
    private var gesture: Gesture = []
    
    private var timer: Timer?
    
    public override init() {
        super.init()
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    public func startAdvertising() {
        peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
    }
    
    public func stopAdvertising() {
        peripheralManager?.stopAdvertising()
    }
    
    public var isAdvertising: Bool {
        return peripheralManager?.isAdvertising ?? false
    }
    
    private func addService() {
        peripheralManager?.removeAllServices()
        
        let service = CBMutableService(type: serviceUUID, primary: true)
        
        let rx = CBMutableCharacteristic(type: rxUUID, properties: [.read, .notify], value: nil, permissions: [.readable])
        let tx = CBMutableCharacteristic(type: txUUID, properties: [.write, .writeWithoutResponse], value: nil, permissions: [.writeable])
        
        service.characteristics = [rx, tx]
        
        peripheralManager?.add(service)
        
        self.characteristic = rx
    }
    
    public func setTilt(x: Int? = nil, y: Int? = nil) {
        if let x = x, abs(x) <= 180 { self.tilt.x = Int16(x) }
        if let y = y, abs(y) <= 180  { self.tilt.y = Int16(y) }
        notify()
    }
    
    public func set(button: Button, pressing: Bool) {
        self.pressing[button] = pressing
        notify()
    }
    
    public func set(pin: Int, connecting: Bool) {
        guard pin >= 0 && pin <= 2 else { return }
        self.connecting[UInt(pin)] = connecting
        notify()
    }
    
    public func set(gesture: Gesture) {
        self.gesture = gesture
        notify()
    }
    
    private func createNotificationData() -> Data {
        let tiltX = UInt16(bitPattern: tilt.x)
        let tiltY = UInt16(bitPattern: tilt.y)
        
        return Data(bytes: [UInt8(tiltX >> 8), UInt8(tiltX & 0xff),
                            UInt8(tiltY >> 8), UInt8(tiltY & 0xff),
                            pressing[.A]  == true ? 0x01 : 0x00,
                            pressing[.B]  == true ? 0x01 : 0x00,
                            connecting[0] == true ? 0x01 : 0x00,
                            connecting[1] == true ? 0x01 : 0x00,
                            connecting[2] == true ? 0x01 : 0x00,
                            gesture.rawValue,
                            ])
    }
    
    private func notify() {
        guard let characteristic = characteristic else { return }
        
        let data = createNotificationData()
        peripheralManager?.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
    }
}

extension Microbit: CBPeripheralManagerDelegate {
    
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            addService()
            startAdvertising()
        default:
            stopAdvertising()
        }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard request.characteristic.uuid == rxUUID else {
            peripheral.respond(to: request, withResult: .requestNotSupported)
            return
        }
        
        request.value = createNotificationData()
        peripheral.respond(to: request, withResult: .success)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        guard let firstRequest = requests.first else { return }
        
        for request in requests {
            guard request.characteristic.uuid == txUUID else {
                peripheral.respond(to: firstRequest, withResult: .requestNotSupported)
                return
            }
            
            if let data = request.value, let command = Command(data: data) {
                switch command {
                case .pinConfig:
                    break
                case .display(let displayCommand):
                    delegate?.microbit(self, didReceiveDisplayCommand: displayCommand)
                }
            }
        }
        
        peripheral.respond(to: firstRequest, withResult: .success)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (_) in
            self?.notify()
        })
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        timer?.invalidate()
    }
}
