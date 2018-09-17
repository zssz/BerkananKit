//
//  Created by Zsombor SZABO on 10/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import CoreBluetooth
import os.log

/// The string representation of the UUID for the authentication characteristic.
public let BerkananUUIDAuthenticationCharacteristicString = "DE2BAC4E-79AA-408F-8FA6-727582952BCF"

/**
 The characteristic used for authentication data.
 
 Data format:
 1. Encode `UUID` instance to data.
 2. Create JSON-encoded representation of an array with elements:
     - Data from previous step
     - Signature of the SHA-256 digest of the data from previous step using a 256 bit ECC private key with `kSecKeyAlgorithmECDSASignatureDigestX962SHA256` [X9.62] algorithm
 
 - SeeAlso: `DataCodable`
 - SeeAlso: `kSecKeyAlgorithmECDSASignatureDigestX962SHA256`
 */
open class BerkananAuthenticationCharacteristic: BerkananMutableCharacteristic {

    /// An inout property used in conjunction with `value`.
    open var authenticationUUID: UUID?
    
    public init(authenticationUUID: UUID? = nil, privateKey: SecKey? = nil, publicKey: SecKey? = nil) {
        super.init(type: CBUUID(string: BerkananUUIDAuthenticationCharacteristicString), properties: [.write], value: nil, permissions: [.writeable], privateKey: privateKey, publicKey: publicKey)
        self.authenticationUUID = authenticationUUID
    }
    
    /**
     Returns data in correct format from parameters.
     
     - Parameter authenticationUUID: The input uuid.
     - Parameter privateKey: The private key used for the signature.
     - Throws: `BerkananError.privateKeyUnavailable` if `privateKey` is `nil`.
     */
    open class func value(from authenticationUUID: UUID?, privateKey: SecKey?) throws -> Data? {
        guard let authenticationUUID = authenticationUUID else {
            return nil
        }
        guard let privateKey = privateKey else {
            throw BerkananError.privateKeyUnavailable
        }
        let pdu = try Berkanan.pdu(from: authenticationUUID.encodedData, useCompression: false, privateKey: privateKey, publicKey: nil)
        return pdu
    }
    
    /**
     Returns a `UUID` instance from data in correct format.
     
     - Parameter value: The input data.
     - Parameter publicKey: The public key used to verify the signature. If `nil` then verification is skipped.
     - Throws: `BerkananError.invalidData` if data is not in correct format.
     */
    open class func authenticationUUID(from value: Data?, publicKey: SecKey?) throws -> UUID? {
        guard let value = value else {
            return nil
        }
        let data = try Berkanan.data(from: value, useCompression: false, privateKey: nil, publicKey: publicKey)
        guard let uuid = UUID(data: data) else {
            throw BerkananError.invalidData
        }
        return uuid
    }
    
    override open var value: Data? {
        get {
            do {
                let data = try BerkananAuthenticationCharacteristic.value(from: authenticationUUID, privateKey: privateKey)
                return data
            } catch {
                os_log("Get value for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, uuid, error as CVarArg)
                return nil
            }
        }
        set {
            do {
                let newUUID = try BerkananAuthenticationCharacteristic.authenticationUUID(from: newValue, publicKey: publicKey)
                self.authenticationUUID = newUUID
            }
            catch {
                os_log("Set value (%{iec-bytes}d) for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, newValue?.count ?? 0, uuid, error as CVarArg)
            }
        }
    }
        
}
