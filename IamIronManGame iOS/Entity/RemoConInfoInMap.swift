//
//  Device.swift
//  IamIronManGame iOS
//
//  Created by 深瀬 on 2023/07/30.
//

import Foundation

struct RemoConInfoInMap: Codable {
    let position: Vector3Entity
    let angle: Vector3Entity
}

struct Vector3Entity: Codable {
    let x: Float
    let y: Float
    let z: Float
}
