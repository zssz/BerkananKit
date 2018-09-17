//
//  Created by Zsombor SZABO on 11/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import CoreBluetooth
import os.log

/// The string representation of the UUID for the control message characteristic.
public let BerkananUUIDControlMessageCharacteristicString = "CDAD54CA-85BF-4F1D-B1EA-A9818B5525FA"

/**
 The characteristic used for control message data.
 
 Data format:
 1. Encode `UInt8` instance to data. See `BerkananControlMessageCharacteristic.ControlMessage` for possible values.
 2. Create JSON-encoded representation of an array with elements:
     - Data from previous step
     - Signature of the SHA-256 digest of the data from previous step using a 256 bit ECC private key with `kSecKeyAlgorithmECDSASignatureDigestX962SHA256` [X9.62] algorithm
 
 - SeeAlso: `DataCodable`
 - SeeAlso: `kSecKeyAlgorithmECDSASignatureDigestX962SHA256`
 */
open class BerkananControlMessageCharacteristic: BerkananMutableCharacteristic {

    /// An inout property used in conjunction with `value`.
    open var controlMessage: ControlMessage?
    
    public init(controlMessage: ControlMessage? = nil, privateKey: SecKey? = nil, publicKey: SecKey? = nil) {
        super.init(type: CBUUID(string: BerkananUUIDControlMessageCharacteristicString), properties: [.write], value: nil, permissions: [.writeable], privateKey: privateKey, publicKey: publicKey)
        self.controlMessage = controlMessage
    }
    
    /**
     Returns data in correct format from parameters.
     
     - Parameter controlMessage: The input control message.
     - Parameter privateKey: The private key used for the signature.
     - Throws: `BerkananError.privateKeyUnavailable` if `privateKey` is `nil`.
     */
    open class func value(from controlMessage: ControlMessage?, privateKey: SecKey?) throws -> Data? {
        guard let controlMessage = controlMessage else {
            return nil
        }
        guard let privateKey = privateKey else {
            throw BerkananError.privateKeyUnavailable
        }
        let pdu = try Berkanan.pdu(from: controlMessage.rawValue.encodedData, useCompression: false, privateKey: privateKey, publicKey: nil)
        return pdu
    }
    
    /**
     Returns a `BerkananControlMessageCharacteristic.ControlMessage` instance from data in correct format.
     
     - Parameter value: The input data.
     - Parameter publicKey: The public key used to verify the signature. If `nil` then verification is skipped.
     - Throws: `BerkananError.invalidData` if data is not in correct format.
     */
    open class func controlMessage(from value: Data?, publicKey: SecKey?) throws -> ControlMessage? {
        guard let value = value else {
            return nil
        }
        let data = try Berkanan.data(from: value, useCompression: false, privateKey: nil, publicKey: publicKey)
        guard let rawValue = UInt8(data: data), let controlMessage = ControlMessage(rawValue: rawValue) else {
            throw BerkananError.invalidData
        }
        return controlMessage
    }

    override open var value: Data? {
        get {
            do {
                let data = try BerkananControlMessageCharacteristic.value(from: controlMessage, privateKey: privateKey)
                return data
            } catch {
                os_log("Get value for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, uuid, error as CVarArg)
                return nil
            }
        }
        set {
            do {
                let newControlMessage = try BerkananControlMessageCharacteristic.controlMessage(from: newValue, publicKey: publicKey)
                self.controlMessage = newControlMessage
            }
            catch {
                os_log("Set value (%{iec-bytes}d) for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, newValue?.count ?? 0, uuid, error as CVarArg)
            }
        }
    }
}

extension BerkananControlMessageCharacteristic {
    
    public enum ControlMessage: UInt8 {
        /// The profile of the sender has been updated.
        case updatedProfile
        
        /// The profile status message of the sender has been updated.
        case updatedProfileStatusMessage
        
        /// The sender is typing to the recipient.
        case typing
        
        /// The sender has finished typing to the recipient.
        case notTyping
        
        /// The sender wants to be hidden.
        case hidden
        
        /// The sender wants to be visible.
        case visible
        
        /// The sender enabled status messages.
        case statusMessageEnabled
        
        /// The sender disabled status messages.
        case statusMessageDisabled
        
        /// The sender answered the call from the recipient.
        case callAnswered
        
        /// The sender ended the call with the recipient.
        case callEnded
    }

}
