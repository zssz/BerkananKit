//
//  Created by Zsombor SZABO on 11/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import CoreBluetooth
import os.log

/// The string representation of the UUID for the L2CAPPSM characteristic.
public let BerkananUUIDL2CAPPSMCharacteristicString = CBUUIDL2CAPPSMCharacteristicString

/**
 The characteristic used for publishing the L2CAPPSM data of the user.
 
 Data format:
 Encode `UInt16` to data.
 
 - SeeAlso: `DataCodable`
 */
open class BerkananL2CAPPSMCharacteristic: BerkananMutableCharacteristic {

    /// An inout property used in conjunction with `value`.
    open var l2cappsm: CBL2CAPPSM?
    
    public init(l2cappsm: CBL2CAPPSM? = nil) {
        super.init(type: CBUUID(string: BerkananUUIDL2CAPPSMCharacteristicString), properties: [.read], value: nil, permissions: [.readable])
        self.l2cappsm = l2cappsm
    }
    
    /// Returns data in correct format from parameters.
    open class func value(from l2cappsm: CBL2CAPPSM?) -> Data? {
        guard let l2cappsm = l2cappsm else {
            return nil
        }
        let pdu = l2cappsm.encodedData
        return pdu
    }
    
    /// Returns a `CBL2CAPPSM` instance from data in correct format.
    ///
    /// - Throws: `BerkananError.invalidData` if data is not in correct format.
    open class func l2cappsm(from value: Data?) throws -> CBL2CAPPSM? {
        guard let value = value else {
            return nil
        }        
        guard let l2cappsm = CBL2CAPPSM(data: value) else {
            throw BerkananError.invalidData
        }
        return l2cappsm
    }
    
    override open var value: Data? {
        get {
            return BerkananL2CAPPSMCharacteristic.value(from: l2cappsm)
        }
        set {
            do {
                self.l2cappsm = try BerkananL2CAPPSMCharacteristic.l2cappsm(from: newValue)
            }
             catch {
                os_log("Set value (%{iec-bytes}d) for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, newValue?.count ?? 0, uuid, error as CVarArg)
            }
        }
    }
    
}
