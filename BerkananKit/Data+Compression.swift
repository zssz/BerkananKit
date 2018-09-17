//
//  Created by Zsombor SZABO on 17/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import Foundation
import Compression

extension Data {
    
    /// Returns compressed data using `algorithm`.
    ///
    /// - Parameter algorithm: The algorithm used to compress the data.
    public func compressed(using algorithm: compression_algorithm) -> Data? {
        return self.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> Data? in
            let compressedData = self.compress(using: algorithm, operation: COMPRESSION_STREAM_ENCODE, sourcePointer: pointer, sourceSize: self.count)
            return compressedData
        }
    }
    
    /// Returns decompressed data using `algorithm`.
    ///
    /// - Parameter algorithm: The algorithm used to decompress the data.
    public func decompressed(using algorithm: compression_algorithm) -> Data? {
        return self.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> Data? in
            let decompressedData = self.compress(using: algorithm, operation: COMPRESSION_STREAM_DECODE, sourcePointer: pointer, sourceSize: self.count)
            return decompressedData
        }
    }

    func compress(using algorithm: compression_algorithm, operation: compression_stream_operation, sourcePointer: UnsafePointer<UInt8>, sourceSize: Int) -> Data? {
        // 0. Allocate compression_stream object.
        let compressionStreamPointer = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        defer {
            // Deallocate before return.
            compressionStreamPointer.deallocate()
        }
        var compressionStream = compressionStreamPointer.pointee
        
        // 1. Initialize the state of your compression_stream object.
        let compressionStreamInitStatus = compression_stream_init(&compressionStream, operation, algorithm)
        defer {
            // 5. Call compression_stream_destroy to free the state object in the stream object.
            compression_stream_destroy(&compressionStream)
        }
        guard compressionStreamInitStatus != COMPRESSION_STATUS_ERROR else {
            return nil
        }
        
        // 2. Set the dst_buffer, dst_size, src_buffer, and src_size fields of the compression_stream object to point to the next blocks to be processed.
        // Allocate a destination buffer with size of maximum 64 kB and minimum 16 B.
        let destinationSize = Swift.max(Swift.min(sourceSize, 64 * 1024), 16)
        let destinationPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationSize)
        defer {
            // Deallocate before return.
            destinationPointer.deallocate()
        }
        compressionStream.src_ptr  = sourcePointer
        compressionStream.src_size = sourceSize
        compressionStream.dst_ptr  = destinationPointer
        compressionStream.dst_size = destinationSize
        
        // 3. Call compression_stream_process. If no further input will be added to the stream via subsequent calls, flags should be COMPRESSION_STREAM_FINALIZE (otherwise 0). If compression_stream_process returns COMPRESSION_STATUS_END, there will be no further output from the stream.
        // 4. Repeat steps 2 and 3 as necessary to process the entire stream.
        var result = Data()
        while true {
            
            // This function performs compression or decompression using an initialized compression_stream object.
            // Each time it is called successfully, the function consumes data from the source buffer and writes data into the destination buffer, until it reaches the end of one of the buffers and returns either COMPRESSION_STATUS_OK or COMPRESSION_STATUS_END.
            // After a successful call the buffer parameters in the stream object are updated: src_ptr is incremented (and src_size decremented) by the number of input bytes consumed. Likewise, dst_ptr is incremented (and dst_size decremented) by the number of output bytes produced. The sum (src_ptr + src_size) remains unchanged, and so does (dst_ptr + dst_size). At this point, either src_size or dst_size will be 0, indicating that the source buffer is empty or the destination buffer is full.
            //  If the source buffer is empty, you might refill it with more data and adjust the parameters, or point to a different buffer for the next call. If you are not supplying any more input data, set flags to COMPRESSION_STREAM_FINALIZE and call again.
            //  If the destination buffer is full and the return value is not COMPRESSION_STATUS_END, there may still be input available for processing. To let this happen, you might grow the buffer, move the pointer back to re-use the buffer, or point to a new destination buffer, and then call again.
            switch compression_stream_process(&compressionStream, Int32(COMPRESSION_STREAM_FINALIZE.rawValue)) {
            case COMPRESSION_STATUS_OK:
                guard compressionStream.dst_size == 0 else {
                    return nil
                }
                result.append(destinationPointer, count: compressionStream.dst_ptr - destinationPointer)
                compressionStream.dst_ptr = destinationPointer
                compressionStream.dst_size = destinationSize
                
            case COMPRESSION_STATUS_END:
                result.append(destinationPointer, count: compressionStream.dst_ptr - destinationPointer)
                return result
                
            case COMPRESSION_STATUS_ERROR:
                return nil
                
            default:
                return nil
            }
            
        }
    }
    
}

extension compression_algorithm: CustomStringConvertible {
    
    public var description: String {
        get {
            switch self {
            case COMPRESSION_LZFSE:
                return "LZFSE"
            case COMPRESSION_LZ4:
                return "LZ4"
            case COMPRESSION_LZMA:
                return "LZMA"
            case COMPRESSION_ZLIB:
                return "ZLIB"
            default:
                return "compression_algorithm(rawValue: \(rawValue))"
            }
        }
    }
}
