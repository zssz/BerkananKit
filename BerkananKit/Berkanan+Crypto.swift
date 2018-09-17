//
//  Created by Zsombor SZABO on 09/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import Foundation
import Security

extension Berkanan {
    
    /// The size of the key in bits.
    /// - Note: Using a larger key size, like 521 bit, produces messages larger than 512 bytes.
    public static let KeySizeInBits: Int = 256
    
    /// The type of the key used for cryptographic operations.
    public static let KeyType: CFString = kSecAttrKeyTypeECSECPrimeRandom
    
    /// The signature algorithm used.
    public static let SignatureAlgorithm: SecKeyAlgorithm = .ecdsaSignatureDigestX962SHA256
    
    /// The encryption algorithm used.
    public static let EncryptionAlgorithm: SecKeyAlgorithm = .eciesEncryptionStandardVariableIVX963SHA256AESGCM
    
    /**
     Returns a private and public key pair to be used for cryptographic operations.
     
     - Parameter privateTag: The value used for `kSecAttrApplicationTag`.
     - Parameter accessGroup: The value used for `kSecAttrAccessGroup`.
     - Parameter isPrivateKeyPermanent: If `true` then the created private key is stored in the Keychain.
     */
    open class func createKeys(privateTag: Data? = nil, accessGroup: String? = nil, isPrivateKeyPermanent: Bool = true) throws -> (SecKey, SecKey) {
        var privateKeyAttributes: [String : Any] = [
            kSecAttrApplicationTag as String:   privateTag as Any,
            kSecAttrIsPermanent as String:      isPrivateKeyPermanent ? true : false,
            kSecAttrAccessible as String:       isPrivateKeyPermanent ? kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String : kSecAttrAccessibleAlways as String,
        ]
        if let accessGroup = accessGroup {
            privateKeyAttributes[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let attributes: [String : Any] = [
            kSecAttrKeyType as String:          Berkanan.KeyType,
            kSecAttrKeySizeInBits as String:    Berkanan.KeySizeInBits,
            kSecPrivateKeyAttrs as String:      privateKeyAttributes
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            let error = error!.takeRetainedValue() as Error
            throw error
        }
        
        guard let publickKey = SecKeyCopyPublicKey(privateKey) else {
            throw BerkananError.publicKeyUnavailable
        }
        
        return (privateKey, publickKey)
    }
    
    /**
     Returns the JSON-encoded representation of a `[Data]` with elements:
     - `data`
     - Signature of the SHA-256 digest of `data` using `Berkanan.SignatureAlgorithm` algorithm.
     
     - Parameter data: The data to sign.
     - Parameter privateKey: The private key used to sign.
     */
    public class func signedData(_ data: Data, privateKey: SecKey) throws -> Data {
        let algorithm = Berkanan.SignatureAlgorithm
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(privateKey, algorithm, (data as NSData).sha256Digest() as CFData, &error) as Data? else {
            let error = error!.takeRetainedValue() as Error
            throw error
        }
        
        let jsonData = try JSONEncoder().encode([data, signature])
        
        return jsonData
    }
    
    /**
     Decodes a JSON object into `[Data]` and returns its 1st element.
     
     - Parameter data: The JSON-encoded representation of a `[Data]`, created with `signedData(_:privateKey:)`.
     */
    class func unverifiedData(_ data: Data) throws -> Data {
        let serialization = try JSONDecoder().decode([Data].self, from: data)
        guard serialization.count == 2, let data = serialization.first else {
            throw BerkananError.invalidData
        }
        
        return data
    }
    
    /**
     Decodes a JSON object into `[Data]` and returns its 1st element. It also verifies the signature of the SHA-256 digest of the 1st element using `Berkanan.SignatureAlgorithm` with the 2nd element.
     
     - Parameter data: The JSON data created with `signedData(_:privateKey:)`.
     */
    public class func verifiedData(_ data: Data, publicKey: SecKey) throws -> Data {
        let serialization = try JSONDecoder().decode([Data].self, from: data)
        guard serialization.count == 2 else {
            throw BerkananError.invalidData
        }
        
        let data = serialization[0]
        let signature = serialization[1]
        
        let algorithm = Berkanan.SignatureAlgorithm
        var error: Unmanaged<CFError>?
        guard SecKeyVerifySignature(publicKey, algorithm, (data as NSData).sha256Digest() as CFData, signature as CFData, &error) else {
            let error = error!.takeRetainedValue() as Error
            throw error
        }
        
        return data
    }
    
    /**
     Returns `data` encrypted with `publicKey` using `Berkanan.EncryptionAlgorithm` algorithm.
     
     - Parameter data: The data to encrypt.
     - Parameter publicKey: The public key used to encrypt.
     */
    class func encryptedData(_ data: Data, publicKey: SecKey) throws -> Data {
        let algorithm = Berkanan.EncryptionAlgorithm
        var error: Unmanaged<CFError>?
        guard let cipherData = SecKeyCreateEncryptedData(publicKey, algorithm, data as CFData, &error) as Data? else {
            let error = error!.takeRetainedValue() as Error
            throw error
        }
        
        return cipherData
    }
    
    /**
     Returns `data` decrypted with `privateKey` using `Berkanan.EncryptionAlgorithm` algorithm.
     
     - Parameter data: The data to decrypt.
     - Parameter private: The private key used to decrypt.
     */
    class func decryptedData(_ data: Data, privateKey: SecKey) throws -> Data {
        let algorithm = Berkanan.EncryptionAlgorithm
        var error: Unmanaged<CFError>?
        guard let clearData = SecKeyCreateDecryptedData(privateKey, algorithm, data as CFData, &error) as Data? else {
            let error = error!.takeRetainedValue() as Error
            throw error
        }
        
        return clearData
    }
    
}
