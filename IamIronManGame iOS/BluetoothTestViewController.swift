//
//  BluetoothTestViewController.swift
//  IamIronManGame iOS
//
//  Created by 深瀬 on 2023/07/05.
//

import UIKit
import SceneKit
import ARKit
import BeerKit
import MultipeerConnectivity

struct Count: Codable {
    let value: Int
}

class BluetoothTestViewController: UIViewController {
    var gameView1: ARSCNView = ARSCNView()
//    var gameController: GameController!
    
    var count = 0
    
    @IBOutlet weak var myNameLabel: UILabel!
    @IBOutlet weak var otherPlayerNameLabel: UILabel!
    
    @IBOutlet weak var countLabel: UILabel!
    
    @IBAction func didTapButton(_ sender: Any) {
        count += 1
        let count = Count(value: count)
        let data: Data = try! JSONEncoder().encode(count)
        BeerKit.sendEvent("count", data: data)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        gameView1.frame = CGRect(x: 0, y: 0, width: view.frame.size.width / 2, height: view.frame.size.height)
//        view.addSubview(gameView1)
//        self.gameController = GameController(sceneRenderer1: gameView1)
//        self.gameView1.allowsCameraControl = true
//        self.gameView1.showsStatistics = true
//        SceneViewSettingUtil.setupSceneView(gameView1, sceneViewDelegate: gameController, physicContactDelegate: gameController)
        
        BeerKit.onConnect { (myPeerId, peerId) in
            DispatchQueue.main.async {
                self.myNameLabel.text = "自分: \(myPeerId.displayName)"
                self.otherPlayerNameLabel.text = "相手: \(peerId.displayName)"
            }
        }
        
        BeerKit.onEvent("count") { (peerId, data) in
            guard let data = data,
                  let count = try? JSONDecoder().decode(Count.self, from: data) else {
                return
            }
            DispatchQueue.main.async {
                self.countLabel.text = "\(count)"
            }
        }
    }

//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        SceneViewSettingUtil.startSession(gameView1)
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        SceneViewSettingUtil.pauseSession(gameView1)
//    }
}
