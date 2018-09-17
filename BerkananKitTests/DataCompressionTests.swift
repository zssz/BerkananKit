//
//  Created by Zsombor SZABO on 17/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import XCTest
import BerkananKit
import Compression
import os.log

class DataCompressionTests: XCTestCase {
    
    func testEmptyString() {
        testWithData("".data(using: .utf8)!)
    }
    
    func testShortString() {
        testWithData("Z".data(using: .utf8)!)
    }
    
    func testHelloWorldString() {
        testWithData("Hello, World!".data(using: .utf8)!)
    }
    
    func test512BRepeating() {
        testWithData(String(repeating: "Z", count: 512).data(using: .utf8)!)
    }
    
    func test512BRandom() {
        testWithRandomData(512)
    }
    
    func test64KBRandom() {
        testWithRandomData(64 * 1024)
    }
    
    func test16MBRandom() {
        testWithRandomData(16 * 1024 * 1024)
    }
    
    private func testWithRandomData(_ byteCount: Int) {
        let uint32Array = [UInt32](repeating: 0, count: byteCount/4).map({ _ in arc4random() })
        let data = Data(bytes: uint32Array, count: byteCount)
        testWithData(data)
    }
    
    private func testWithData(_ data: Data) {
        [COMPRESSION_LZFSE, COMPRESSION_LZ4, COMPRESSION_LZMA, COMPRESSION_ZLIB].forEach {
            let compressedData = data.compressed(using: $0)
            XCTAssertNotNil(compressedData, "Compressing using algorithm \($0) failed")
            os_log("%@: uncompressed size=%{iec-bytes}d compressed size=%{iec-bytes}d", type: .debug, String(describing: $0), data.count, compressedData!.count)
            let decompressedData = compressedData!.decompressed(using: $0)
            XCTAssertNotNil(decompressedData, "Decompressing using algorithm \($0) failed")
            XCTAssert(data == decompressedData!, "Compressed then decompressed data not equal to original data")
        }
    }
    
}
