//
//  GameController.swift
//  IamIronManGame Shared
//
//  Created by 深瀬 on 2023/07/05.
//

import SceneKit
import ARKit

#if os(macOS)
    typealias SCNColor = NSColor
#else
    typealias SCNColor = UIColor
#endif

class GameController: NSObject {

    let scene1: SCNScene
    let sceneRenderer1: SCNSceneRenderer
    
    init(sceneRenderer1 renderer1: SCNSceneRenderer) {
        sceneRenderer1 = renderer1
        scene1 = SCNScene(named: "Art.scnassets/ship.scn")!
        
        super.init()

        if let ship1 = scene1.rootNode.childNode(withName: "ship", recursively: true) {
            ship1.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        }
        
        sceneRenderer1.scene = scene1
    }
}

extension GameController: ARSCNViewDelegate {
    //常に更新され続けるdelegateメソッド
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
    }
}

extension GameController: SCNPhysicsContactDelegate {
    //衝突検知時に呼ばれる
    //MEMO: - このメソッド内でUIの更新を行いたい場合はmainThreadで行う
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
       
    }
}
