//
//  SVBLEPeripheralManager.swift
//  SimpleVote
//
//  Created by Luke Gao on 11/23/18.
//  Copyright © 2018 Luke Gao. All rights reserved.
//

import UIKit
import CoreBluetooth

class SVBLEPeripheralManager: NSObject, CBPeripheralManagerDelegate {
    // shared instance
    static let sharedManager = SVBLEPeripheralManager()
    
    // CBPeripheralManager
    private var peripheralManager = CBPeripheralManager()
    
    // vote UUID (this should be agree with all devices)
    private let voteServiceUUID = CBUUID.init(string: "CDD1")
    private let voteCharUUID = CBUUID.init(string: "CDD2")
    private let voteInfoCharUUID = CBUUID.init(string: "CDD3")
    private let voteResultCharUUID = CBUUID.init(string: "CDD4")
    
    // current vote
    var voteDict : [String : Any] = [:]
    
    // vote info
    var voteInfo = [0, 0, 0, 0]
    
    // user's selection
    var selection : Int?
    
    // vote char and services
    var voteChar : CBMutableCharacteristic?
    var dictChar : CBMutableCharacteristic?
    var voteResultChar : CBMutableCharacteristic?
    var voteService : CBMutableService?
    
    // current vc
    weak var currVC : UIViewController?
    
    // central
    var central : CBCentral?
    
    // configured flag
    var isConfigured = false
    
    // MARK: life cycle
    private override init() {
        super.init()
        self.peripheralManager.delegate = self
    }
    
    // MARK: interface API
    func configServiceAndCharacteristic() {
        self.voteChar = CBMutableCharacteristic(type: self.voteCharUUID,
                                                properties:[.read, .notify],
                                                value: nil,
                                                permissions: .readable)
        self.dictChar = CBMutableCharacteristic(type: self.voteInfoCharUUID,
                                                properties: [.read, .write, .notify],
                                                value: nil,
                                                permissions: [.readable,.writeable])
        self.voteResultChar = CBMutableCharacteristic(type: self.voteResultCharUUID,
                                                      properties: [.read, .write, .notify],
                                                      value: nil,
                                                      permissions: [.readable, .writeable])
        self.voteService = CBMutableService(type: self.voteServiceUUID,primary: true)
        voteService!.characteristics = [self.voteChar!, self.dictChar!, self.voteResultChar!]
        self.peripheralManager.add(voteService!)
    }
    
    func sendSelectionInfo(_ selection: Int) {
        self.selection = selection
        let data = Data(bytes: &self.selection, count:16)
        self.peripheralManager.updateValue(data, for: self.voteChar!, onSubscribedCentrals: [self.central!])
        guard self.currVC != nil else {return}
        if self.currVC!.isKind(of: SVVoteViewController.classForCoder()) {
            let vc = SVVoteResultViewController()
            vc.deviceInfo = .peripheral
            self.currVC!.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func reset() {
        self.voteDict = [:]
        self.voteInfo = [0, 0, 0, 0]
        self.selection = nil
        self.currVC = nil
        self.central = nil
        self.isConfigured = false
    }
    
    // MARK: private method
    private func joinVote() {
        guard self.currVC != nil else {return}
        if self.currVC!.isKind(of: SVVoteSearchViewController.classForCoder()) {
            let voteVC = SVVoteViewController.init(withType: .typeVote)
            voteVC.deviceInfo = .peripheral
            self.currVC!.navigationController?.pushViewController(voteVC, animated: true)
        }
    }
    
    private func finishVote() {
        guard self.currVC != nil else {return}
        if let resultVC = self.currVC as? SVVoteResultViewController {
            resultVC.didReceiveResult()
        }
    }
    // MARK: PeripheralManager Delegate
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            print("OK")
            SVBLEPeripheralManager.sharedManager.configServiceAndCharacteristic()
        } else if peripheral.state == .poweredOff {
            let alert = UIAlertController(title: "Bluetooth", message: "Please turn on bluetooth", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Settings", style: .default) { (action) in
                if let url = URL(string: UIApplication.openSettingsURLString){
                    if (UIApplication.shared.canOpenURL(url)){
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (action) in
                self.currVC?.navigationController?.popViewController(animated: true)
            }
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            self.currVC?.present(alert, animated: true, completion: nil)
        } else {
            print("Something went wrong")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        self.central = central
        if characteristic == self.voteChar {
            print("vote char is connected.")
        }
        if characteristic == self.dictChar {
            print("voteInfo char is connected.")
        }
        if characteristic == self.voteResultChar {
            print("voteResult char is connected")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("Add service successfully")
        self.peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:self.voteServiceUUID])
        self.isConfigured = true
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard let vc = self.currVC as! SVVoteSearchViewController? else {return}
        vc.statusLabel.text = "Configured!\nPlease add me in the central device."
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == self.voteInfoCharUUID {
                guard let data = request.value else {return}
                do {
                    let retrievedObj = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
                    guard let dict : [String : Any] = retrievedObj as? [String : Any] else {return}
                    self.voteDict = dict
                } catch {
                    print ("error")
                }
            }
            if request.characteristic.uuid == self.voteResultCharUUID {
                guard let data = request.value else {return}
                do {
                    let retrievedObj = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
                    guard let array : [Int] = retrievedObj as? [Int] else {return}
                    if array == [-1, -1, -1, -1] {
                        self.voteInfo = [0, 0, 0, 0]
                        self.joinVote()
                    } else {
                        self.voteInfo = array
                        self.finishVote()
                    }
                } catch {
                    print("error")
                }
            }
        }
    }
}
