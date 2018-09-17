# BerkananKit

[![Travis CI](https://travis-ci.org/zssz/BerkananKit.svg?branch=master)](https://travis-ci.org/zssz/BerkananKit) [![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://developer.apple.com/ios) [![Language](https://img.shields.io/badge/language-Swift-orange.svg)](https://developer.apple.com/swift) [![Language](https://img.shields.io/badge/language-Objective--C-blue.svg)](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC) [![Documented](https://img.shields.io/badge/documented-%E2%9C%93-brightgreen.svg)]() [![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE.txt)

This open-source software is part of the iOS app [Berkanan](http://berkanan.chat). With Berkanan app, you can send public and end-to-end encrypted private messages to nearby users using Bluetooth without the need to register for an account. An app like this could be useful at events (e.g., festivals, sports, protests), for message walls or even on an ✈️ for asking nearby users what movie to watch.

`BerkananKit` allows you to take a look at the inner workings of [BLE](https://en.wikipedia.org/wiki/Bluetooth_Low_Energy) communication in Berkanan app, specifically:
- What kind of peripheral services and characteristics there are and what they are used for.
- What are the UUIDs of these services and characteristics.
- What data format is expected when reading or writing these characteristics. 
- What kind of cryptography is used and how it's implemented.

This software was made available to the public with the intentions to make Berkanan app transparent, especially its use of cryptography.

## Requirements

### Build

This software was built using [Xcode](https://developer.apple.com/xcode) 10.0 on macOS 10.13.6 with the iOS 12.0 SDK. You should be able to open the project and choose *Product* > *Build*.

### Frameworks

* [Foundation](https://developer.apple.com/documentation/foundation)
* [CoreBluetooth](https://developer.apple.com/documentation/corebluetooth)
* [Compression](https://developer.apple.com/documentation/compression)
* [CommonCrypto](https://opensource.apple.com/source/CommonCrypto)
* [Security](https://developer.apple.com/documentation/security)
* [os.log](https://developer.apple.com/documentation/os/logging)

### Runtime

None. The Xcode project builds a framework target.

## License

This software is distributed under the terms and conditions of the [MIT license](LICENSE.txt).
