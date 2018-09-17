//
//  Created by Zsombor SZABO on 11/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import CoreBluetooth
import os.log
import Security

/// The string representation of the UUID for the public key characteristic.
public let BerkananUUIDPublicKeyCharacteristicString = "224C5940-2CFE-408B-8E66-7F8CBD5DBF01"

/**
 The characteristic used for publishing the public key data of the user.
 
 Data format:
 Encode 256 bit ECC public key using the ANSI X9.63 standard using a byte string of 04 || X || Y.
 */
open class BerkananPublicKeyCharacteristic: BerkananMutableCharacteristic {

    /// An inout property used in conjunction with `value`.
    open var key: SecKey?
    
    public init(key: SecKey? = nil) {
        super.init(type: CBUUID(string: BerkananUUIDPublicKeyCharacteristicString), properties: [.read], value: nil, permissions: [.readable])
        self.key = key
    }

    /// Returns data in correct format from parameters.
    open class func value(from key: SecKey?) throws -> Data? {
        guard let key = key else {
            return nil
        }
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(key, &error) as Data? else {
            let error = error!.takeRetainedValue() as Error
            throw error
        }
        return data
    }
    
    /// Returns a `SecKey` instance from data in correct format.
    open class func key(from value: Data?) throws -> SecKey? {
        guard let value = value else {
            return nil
        }
        let data = value
        let options: [String : Any] = [
            kSecAttrKeyType as String       : Berkanan.KeyType,
            kSecAttrKeySizeInBits as String : Berkanan.KeySizeInBits,
            kSecAttrKeyClass as String      : kSecAttrKeyClassPublic,
            ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(data as CFData, options as CFDictionary, &error) else {
            let error = error!.takeRetainedValue() as Error
            throw error
        }
        return key
    }
    
    override open var value: Data? {
        get {
            do {
                let data = try BerkananPublicKeyCharacteristic.value(from: key)
                return data
            }
            catch {
                os_log("Get value for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, uuid, error as CVarArg)
                return nil
            }
        }
        set {
            do {
                let newKey = try BerkananPublicKeyCharacteristic.key(from: newValue)
                self.key = newKey
            }
            catch {
                os_log("Set value (%{iec-bytes}d) for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, newValue?.count ?? 0, uuid, error as CVarArg)
            }
        }
    }
 
}
