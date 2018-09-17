//
//  Created by Zsombor SZABO on 09/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import Foundation
import CoreBluetooth
import os.log

/// The string representation of the UUID for the primary peripheral service.
public let BerkananUUIDPeripheralServiceString = "01F42344-3A62-4FAA-98C8-8B430DBEB9BA"

/// The string representations of the UUIDs for the profile image characteristics.
/// The technique used for retrieving the data is the [subscription-notify method](https://developer.apple.com/library/content/samplecode/BTLE_Transfer/). In short: Send JPEG data in chunks to subscribed peripheral. When finished, send `"EOM"` encoded using UTF-8 encoding. If multiple peripherals are subscribed at the same time then use queueing.
public let BerkananUUIDProfileImageCharacteristicStrings = [
    "B0AA71B5-CFCF-4EF2-9B79-B650A4C9427C",
    "615E3727-9DA8-484D-9EC9-72DEBFCB42FE",
    "E9651ED0-95AF-4828-9F9F-6AC51FF3F6CD",
    "BB0B2245-BDDE-44C7-A163-8A4C83CFD4EB",
]

open class Berkanan {
    
    public static let shared = Berkanan()
    
    public static let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Berkanan")
    
    // MARK: - Bluetooth
    
    public lazy var peripheralService: CBMutableService = {
        let service = CBMutableService(type: CBUUID(string: BerkananUUIDPeripheralServiceString), primary: true)
        var characteristics: [CBMutableCharacteristic] = [
            profileCharacteristic,
            profileStatusMessageCharacteristic,
            publicKeyCharacteristic,
            l2cappsmCharacteristic,
            authenticationCharacteristic,
            controlMessageCharacteristic,
            encryptedPrivateMessageCharacteristic,
            floodMessageCharacteristic,
            ]
        characteristics.append(contentsOf: self.profileImageCharacteristics)
        service.characteristics = characteristics
        return service
    }()
    
    public lazy var profileCharacteristic = BerkananProfileCharacteristic()
    
    public lazy var profileStatusMessageCharacteristic = BerkananProfileStatusMessageCharacteristic()
    
    public lazy var profileImageCharacteristics: [CBMutableCharacteristic] = {
        let characteristics = BerkananUUIDProfileImageCharacteristicStrings.map({ CBMutableCharacteristic(type: CBUUID(string: $0), properties: [.notify], value: nil, permissions: [.readable]) })
        return characteristics
    }()
    
    public lazy var publicKeyCharacteristic = BerkananPublicKeyCharacteristic()
    
    public lazy var l2cappsmCharacteristic = BerkananL2CAPPSMCharacteristic()
    
    public lazy var authenticationCharacteristic = BerkananAuthenticationCharacteristic()
    
    public lazy var controlMessageCharacteristic = BerkananControlMessageCharacteristic()
    
    public lazy var encryptedPrivateMessageCharacteristic = BerkananEncryptedPrivateMessageCharacteristic()
    
    public lazy var floodMessageCharacteristic = BerkananFloodMessageCharacteristic()

}
