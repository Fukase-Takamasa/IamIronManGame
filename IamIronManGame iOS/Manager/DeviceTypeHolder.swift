//
//  DeviceTypeHolder.swift
//  IamIronManGame iOS
//
//  Created by 深瀬 on 2023/07/29.
//

import Foundation

enum DeviceType {
    case main
    case remoCon
    case camera
}

class DeviceTypeHolder {
    static let shared = DeviceTypeHolder()
    private init() {}
    
    var type = DeviceType.main
}
