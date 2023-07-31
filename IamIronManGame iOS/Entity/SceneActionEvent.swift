//
//  SceneActionEvent.swift
//  IamIronManGame iOS
//
//  Created by 深瀬 on 2023/07/31.
//

import Foundation
import SceneKit

enum SceneActionEventType: Codable {
    case initialNodesShowed
    case taimeiImageChanged
    case taimeiBulletShot
    case playerBulletShot
    case nodesUpdated
    case startButtonTapped
    case gameStarted
}

struct SceneActionEvent: Codable {
    let type: SceneActionEventType
    let nodes: [GameSceneNode]
    var bulletShootingAction: BulletShootingAction?
    var taimeisanPausingType: TaimeisanPausingType?
}

enum GameSceneNodeType: Codable {
    case taimei
    case pistol
    case taimeiBullet
    case playerBullet
    case startGameButton
}

struct GameSceneNode: Codable {
    let type: GameSceneNodeType
    let name: String
    let position: Vector3Entity
    let angle: Vector3Entity
}

struct BulletShootingAction: Codable {
    let startPosition: Vector3Entity
    let targetPosition: Vector3Entity
    let duration: TimeInterval
}
