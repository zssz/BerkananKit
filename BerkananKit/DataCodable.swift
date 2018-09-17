//
//  Created by Zsombor SZABO on 25/07/2017.
//  Copyright © 2017 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import Foundation

/// A type that can convert itself into and out of a little endian byte buffer. Introduced to get a more compact encoding for the `UUID` type than the one from the implementation of `Codable`.
public protocol DataCodable {
    
    /// Initialize an instance from a little endian byte buffer.
    ///
    /// - Parameter data: A little endian byte buffer.
    init?(data: Data)
    
    /// Returns a little endian byte buffer.
    var encodedData: Data { get }
    
}

extension DataCodable {
    
    public init?(data: Data) {
        guard data.count == MemoryLayout<Self>.size else {
            return nil            
        }
        self = data.withUnsafeBytes { $0.pointee }
    }
    
    public var encodedData: Data {
        var value = self
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
    
}
