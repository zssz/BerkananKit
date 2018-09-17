//
//  Created by Zsombor SZABO on 04/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import XCTest
@testable import BerkananKit

class BerkananCryptoTests: XCTestCase {
    
    let data = "Hello, World!".data(using: .utf8)!
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
        super.tearDown()
    }
    
    func testSignature() {
        do {
            let signedData = try Berkanan.signedData(data, privateKey: privateKey)            
            let verifiedData = try Berkanan.verifiedData(signedData, publicKey: publicKey)
            XCTAssert(data == verifiedData)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testNonSignature() {
        do {
            let signedData = try Berkanan.signedData(data, privateKey: privateKey)
            let unverifiedData = try Berkanan.unverifiedData(signedData)
            XCTAssert(data == unverifiedData)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testSignaturesNotEqualForSamePrivateKey() {
        do {
            let signature1 = try Berkanan.signedData(data, privateKey: privateKey)
            let signature2 = try Berkanan.signedData(data, privateKey: privateKey)
            XCTAssert(signature1 != signature2)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testEncryption() {
        do {
            let encryptedData = try Berkanan.encryptedData(data, publicKey: publicKey)
            let decryptedData = try Berkanan.decryptedData(encryptedData, privateKey: privateKey)
            XCTAssert(data == decryptedData)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testEncryptionsNotEqualForSamePublicKey() {
        do {
            let encryptedData1 = try Berkanan.encryptedData(data, publicKey: publicKey)
            let encryptedData2 = try Berkanan.encryptedData(data, publicKey: publicKey)
            XCTAssert(encryptedData1 != encryptedData2)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
