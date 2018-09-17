//
//  Created by Zsombor SZABO on 10/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import CoreBluetooth
import os.log

/// The string representation of the UUID for the profile characteristic.
public let BerkananUUIDProfileCharacteristicString: String = "516CC9DC-7BC4-46BA-9479-F5241E3BD076"

/**
 The characteristic used for publishing the profile data of the user.
 
 Data format:
 1. Create JSON-encoded representation of a dictionary with keys and values:
     - Required `BerkananProfileDictionaryUUIDKey`
     - Optional `BerkananProfileDictionaryNameKey`
     - Optional `BerkananProfileDictionaryAboutKey`
     - Optional `BerkananProfileDictionaryStatusMessageEnabledKey`
     - Optional `BerkananProfileDictionaryHiddenKey`
     - Optional `BerkananProfileDictionaryImageMD5sKey`
 2. Compress data from previous step using zlib algorithm.
 
 Example JSON from step 1:
 
 `"{"m":[],"i":"H2ojD1cHQDaXWLoqYq3ZXg==","n":"John","s":true,"h":false,"a":"Hello, World!"}"`
 */
open class BerkananProfileCharacteristic: BerkananMutableCharacteristic {
    
    /// An inout property used in conjunction with `value`.
    open var profile: Profile?
        
    public init(profile: Profile? = nil) {
        super.init(type: CBUUID(string: BerkananUUIDProfileCharacteristicString), properties: [.read], value: nil, permissions: [.readable])
        self.profile = profile
    }
    
    /// Returns data in correct format from parameters.
    open class func value(from profile: Profile?) throws -> Data? {
        guard let profile = profile else {
            return nil
        }
        let jsonData = try JSONEncoder().encode(profile)
        let pdu = try Berkanan.pdu(from: jsonData, useCompression: true)
        return pdu
    }
    
    /// Returns a `Profile` instance from data in correct format.
    ///
    /// - Throws: `BerkananError.invalidData` if data is not in correct format.
    open class func profile(from value: Data?) throws -> Profile? {
        guard let value = value else {
            return nil
        }
        let jsonData = try Berkanan.data(from: value, useCompression: true)
        let profile = try JSONDecoder().decode(Profile.self, from: jsonData)
        return profile
    }
    
    override open var value: Data? {
        get {
            do {
                let data = try BerkananProfileCharacteristic.value(from: profile)
                return data
            }
            catch {
                os_log("Get value for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, uuid, error as CVarArg)
                return nil
            }
        }
        set {
            do {
                let newProfile = try BerkananProfileCharacteristic.profile(from: newValue)
                self.profile = newProfile
            }
            catch {
                os_log("Set value (%{iec-bytes}d) for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, newValue?.count ?? 0, uuid, error as CVarArg)
            }
        }
    }
        
}

/// A `Data` containing the encoded uuid of the user.
///
/// - SeeAlso: `DataCodable`
public let BerkananProfileDictionaryUUIDKey = "i"

/// A `String` containing the name of the user.
public let BerkananProfileDictionaryNameKey = "n"

/// A `String` containing the about section of the user.
public let BerkananProfileDictionaryAboutKey = "a"

/// A `Bool` containing the status message enabled preference of the user.
public let BerkananProfileDictionaryStatusMessageEnabledKey = "s"

/// A `Bool` containing the hidden preference of the user.
public let BerkananProfileDictionaryHiddenKey = "h"

/// A `[String]` containing the MD5 hashes of the profile images of the user. Maximum 4.
public let BerkananProfileDictionaryImageMD5sKey = "m"

extension BerkananProfileCharacteristic {
    
    public struct Profile: Codable, Equatable {
        public var uuid: UUID
        public var name: String?
        public var isHidden: Bool?
        public var isStatusMessageEnabled: Bool?
        public var about: String?
        public var imageMD5s: [String]?
        
        enum CodingKeys: String, CodingKey {
            case uuid = "i"
            case name = "n"
            case about = "a"
            case isStatusMessageEnabled = "s"
            case isHidden = "h"
            case imageMD5s = "m"
        }
        
        public init(uuid: UUID, name: String? = nil, isHidden: Bool? = nil, isStatusMessageEnabled: Bool? = nil, about: String? = nil, imageMD5s: [String]? = nil) {
            self.uuid = uuid
            self.name = name
            self.isHidden = isHidden
            self.isStatusMessageEnabled = isStatusMessageEnabled
            self.about = about
            self.imageMD5s = imageMD5s
        }
        
        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            
            let uuidData = try values.decode(Data.self, forKey: .uuid)
            guard let uuid = UUID(data: uuidData) else {
                throw BerkananError.invalidData
            }
            self.uuid = uuid
            
            self.name = try values.decodeIfPresent(String.self, forKey: .name)
            self.isHidden = try values.decodeIfPresent(Bool.self, forKey: .isHidden)
            self.isStatusMessageEnabled = try values.decodeIfPresent(Bool.self, forKey: .isStatusMessageEnabled)
            self.about = try values.decodeIfPresent(String.self, forKey: .about)
            self.imageMD5s = try values.decodeIfPresent([String].self, forKey: .imageMD5s)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(uuid.encodedData, forKey: .uuid)
            if let name = name {
                try container.encode(name, forKey: .name)
            }
            if let isHidden = isHidden {
                try container.encode(isHidden, forKey: .isHidden)
            }
            if let isStatusMessageEnabled = isStatusMessageEnabled {
                try container.encode(isStatusMessageEnabled, forKey: .isStatusMessageEnabled)
            }
            if let about = about {
                try container.encode(about, forKey: .about)
            }
            if let imageMD5s = imageMD5s {
                try container.encode(imageMD5s, forKey: .imageMD5s)
            }
        }
    }
    
}
