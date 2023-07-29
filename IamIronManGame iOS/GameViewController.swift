//
//  GameViewController.swift
//  IamIronManGame iOS
//
//  Created by 深瀬 on 2023/07/05.
//

import UIKit
import SceneKit
import ARKit

class GameViewController: UIViewController {
    var gameView1: ARSCNView = ARSCNView()
    var gameController: GameController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameView1.frame = CGRect(x: 0, y: 0, width: view.frame.size.width / 2, height: view.frame.size.height)
        view.addSubview(gameView1)
        self.gameController = GameController(sceneRenderer1: gameView1)
        self.gameView1.allowsCameraControl = true
        self.gameView1.showsStatistics = true
        SceneViewSettingUtil.setupSceneView(gameView1, sceneViewDelegate: gameController, physicContactDelegate: gameController)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SceneViewSettingUtil.startSession(gameView1)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SceneViewSettingUtil.pauseSession(gameView1)
    }
}
