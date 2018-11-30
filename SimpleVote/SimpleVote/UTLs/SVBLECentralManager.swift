//
//  SVBLECentralManager.swift
//  SimpleVote
//
//  Created by Luke Gao on 11/23/18.
//  Copyright © 2018 Luke Gao. All rights reserved.
//

import UIKit
import CoreBluetooth

class SVBLECentralManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // shared instance
    static let sharedManager = SVBLECentralManager()
    
    // CBCentralManager
    private var centralManager = CBCentralManager()
    
    // vote UUID (this should be agree with all devices)
    private let voteServiceUUID = CBUUID.init(string: "CDD1")
    private let voteCharUUID = CBUUID.init(string: "CDD2")
    private let voteInfoCharUUID = CBUUID.init(string: "CDD3")
    private let voteResultCharUUID = CBUUID.init(string: "CDD4")

    // current vote
    var voteDict : [String : Any] = [:]
    
    // current peripheral devices discovered & name array
    var devicesDict : [String : CBPeripheral] = [:]
    @objc dynamic var deviceNames : [String] = []
    
    // vote info
    var voteInfo = [0, 0, 0, 0]
    
    // current vc
    weak var currVC : UIViewController?
    
    // connected devices
    var connectedDevices : [CBPeripheral] = []
    
    // required number of devices
    var requiredDevNum : Int?
    
    // required number of char
    var requiredCharNum = 3
    
    // vote result char
    var voteResultChar : CBCharacteristic?
    
    // unavailable devices
    var unavailableDevices : [CBPeripheral] = []
    
    // number of vote received
    var receiveVotes = 0
    
    // MARK: life cycle
    private override init() {
        super.init()
        self.centralManager.delegate = self
    }
    
    // MARK: interface API
    func isScanning() -> Bool {
        return self.centralManager.isScanning
    }
    
    func setCurrentVote(voteDict : [String : Any]) {
        self.voteDict = voteDict
    }
    
    func connect(_ peripherals : [CBPeripheral]) {
        self.requiredDevNum = peripherals.count
        self.unavailableDevices = []
        for peripheral in peripherals {
            self.centralManager.connect(peripheral, options: nil)
        }
    }
    
    func stopScan() {
        self.centralManager.stopScan()
    }
    
    func boardcastResult() {
        var resultData : Data?
        do {
            resultData = try NSKeyedArchiver.archivedData(withRootObject: self.voteInfo, requiringSecureCoding: false)
        } catch {
            print ("data conversion is not successful")
        }
        if resultData != nil {
            for peripheral in self.connectedDevices {
                peripheral.writeValue(resultData!, for: self.voteResultChar! , type: .withResponse)
            }
        }
    }
    
    // MARK: private method
    private func startVote() {
        var resultData : Data?
        do {
            resultData = try NSKeyedArchiver.archivedData(withRootObject: [-1, -1, -1, -1], requiringSecureCoding: false)
        } catch {
            print ("data conversion is not successful")
        }
        if resultData != nil {
            for peripheral in self.connectedDevices {
                peripheral.writeValue(resultData!, for: self.voteResultChar! , type: .withResponse)
            }
        }
        guard self.currVC != nil else {return}
        if self.currVC!.isKind(of: SVVotePrepViewController.classForCoder()) {
            let voteVC = SVVoteViewController.init(withType: .typeVote)
            voteVC.deviceInfo = .central
            self.currVC!.navigationController?.pushViewController(voteVC, animated: true)
        }
    }
    
    private func finishVote() {
        guard self.currVC != nil else {return}
        if let resultVC = self.currVC as? SVVoteResultViewController {
            resultVC.didFinishVote()
        }
    }
    
    // MARK: CBCentralManager Delegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager.scanForPeripherals(withServices:nil, options: nil)
            print("Bluetooth: ON")
        } else if central.state == .poweredOff {
            print("Bluetooth: OFF")
        } else {
            print("Bluetooth: UNKNOWN")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else {return}
        self.devicesDict[name] = peripheral
        self.deviceNames = Array(devicesDict.keys)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        peripheral.delegate = self
        peripheral.discoverServices([self.voteServiceUUID])
    }
    
    // MARK: CBPeripheral Delegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {return}
        var found = false
        for service in services {
            if service.uuid == self.voteServiceUUID {
                print("Vote service discovered!")
                found = true
                peripheral.discoverCharacteristics([self.voteCharUUID, self.voteInfoCharUUID, self.voteResultCharUUID], for:service)
            }
        }
        if !found {
            self.unavailableDevices.append(peripheral)
            self.centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else {return}
        var count = 0
        for char in chars {
            if char.uuid == self.voteCharUUID {
                peripheral.setNotifyValue(true, for: char)
                peripheral.readValue(for: char)
                print("vote char is ready!")
                count += 1
            }
            if char.uuid == self.voteInfoCharUUID {
                peripheral.setNotifyValue(true, for: char)
                print("voteInfo char is ready!")
                count += 1
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: self.voteDict, requiringSecureCoding: false)
                    peripheral.writeValue(data, for: char, type: .withResponse)
                } catch {
                    print ("voteDict is not sent")
                }
            }
            if char.uuid == self.voteResultCharUUID {
                peripheral.setNotifyValue(true, for: char)
                self.voteResultChar = char
                print("voteResult char is ready!")
                count += 1
            }
        }
        if count < 3 {
            self.unavailableDevices.append(peripheral)
            self.centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil {
            if characteristic.uuid == self.voteCharUUID {
                print("Subscribe to vote char successfully!")
                self.requiredCharNum -= 1
            }
            if characteristic.uuid == self.voteInfoCharUUID {
                print("Subscribe to voteDict char successfully!")
                self.requiredCharNum -= 1
            }
            if characteristic.uuid == self.voteResultCharUUID {
                print("Subscribe to voteResult char successfully!")
                self.requiredCharNum -= 1
            }
            if self.requiredCharNum == 0 {
                self.requiredDevNum? -= 1
                self.connectedDevices.append(peripheral)
            }
            if self.requiredDevNum == 0 {
                self.startVote()
            } else if self.unavailableDevices.count > 0 {
                print("aaaaaa")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == self.voteCharUUID {
            guard let data = characteristic.value else {return}
            let selection = data.withUnsafeBytes {
                (pointer: UnsafePointer<Int16>) -> Int16 in
                return pointer.pointee
            }
            self.voteInfo[Int(selection)] += 1
            self.receiveVotes += 1
            if self.receiveVotes == self.connectedDevices.count {
                self.finishVote()
            }
        }
    }
}
