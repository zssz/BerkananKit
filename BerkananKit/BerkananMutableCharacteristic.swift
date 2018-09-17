//
//  Created by Zsombor SZABO on 11/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import CoreBluetooth

/// The maximum length of a characteristic's value in bytes.
public let BerkananMaxAttributeValueLength: Int = 512

open class BerkananMutableCharacteristic: CBMutableCharacteristic {

    /// The private key used to sign or decrypt `value`.
    open var privateKey: SecKey?
    
    /// The public key used to verify the signature or encrypt `value`. If `nil` when verifying then the verification step is skipped.
    open var publicKey: SecKey?
    
    public init(type UUID: CBUUID, properties: CBCharacteristicProperties, value: Data?, permissions: CBAttributePermissions, privateKey: SecKey? = nil, publicKey: SecKey? = nil) {
        super.init(type: UUID, properties: properties, value: value, permissions: permissions)
        self.privateKey = privateKey
        self.publicKey = publicKey
    }

    /// Returns data in correct format based on current state. Updates inout properties when set with data in correct format.
    ///
    /// - Important: The length of the data must not be greater than `BerkananMaxAttributeValueLength`.
    override open var value: Data? {
        get {
            return nil
        }
        set { }
    }

}
