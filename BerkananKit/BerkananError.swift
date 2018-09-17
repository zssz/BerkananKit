//
//  Created by Zsombor SZABO on 09/05/2018.
//  Copyright © 2018 IZE. All rights reserved.
//  See LICENSE.txt for licensing information.
//

import Foundation

public enum BerkananError: Error {
    case invalidData
    case privateKeyUnavailable
    case publicKeyUnavailable
}

extension BerkananError: LocalizedError {
    
    // Used for Bundle(for:)
    private class Class { }
    
    public var errorDescription: String? {
        switch self {
        case .invalidData: return NSLocalizedString("Invalid data", bundle: Bundle(for: Class.self), comment: "")
        case .privateKeyUnavailable: return NSLocalizedString("Private key unavailable", bundle: Bundle(for: Class.self), comment: "")
        case .publicKeyUnavailable: return NSLocalizedString("Public key unavailable", bundle: Bundle(for: Class.self), comment: "")
        }
    }
    
}
