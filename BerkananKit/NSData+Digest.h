//
//  Created by Zsombor SZABO on 16/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

#import <Foundation/Foundation.h>

/// Adds digest calculation to NSData. Using Objective-C instead of Swift because of CommonCrypto's [modular header problem](https://forums.developer.apple.com/thread/46477#136317)
@interface NSData (Digest)

/// Returns the MD5 digest of the receiver.
- (nonnull NSData *)md5Digest;

/// Returns the SHA-256 digest of the receiver.
- (nonnull NSData *)sha256Digest;

/// Returns the SHA-1 digest of the receiver.
- (nonnull NSData *)sha1Digest;

@end
