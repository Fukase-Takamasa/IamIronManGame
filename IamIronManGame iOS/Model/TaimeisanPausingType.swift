//
//  TaimeisanPausingType.swift
//  AquaVSTaimei
//
//  Created by ウルトラ深瀬 on 4/10/22.
//

import Foundation

enum TaimeisanPausingType: String {
    case standing = "standing"
    case shooting = "shooting"
    
    var toggledValue: TaimeisanPausingType {
        if self == .standing {
            return .shooting
        }else {
            return .standing
        }
    }
}
