//
//  Created by Zsombor SZABO on 10/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import CoreBluetooth
import os.log

/// The string representation of the UUID for the profile status message characteristic.
public let BerkananUUIDProfileStatusMessageCharacteristicString = "C39F449D-F211-4919-A322-81B4893550C4"

/**
 The characteristic used for publishing the profile status message data of the user.
 
 Data format:
 1. Encode `String` instance to data using UTF-8 encoding.
 2. Compress data from previous step using zlib algorithm.
 */
open class BerkananProfileStatusMessageCharacteristic: BerkananMutableCharacteristic {
    
    /// An inout property used in conjunction with `value`.
    open var profileStatusMessage: String?
    
    public init(profileStatusMessage: String? = nil) {        
        super.init(type: CBUUID(string: BerkananUUIDProfileStatusMessageCharacteristicString), properties: [.read], value: nil, permissions: [.readable])
        self.profileStatusMessage = profileStatusMessage
    }
    
    /// Returns data in correct format from parameters.
    open class func value(from profileStatusMessage: String?) throws -> Data? {
        guard let profileStatusMessage = profileStatusMessage else {
            return nil
        }
        let pdu = try Berkanan.pdu(from: profileStatusMessage, useCompression: true)
        return pdu
    }
    
    /// Returns a `String` instance from data in correct format.
    ///
    /// - Throws: `BerkananError.invalidData` if data is not in correct format.
    open class func profileStatusMessage(from value: Data?) throws -> String? {
        guard let value = value else {
            return nil
        }
        let profileStatusMessage = try Berkanan.text(from: value, useCompression: true)
        return profileStatusMessage
    }
    
    override open var value: Data? {
        get {
            do {
                let pdu = try BerkananProfileStatusMessageCharacteristic.value(from: profileStatusMessage)
                return pdu
            }
            catch {
                os_log("Get value for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, uuid, error as CVarArg)
                return nil
            }
        }
        set {            
            do {
                let newProfileStatusMessage = try BerkananProfileStatusMessageCharacteristic.profileStatusMessage(from: newValue)
                self.profileStatusMessage = newProfileStatusMessage
            }
            catch {
                os_log("Set value (%{iec-bytes}d) for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, newValue?.count ?? 0, uuid, error as CVarArg)
            }
        }
    }
    
}
