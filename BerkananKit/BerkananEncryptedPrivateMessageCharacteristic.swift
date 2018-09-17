//
//  Created by Zsombor SZABO on 11/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import CoreBluetooth
import os.log

/// The string representation of the UUID for the encrypted private message characteristic.
public let BerkananUUIDEncryptedPrivateMessageCharacteristicString = "EA0B7E26-1CFE-4A3B-90DD-C49C0DEC2240"

/**
 The characteristic used for encrypted private message data.
 
 Data format:
 1. Encode `String` instance to data using UTF-8 encoding.
 2. Compress data from previous step using zlib algorithm.
 3. Create JSON-encoded representation of an array with elements:
     - Data from previous step
     - Signature of the SHA-256 digest of the data from previous step using a 256 bit ECC private key with `kSecKeyAlgorithmECDSASignatureDigestX962SHA256` [X9.62] algorithm
 4. Encrypt data from previous step using a 256 bit ECC public key with `kSecKeyAlgorithmECIESEncryptionStandardVariableIVX963SHA256AESGCM` [X9.63] algorithm.
 
 - SeeAlso: `kSecKeyAlgorithmECDSASignatureDigestX962SHA256`
 - SeeAlso: `kSecKeyAlgorithmECIESEncryptionStandardVariableIVX963SHA256AESGCM`
 */
open class BerkananEncryptedPrivateMessageCharacteristic: BerkananMutableCharacteristic {
    
    /// An inout property used in conjunction with `value`.
    open var privateMessage: String?
    
    public init(privateMessage: String? = nil, privateKey: SecKey? = nil, publicKey: SecKey? = nil) {
        super.init(type: CBUUID(string: BerkananUUIDEncryptedPrivateMessageCharacteristicString), properties: [.write], value: nil, permissions: [.writeable], privateKey: privateKey, publicKey: publicKey)
        self.privateMessage = privateMessage
    }
    
    /**
     Returns data in correct format from parameters.
     
     - Parameter privateMessage: The input private message.
     - Parameter privateKey: The private key used for the signature.
     - Parameter publicKey: The publicKey key used for the encryption.
     - Throws: `BerkananError.privateKeyUnavailable` if `privateKey` is `nil`. `BerkananError.publicKeyUnavailable` if `publicKey` is `nil`.
     */
    open class func value(from privateMessage: String?, privateKey: SecKey?, publicKey: SecKey?) throws -> Data? {
        guard let privateMessage = privateMessage else {
            return nil
        }
        guard let privateKey = privateKey else {
            throw BerkananError.privateKeyUnavailable
        }
        guard let publicKey = publicKey else {
            throw BerkananError.publicKeyUnavailable
        }
        let pdu = try Berkanan.pdu(from: privateMessage, useCompression: true, privateKey: privateKey, publicKey: publicKey)
        return pdu
    }
    
    /**
     Returns a `String` instance from data in correct format.
     
     - Parameter value: The input data.
     - Parameter privateKey: The private key used to decrypt the data.
     - Parameter publicKey: The public key used to verify the signature. If `nil` then verification is skipped.
     - Throws: `BerkananError.privateKeyUnavailable` if `privateKey` is `nil`. `BerkananError.invalidData` if data is not in correct format.
     */
    open class func privateMessage(from value: Data?, privateKey: SecKey?, publicKey: SecKey?) throws -> String? {
        guard let value = value else {
            return nil
        }
        guard let privateKey = privateKey else {
            throw BerkananError.privateKeyUnavailable
        }
        let privateMessage = try Berkanan.text(from: value, useCompression: true, privateKey: privateKey, publicKey: publicKey)
        return privateMessage
    }
    
    override open var value: Data? {
        get {
            do {
                let pdu = try BerkananEncryptedPrivateMessageCharacteristic.value(from: privateMessage, privateKey: privateKey, publicKey: publicKey)
                return pdu
            } catch {
                os_log("Get value for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, uuid, error as CVarArg)
                return nil
            }
        }
        set {
            do {
                let newPrivateMessage = try BerkananEncryptedPrivateMessageCharacteristic.privateMessage(from: newValue, privateKey: privateKey, publicKey: publicKey)
                self.privateMessage = newPrivateMessage
            }
            catch {
                os_log("Set value (%{iec-bytes}d) for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, newValue?.count ?? 0, uuid, error as CVarArg)
            }
        }
    }
    
}
