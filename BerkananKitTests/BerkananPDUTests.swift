//
//  Created by Zsombor SZABO on 05/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import XCTest
@testable import BerkananKit
import CoreBluetooth

class BerkananPDUTests: XCTestCase {
    
    let text: String = "Hello, World!"
    var data: Data {
        return self.text.data(using: .utf8)!
    }
    var privateKey: SecKey! = nil
    var publicKey: SecKey! = nil
    
    override func setUp() {
        super.setUp()
        let keyTag = "Berkanan".data(using: .utf8)!
        if let (privateKey, publicKey) = try? Berkanan.createKeys(privateTag: keyTag, isPrivateKeyPermanent: false) {
            self.privateKey = privateKey
            self.publicKey = publicKey
        }
        XCTAssertNotNil(privateKey)
        XCTAssertNotNil(publicKey)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTextPDU() {
        do {
            let signedEncryptedPDU = try Berkanan.pdu(from: text, privateKey: privateKey, publicKey: publicKey)
            let decryptedVerifiedText = try Berkanan.text(from: signedEncryptedPDU, privateKey: privateKey, publicKey: publicKey)
            XCTAssert(text == decryptedVerifiedText)
            let decryptedUnverifiedText = try Berkanan.text(from: signedEncryptedPDU, privateKey: privateKey, publicKey: nil)
            XCTAssert(text == decryptedUnverifiedText)
            
            let signedPDU = try Berkanan.pdu(from: text, privateKey: privateKey, publicKey: nil)
            let verifiedText = try Berkanan.text(from: signedPDU, privateKey: nil, publicKey: publicKey)
            XCTAssert(text == verifiedText)
            let unverifiedText = try Berkanan.text(from: signedPDU, privateKey: nil, publicKey: nil)
            XCTAssert(text == unverifiedText)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testProfileCharacteristic() {
        let originalData = BerkananProfileCharacteristic.Profile(uuid: UUID(uuidString: "1F6A230F-5707-4036-9758-BA2A62ADD95E")!, name: "John", isHidden: false, isStatusMessageEnabled: true, about: text, imageMD5s: [])
        let characteristic = BerkananProfileCharacteristic(profile: originalData)
        XCTAssert(characteristic.uuid.uuidString == BerkananUUIDProfileCharacteristicString)
        XCTAssert(characteristic.permissions.contains(.readable))
        XCTAssert(characteristic.properties.contains(.read))
        let value = characteristic.value
        XCTAssertNotNil(value)
        XCTAssert(value!.count < BerkananMaxAttributeValueLength)
        characteristic.value = value
        let receivedData = characteristic.profile
        XCTAssert(originalData == receivedData)        
    }
    
    func testProfileStatusMessageCharacteristic() {
        let originalData = text
        let characteristic = BerkananProfileStatusMessageCharacteristic(profileStatusMessage: originalData)
        XCTAssert(characteristic.uuid.uuidString == BerkananUUIDProfileStatusMessageCharacteristicString)
        XCTAssert(characteristic.permissions.contains(.readable))
        XCTAssert(characteristic.properties.contains(.read))
        let value = characteristic.value
        XCTAssertNotNil(value)
        XCTAssert(value!.count < BerkananMaxAttributeValueLength)
        characteristic.value = value
        let receivedData = characteristic.profileStatusMessage
        XCTAssert(originalData == receivedData)
    }

    func testPublicKeyCharacteristic() {
        let originalData: SecKey! = publicKey
        let characteristic = BerkananPublicKeyCharacteristic(key: originalData)
        XCTAssert(characteristic.uuid.uuidString == BerkananUUIDPublicKeyCharacteristicString)
        XCTAssert(characteristic.permissions.contains(.readable))
        XCTAssert(characteristic.properties.contains(.read))
        let value = characteristic.value
        XCTAssertNotNil(value)
        XCTAssert(value!.count < BerkananMaxAttributeValueLength)
        characteristic.value = value
        let receivedData = characteristic.key
        XCTAssert(originalData == receivedData)
    }
    
    func testL2CAPPPSMCharacteristic() {
        let originalData: CBL2CAPPSM = 129
        let characteristic = BerkananL2CAPPSMCharacteristic(l2cappsm: originalData)
        XCTAssert(characteristic.uuid.uuidString == BerkananUUIDL2CAPPSMCharacteristicString)
        XCTAssert(characteristic.permissions.contains(.readable))
        XCTAssert(characteristic.properties.contains(.read))
        let value = characteristic.value
        XCTAssertNotNil(value)
        XCTAssert(value!.count < BerkananMaxAttributeValueLength)
        characteristic.value = value
        let receivedData = characteristic.l2cappsm
        XCTAssert(originalData == receivedData)
    }
    
    func testAuthenticationCharacteristic() {
        let originalData = UUID(uuidString: "1F6A230F-5707-4036-9758-BA2A62ADD95E")!
        let characteristic = BerkananAuthenticationCharacteristic(authenticationUUID: originalData, privateKey: privateKey, publicKey: nil)
        XCTAssert(characteristic.uuid.uuidString == BerkananUUIDAuthenticationCharacteristicString)
        XCTAssert(characteristic.permissions.contains(.writeable))
        XCTAssert(characteristic.properties.contains(.write))
        let value = characteristic.value
        XCTAssertNotNil(value)
        XCTAssert(value!.count < BerkananMaxAttributeValueLength)
        characteristic.value = value
        let receivedData = characteristic.authenticationUUID
        XCTAssert(originalData == receivedData)
        
        characteristic.publicKey = publicKey
        let value2 = characteristic.value
        XCTAssertNotNil(value2)
        characteristic.value = value2
        let verifiedReceivedData = characteristic.authenticationUUID
        XCTAssert(originalData == verifiedReceivedData)
    }
    
    func testControlMessageCharacteristic() {
        let originalData = BerkananControlMessageCharacteristic.ControlMessage.callAnswered
        let characteristic = BerkananControlMessageCharacteristic(controlMessage: originalData, privateKey: privateKey, publicKey: nil)
        XCTAssert(characteristic.uuid.uuidString == BerkananUUIDControlMessageCharacteristicString)
        XCTAssert(characteristic.permissions.contains(.writeable))
        XCTAssert(characteristic.properties.contains(.write))
        let value = characteristic.value
        XCTAssertNotNil(value)
        XCTAssert(value!.count < BerkananMaxAttributeValueLength)
        characteristic.value = value
        let receivedData = characteristic.controlMessage
        XCTAssert(originalData == receivedData)
        
        characteristic.publicKey = publicKey
        let value2 = characteristic.value
        XCTAssertNotNil(value2)
        characteristic.value = value2
        let verifiedReceivedData = characteristic.controlMessage
        XCTAssert(originalData == verifiedReceivedData)
    }
        
    func testEncryptedPrivateMessageCharacteristic() {
        let originalData = text
        let characteristic = BerkananEncryptedPrivateMessageCharacteristic(privateMessage: text, privateKey: privateKey, publicKey: publicKey)
        XCTAssert(characteristic.uuid.uuidString == BerkananUUIDEncryptedPrivateMessageCharacteristicString)
        XCTAssert(characteristic.permissions.contains(.writeable))
        XCTAssert(characteristic.properties.contains(.write))
        let value = characteristic.value        
        XCTAssertNotNil(value)
        XCTAssert(value!.count < BerkananMaxAttributeValueLength)
        characteristic.value = value
        let receivedData = characteristic.privateMessage
        XCTAssert(originalData == receivedData)
        
        characteristic.publicKey = nil
        characteristic.value = value
        let unverifiedReceivedData = characteristic.privateMessage
        XCTAssert(originalData == unverifiedReceivedData)
    }
    
    func testFloodMessageCharacteristicWithHello() {
        let originalData = BerkananFloodMessageCharacteristic.FloodMessage(type: .hello, uuid: UUID(uuidString: "1F6A230F-5707-4036-9758-BA2A62ADD95E")!, sourceUserUUID: UUID(uuidString: "5805B5AA-B550-414F-9492-CEBD12CE3819")!, decodedPayload: "John")
        let characteristic = BerkananFloodMessageCharacteristic(floodMessage: originalData, privateKey: privateKey, publicKey: nil)
        XCTAssert(characteristic.uuid.uuidString == BerkananUUIDFloodMessageCharacteristicString)
        XCTAssert(characteristic.permissions.contains(.writeable))
        XCTAssert(characteristic.properties.contains(.write))
        let value = characteristic.value
        XCTAssertNotNil(value)
        XCTAssert(value!.count < BerkananMaxAttributeValueLength)
        characteristic.value = value
        let receivedData = characteristic.floodMessage
        XCTAssert(originalData == receivedData)
    }
    
    func testFloodMessageCharacteristicWithEncryptedPrivateMessage() {
        let originalData = BerkananFloodMessageCharacteristic.FloodMessage(type: .encryptedPrivateMessage, uuid: UUID(uuidString: "1F6A230F-5707-4036-9758-BA2A62ADD95E")!, sourceUserUUID: UUID(uuidString: "5805B5AA-B550-414F-9492-CEBD12CE3819")!, decodedPayload: "Hello, World! How are you?", destinationUserUUID: UUID(uuidString: "9600F137-5C6C-4EE1-94DA-4A281F2D6E7E")!, privateKey: privateKey, publicKey: publicKey)
        let characteristic = BerkananFloodMessageCharacteristic(floodMessage: originalData, privateKey: privateKey, publicKey: publicKey)
        XCTAssert(characteristic.uuid.uuidString == BerkananUUIDFloodMessageCharacteristicString)
        XCTAssert(characteristic.permissions.contains(.writeable))
        XCTAssert(characteristic.properties.contains(.write))
        let value = characteristic.value
        XCTAssertNotNil(value)
        XCTAssert(value!.count < BerkananMaxAttributeValueLength)
        characteristic.value = value
        let receivedData = characteristic.floodMessage
        XCTAssert(originalData == receivedData)
    }
    
}
