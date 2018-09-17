//
//  Created by Zsombor SZABO on 09/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import Foundation
import CoreBluetooth
import Compression

extension UInt8 : DataCodable { }
extension CBL2CAPPSM : DataCodable { }
extension UUID : DataCodable { }

extension Berkanan {
    
    /**
     Encodes `text` to data using UTF-8 encoding and calls `Berkanan.pdu(from:useCompression:privateKey:publicKey:)`.
     
     - SeeAlso: `Berkanan.pdu(from:useCompression:privateKey:publicKey:)`
     */
    class func pdu(from text: String, useCompression: Bool = true, privateKey: SecKey? = nil, publicKey: SecKey? = nil) throws -> Data {
        guard let data = text.data(using: .utf8) else {
            throw BerkananError.invalidData
        }
        return try pdu(from: data, useCompression: useCompression, privateKey: privateKey, publicKey: publicKey)
    }
    
    /**
     Calls `Berkanan.data(from:useCompression:privateKey:publicKey:)` and decodes the returned data into `String` using UTF-8 encoding.
     
     - SeeAlso: `Berkanan.data(from:useCompression:privateKey:publicKey:)`
     */
    class func text(from pdu: Data, useCompression: Bool = true, privateKey: SecKey? = nil, publicKey: SecKey? = nil) throws -> String {
        let data = try Berkanan.data(from: pdu, useCompression: useCompression, privateKey: privateKey, publicKey: publicKey)
        guard let text = String(data: data, encoding: .utf8) else {
            throw BerkananError.invalidData
        }
        return text
    }
    
    /**
     Returns `data` compressed, signed and encrypted. Each operation is optional and can be toggled with parameters.
     
     - Parameter data: The data to apply the operations.
     - Parameter useCompression: If `true` then the data from previous step is compressed using zlib algorithm.
     - Parameter privateKey: If not `nil` then the data from previous step is signed with `privateKey` using `Berkanan.SignatureAlgorithm` algorithm.
     - Parameter publicKey: If not `nil` then the data from previous step is encrypted with `publicKey` using `Berkanan.EncryptionAlgorithm` algorithm.
     */
    class func pdu(from data: Data, useCompression: Bool = true, privateKey: SecKey? = nil, publicKey: SecKey? = nil) throws -> Data {
        var pdu: Data = data
        
        // Compress if needed
        if useCompression {
            guard let compressedData = pdu.compressed(using: COMPRESSION_ZLIB) else {
                throw BerkananError.invalidData
            }
            pdu = compressedData
        }
        
        // Sign if needed
        if let privateKey = privateKey {
            pdu = try Berkanan.signedData(pdu, privateKey: privateKey)
        }
        
        // Encrypt if needed
        if let publicKey = publicKey {
            pdu = try Berkanan.encryptedData(pdu, publicKey: publicKey)
        }
        
        return pdu
    }
    
    /**
     Returns `data` decrypted, verified and decompressed. Each operation is optional and can be toggled with parameters.
     
     - Parameter pdu: The data to apply the operations.
     - Parameter useCompression: If `true` then the data from previous step is decompressed using zlib algorithm.
     - Parameter privateKey: If not `nil` then the data from previous step is decrypted with `privateKey` using `Berkanan.EncryptionAlgorithm` algorithm.
     - Parameter publicKey: If not `nil` then the data from previous step is verified with `publicKey` using  `Berkanan.SignatureAlgorithm` algorithm.
     */
    class func data(from pdu: Data, useCompression: Bool = true, privateKey: SecKey? = nil, publicKey: SecKey? = nil) throws -> Data {
        var data: Data = pdu
        
        // Decrypt if needed
        if let privateKey = privateKey {
            data = try Berkanan.decryptedData(data, privateKey: privateKey)
        }
        
        // Verify signature if needed
        if let publicKey = publicKey {
            data = try Berkanan.verifiedData(data, publicKey: publicKey)
        }
        else {
            // The data may be signed with `Berkanan.signedData(_:privateKey:)`, or may be not. We do not have a public key to verify its signature if it is.
            do {
                data = try Berkanan.unverifiedData(data)
            }
            catch BerkananError.invalidData {
                // The data *is* signed, however it is invalid. Fail now.
                throw BerkananError.invalidData
            }
            catch is DecodingError {
                // The data *is not* signed. Do not fail.
                // Intentionally left blank
            }
        }
        
        // Decompress if needed
        if useCompression {
            guard let decompressedData = data.decompressed(using: COMPRESSION_ZLIB) else {
                throw BerkananError.invalidData
            }
            data = decompressedData
        }
        
        return data
    }
    
}
