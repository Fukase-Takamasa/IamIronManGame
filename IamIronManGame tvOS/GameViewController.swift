//
//  GameViewController.swift
//  IamIronManGame tvOS
//
//  Created by 深瀬 on 2023/07/05.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
    
    var gameView: SCNView {
        return self.view as! SCNView
    }
    
    @IBOutlet weak var labelB: UILabel!
    @IBOutlet weak var labelA: UILabel!
    @IBOutlet weak var labelA: UILabel!
    var gameController: GameController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gameController = GameController(sceneRenderer: gameView)
        
        // Allow the user to manipulate the camera
        self.gameView.allowsCameraControl = true
        
        // Show statistics such as fps and timing information
        self.gameView.showsStatistics = true
        
        // Configure the view
        self.gameView.backgroundColor = UIColor.black
        
        // Add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        var gestureRecognizers = gameView.gestureRecognizers ?? []
        gestureRecognizers.insert(tapGesture, at: 0)
        self.gameView.gestureRecognizers = gestureRecognizers
    }
    
    @objc
    @IBOutlet weak var backToTopPageButton: UIButton!
    func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        @IBOutlet weak var backToTopPageButton: UIButton!
        // Highlight the tapped nodes
        let p = gestureRecognizer.location(in: gameView)
//        gameController.highlightNodes(atPoint: p)
    }
    
}
