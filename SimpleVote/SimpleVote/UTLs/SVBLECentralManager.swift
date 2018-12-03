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
    var deviceNames : [String] = []
    
    // vote info
    var voteInfo = [0, 0, 0, 0]
    
    // current vc
    weak var currVC : UIViewController?
    
    // connected devices
    var connectedDevices : [CBPeripheral] = []
    
    // required number of devices
    var requiredDevNum : Int?
    
    // vote result char dict
    var voteResultCharDict : [String : CBCharacteristic] = [:]
    
    // device set
    var deviceSet = Set<CBPeripheral>()
    
    // counter of connected char for each device
    var deviceCharCountDict : [String : Int] = [:]
    
    // number of vote received
    var receiveVotes = 0
    
    // MARK: life cycle
    private override init() {
        super.init()
        self.centralManager.delegate = self
    }
    
    // MARK: interface API
    func scan() {
        self.centralManager.scanForPeripherals(withServices:[self.voteServiceUUID], options: nil)
    }
    
    func isScanning() -> Bool {
        return self.centralManager.isScanning
    }
    
    func setCurrentVote(voteDict : [String : Any]) {
        self.voteDict = voteDict
    }
    
    func connect(_ peripherals : [CBPeripheral]) {
        self.requiredDevNum = peripherals.count
        self.deviceSet = Set()
        self.deviceCharCountDict = [:]
        for peripheral in peripherals {
            self.deviceSet.insert(peripheral)
            self.centralManager.connect(peripheral, options: nil)
        }
    }
    
    func reset() {
        self.disconnectAll()
        self.devicesDict = [:]
        self.deviceNames = []
        self.voteInfo = [0, 0, 0, 0]
        self.currVC = nil
        self.deviceSet = Set()
        self.deviceCharCountDict = [:]
        self.connectedDevices = []
        self.receiveVotes = 0
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
                guard let char = self.voteResultCharDict[peripheral.name!] else {return}
                peripheral.writeValue(resultData!, for: char, type: .withResponse)
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
                guard let char = self.voteResultCharDict[peripheral.name!] else {return}
                peripheral.writeValue(resultData!, for: char, type: .withResponse)
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
    
    private func disconnectAll() {
        for peripheral in self.connectedDevices {
            self.centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    // MARK: CBCentralManager Delegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth: ON")
        } else if central.state == .poweredOff {
            print("Bluetooth: OFF")
        } else {
            print("Bluetooth: UNKNOWN")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let data = advertisementData[CBAdvertisementDataServiceUUIDsKey] {
            print(data)
        }
        guard let name = peripheral.name else {return}
        self.devicesDict[name] = peripheral
        self.deviceNames = Array(devicesDict.keys)
        if let prepVC = self.currVC as? SVVotePrepViewController {
            prepVC.deviceTableView.reloadData()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        peripheral.delegate = self
        peripheral.discoverServices([self.voteServiceUUID])
    }
    
    // MARK: CBPeripheral Delegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {return}
        for service in services {
            if service.uuid == self.voteServiceUUID {
                print("Vote service discovered!")
                peripheral.discoverCharacteristics([self.voteCharUUID, self.voteInfoCharUUID, self.voteResultCharUUID], for:service)
                self.connectedDevices.append(peripheral)
                self.deviceCharCountDict[peripheral.name!] = 0
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else {return}
        for char in chars {
            if char.uuid == self.voteCharUUID {
                peripheral.setNotifyValue(true, for: char)
                print("vote char is ready!")
            }
            if char.uuid == self.voteInfoCharUUID {
                peripheral.setNotifyValue(true, for: char)
                print("voteInfo char is ready!")
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: self.voteDict, requiringSecureCoding: false)
                    peripheral.writeValue(data, for: char, type: .withResponse)
                } catch {
                    print ("voteDict is not sent")
                }
            }
            if char.uuid == self.voteResultCharUUID {
                peripheral.setNotifyValue(true, for: char)
                self.voteResultCharDict[peripheral.name!] = char
                print("voteResult char is ready!")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil {
            if characteristic.uuid == self.voteCharUUID {
                print("Subscribe to vote char successfully!")
                let val = self.deviceCharCountDict[peripheral.name!]
                self.deviceCharCountDict.updateValue(val! + 1, forKey: peripheral.name!)
            }
            if characteristic.uuid == self.voteInfoCharUUID {
                print("Subscribe to voteDict char successfully!")
                let val = self.deviceCharCountDict[peripheral.name!]
                self.deviceCharCountDict.updateValue(val! + 1, forKey: peripheral.name!)
            }
            if characteristic.uuid == self.voteResultCharUUID {
                print("Subscribe to voteResult char successfully!")
                let val = self.deviceCharCountDict[peripheral.name!]
                self.deviceCharCountDict.updateValue(val! + 1, forKey: peripheral.name!)
            }
            if self.deviceCharCountDict[peripheral.name!] == 3 {
                self.deviceSet.remove(peripheral)
            }
            if self.deviceSet.count == 0 {
                self.startVote()
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
