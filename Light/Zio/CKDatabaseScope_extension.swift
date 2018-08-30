//
// Created by 김범수 on 2018. 4. 19..
// Copyright (c) 2018 piano. All rights reserved.
//

import CloudKit

extension CKDatabaseScope {
    var string: String {
        switch self {
            case .public: return "public"
            case .private: return "private"
            case .shared: return "shared"
        }
    }
}