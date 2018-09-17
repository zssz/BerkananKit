//
//  Created by Zsombor SZABO on 11/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import CoreBluetooth
import os.log

/// The string representation of the UUID for the flood message characteristic.
public let BerkananUUIDFloodMessageCharacteristicString = "C3B20DF8-2E1B-49E8-BBB2-596CF39C2718"

/**
 The characteristic used for flood message data.
 
 Data format:
 1. Create JSON-encoded representation of a dictionary with keys and values:
     - Required `BerkananFloodMessageDictionaryTypeKey`
     - Required `BerkananFloodMessageDictionaryUUIDKey`
     - Required `BerkananFloodMessageDictionarySourceUserUUIDKey`
     - Optional `BerkananFloodMessageDictionaryPayloadKey`
     - Optional `BerkananFloodMessageDictionaryDestinationUserUUIDKey`. Note: Required if value for `BerkananFloodMessageDictionaryTypeKey` is `.encryptedPrivateMessage` or `.encryptedPrivateMessageAck`.
 2. Compress data from previous step using zlib algorithm.
 3. Create JSON-encoded representation of an array with elements:
     - Data from previous step
     - Signature of the SHA-256 digest of the data from previous step using a 256 bit ECC private key with `kSecKeyAlgorithmECDSASignatureDigestX962SHA256` [X9.62] algorithm
 
 Example JSON from step 1:
 
 `"{"i":"H2ojD1cHQDaXWLoqYq3ZXg==","p":"Sm9obg==","s":"WAW1qrVQQU+Uks69Es44GQ==","t":0}"`
 
 `"{"d":"lgDxN1xsTuGU2kooHy1ufg==","i":"H2ojD1cHQDaXWLoqYq3ZXg==","p":"BLjNn70m+Nb\/vym3RVjqNokjlXp9Gqv76fIef8C5uliXNKkvfBfvBk1w1WNt7aqwiT0G8WxVJmK+gQD30guiPaAw3h8HJnVFQ4GlgFxd1VqtsMT2USmdFErog1g6k0L6fm0WJB05SQGNOtn9OtZ9FQMGehVGnarCOMZnllrvdG73jjWAehNOHgfe9Zrj","s":"WAW1qrVQQU+Uks69Es44GQ==","t":3}"`

 - SeeAlso: `kSecKeyAlgorithmECDSASignatureDigestX962SHA256`
 */
open class BerkananFloodMessageCharacteristic: BerkananMutableCharacteristic {

    /// An inout property used in conjunction with `value`.
    open var floodMessage: FloodMessage?
    
    public init(floodMessage: FloodMessage? = nil, privateKey: SecKey? = nil, publicKey: SecKey? = nil) {
        super.init(type: CBUUID(string: BerkananUUIDFloodMessageCharacteristicString), properties: [.write], value: nil, permissions: [.writeable], privateKey: privateKey, publicKey: publicKey)
        self.floodMessage = floodMessage
    }
    
    /**
     Returns data in correct format from parameters.
     
     - Parameter floodMessage: The input flood message.
     - Parameter privateKey: The private key used for the signature.
     - Throws: `BerkananError.privateKeyUnavailable` if `privateKey` is `nil`.
     */
    open class func value(from floodMessage: FloodMessage?, privateKey: SecKey?) throws -> Data? {
        guard let floodMessage = floodMessage else {
            return nil
        }
        guard let privateKey = privateKey else {
            throw BerkananError.privateKeyUnavailable
        }
        let jsonData = try JSONEncoder().encode(floodMessage)
        let pdu = try Berkanan.pdu(from: jsonData, useCompression: true, privateKey: privateKey, publicKey: nil)
        return pdu
    }
    
    /**
     Returns a `FloodMessage` instance from data in correct format.
     
     - Parameter value: The input data.
     - Parameter privateKey: The private key used to decrypt the data if the flood message type is `.encryptedPrivateMessage`. Fails silently by setting `decodedPayload` to `nil` if `privateKey` is `nil`.
     - Parameter publicKey: The public key used to verify the signature. If `nil` then verification is skipped.
     - Throws: `BerkananError.invalidData` if data is not in correct format.
     */
    open class func floodMessage(from value: Data?, privateKey: SecKey?, publicKey: SecKey?) throws -> FloodMessage? {
        guard let value = value else {
            return nil
        }
        let jsonData = try Berkanan.data(from: value, useCompression: true, privateKey: nil, publicKey: publicKey)
        var floodMessage = try JSONDecoder().decode(FloodMessage.self, from: jsonData)
        if floodMessage.type == .encryptedPrivateMessage {
            floodMessage.privateKey = privateKey
            floodMessage.publicKey = publicKey
            if privateKey != nil {
                floodMessage.decodeEncrytedPrivateMessagePayload()
            }
        }
        floodMessage.encodedPayload = nil
        return floodMessage
    }
    
    override open var value: Data? {
        get {
            do {
                let pdu = try BerkananFloodMessageCharacteristic.value(from: floodMessage, privateKey: privateKey)
                return pdu
            }
            catch {
                os_log("Get value for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, uuid, error as CVarArg)
                return nil
            }
        }
        set {
            do {
                let newFloodMessage = try BerkananFloodMessageCharacteristic.floodMessage(from: newValue, privateKey: privateKey, publicKey: publicKey)
                self.floodMessage = newFloodMessage
            }
            catch {
                os_log("Set value (%{iec-bytes}d) for characteristic (%@) failed: %@", log: Berkanan.log, type: .error, newValue?.count ?? 0, uuid, error as CVarArg)
            }
        }
    }
    
}

/// A `UInt8` containing the type of the flood message. See `BerkananFloodMessageCharacteristic.FloodMessageType` for possible values.
public let BerkananFloodMessageDictionaryTypeKey = "t"

/// A `Data` containing the encoded uuid of the flood message.
public let BerkananFloodMessageDictionaryUUIDKey = "i"

/// A `Data` containing the encoded uuid of the source user.
public let BerkananFloodMessageDictionarySourceUserUUIDKey = "s"

/// A `Data` containing the payload of the flood message.
public let BerkananFloodMessageDictionaryPayloadKey = "p"

/// A `Data` containing the encoded uuid of the destination user.
public let BerkananFloodMessageDictionaryDestinationUserUUIDKey = "d"

extension BerkananFloodMessageCharacteristic {
    
    public struct FloodMessage: Codable, Equatable {
        public var type: FloodMessageType
        public var uuid: UUID
        public var sourceUserUUID: UUID
        public var destinationUserUUID: UUID?
        public var decodedPayload: AnyHashable?
        /// The public key used to encrypt the payload data when the flood message type is `.encryptedPrivateMessage`
        public var publicKey: SecKey?
        /// The private key used to decrypt the payload data when the flood message type is `.encryptedPrivateMessage`
        public var privateKey: SecKey?
        
        var encodedPayload: Data?
        
        var payload: Data? {
            get {
                guard let decodedPayload = decodedPayload else {
                    return nil
                }
                do {
                    switch type {
                    case .hello, .publicMessage:
                        guard let decodedPayload = decodedPayload as? String else {
                            throw BerkananError.invalidData
                        }
                        guard let data = decodedPayload.data(using: .utf8) else {
                            throw BerkananError.invalidData
                        }
                        return data
                    case .encryptedPrivateMessage:
                        guard let decodedPayload = decodedPayload as? String else {
                            throw BerkananError.invalidData
                        }
                        guard let publicKey = publicKey else {
                            throw BerkananError.publicKeyUnavailable
                        }
                        let data = try Berkanan.pdu(from: decodedPayload, useCompression: true, privateKey: nil, publicKey: publicKey)
                        return data
                    case .encryptedPrivateMessageAck:
                        guard let decodedPayload = decodedPayload as? UUID else {
                            throw BerkananError.invalidData
                        }
                        return decodedPayload.encodedData
                    }
                }
                catch {
                    os_log("Get flood message payload failed: %@", type: .info, error as CVarArg)
                    return nil
                }
            }
            set {
                self.encodedPayload = newValue
                guard let newValue = newValue else {
                    return
                }
                do {
                    switch type {
                    case .hello, .publicMessage:
                        guard let text = String(data: newValue, encoding: .utf8) else {
                            throw BerkananError.invalidData
                        }
                        self.decodedPayload = text
                    case .encryptedPrivateMessage:
                        // Intentionally left blank. Use `decodeEncrytedPrivateMessagePayload
                        break
                    case .encryptedPrivateMessageAck:
                        guard let uuid = UUID(data: newValue) else {
                            throw BerkananError.invalidData
                        }
                        self.decodedPayload = uuid
                    }
                }
                catch {
                    os_log("Set flood message payload failed: %@", type: .info, newValue.count, error as CVarArg)
                }
            }
        }
        
        /// - Parameter `privatekey: The private key used to decrypt the payload data when the flood message type is `FloodMessageType.encryptedPrivateMessage`
        mutating func decodeEncrytedPrivateMessagePayload() {
            guard let payload = encodedPayload else {
                return
            }
            if type == .encryptedPrivateMessage {
                do {
                    let text = try Berkanan.text(from: payload, useCompression: true, privateKey: privateKey, publicKey: nil)
                    self.decodedPayload = text
                } catch {
                    os_log("Set flood message decoded payload failed: %@", type: .error, error as CVarArg)
                }
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case type = "t"
            case uuid = "i"
            case sourceUserUUID = "s"
            case payload = "p"
            case destinationUserUUID = "d"
        }
        
        public init(type: FloodMessageType, uuid: UUID, sourceUserUUID: UUID, decodedPayload: AnyHashable? = nil, destinationUserUUID: UUID? = nil, privateKey: SecKey? = nil, publicKey: SecKey? = nil) {
            self.type = type
            self.uuid = uuid
            self.sourceUserUUID = sourceUserUUID
            self.decodedPayload = decodedPayload
            self.destinationUserUUID = destinationUserUUID
            self.privateKey = privateKey
            self.publicKey = publicKey
        }
        
        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            
            self.type = try values.decode(FloodMessageType.self, forKey: .type)
            
            let uuidData = try values.decode(Data.self, forKey: .uuid)
            guard let uuid = UUID(data: uuidData) else {
                throw BerkananError.invalidData
            }
            self.uuid = uuid
            
            let sourceUserUUIDData = try values.decode(Data.self, forKey: .sourceUserUUID)
            guard let sourceUserUUID = UUID(data: sourceUserUUIDData) else {
                throw BerkananError.invalidData
            }
            self.sourceUserUUID = sourceUserUUID

            self.payload = try values.decodeIfPresent(Data.self, forKey: .payload)
            
            if let destinationUserUUIDData = try values.decodeIfPresent(Data.self, forKey: .destinationUserUUID) {
                guard let destinationUserUUID = UUID(data: destinationUserUUIDData) else {
                    throw BerkananError.invalidData
                }
                self.destinationUserUUID = destinationUserUUID
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encode(uuid.encodedData, forKey: .uuid)
            try container.encode(sourceUserUUID.encodedData, forKey: .sourceUserUUID)
            if let data = payload {
                try container.encode(data, forKey: .payload)
            }
            if let destinationUserUUID = destinationUserUUID {
                try container.encode(destinationUserUUID.encodedData, forKey: .destinationUserUUID)
            }
        }
        
    }
    
    public enum FloodMessageType: UInt8, Codable {
        /**
         Broadcast message used for network topology discovery. `BerkananFloodMessageDictionaryPayloadKey` can contain the profile name of the source user. Its data format is a `String` instance encoded to data using UTF-8 encoding.
         */
        case hello
        
        /**
         Public message for all users. `BerkananFloodMessageDictionaryPayloadKey` must contain the public message data. Its data format is a `String` instance encoded to data using UTF-8 encoding.
         */
        case publicMessage
        
        /**
         Encrypted private message for the destination user. `BerkananFloodMessageDictionaryPayloadKey` must contain the private message data for the destination user.
         
         Data format:
         1. Encode `String` instance to data using UTF-8 encoding.
         2. Compress data from previous step using zlib algorithm.
         3. Encrypt data from previous step using the a 256 bit ECC public key with `kSecKeyAlgorithmECIESEncryptionStandardVariableIVX963SHA256AESGCM` [X9.63] algorithm.
         
         - SeeAlso: `kSecKeyAlgorithmECIESEncryptionStandardVariableIVX963SHA256AESGCM`
         */
        case encryptedPrivateMessage
        
        /**
         Ack for a previously sent flood message with `.encryptedPrivateMessage` type. `BerkananFloodMessageDictionaryPayloadKey` must contain the UUID data of the previously sent private message. Its data format is a `UUID` instance encoded to data.
         */
        case encryptedPrivateMessageAck
    }
}
