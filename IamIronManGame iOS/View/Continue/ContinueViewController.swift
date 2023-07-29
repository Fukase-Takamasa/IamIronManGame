//
//  ContinueViewController.swift
//  AquaVSTaimei
//
//  Created by 深瀬 貴将 on 2021/02/06.
//

import UIKit

class ContinueViewController: UIViewController {
    
    static func instantiate() -> UIViewController {
        let storyboard: UIStoryboard = UIStoryboard(name: "ContinueViewController", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ContinueViewController") as! ContinueViewController
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //背景をぼかし処理
//        let blurEffect = UIBlurEffect(style: .extraLight)
//        let visualEffectView = UIVisualEffectView(effect: blurEffect)
//        visualEffectView.frame = self.view.frame
//        self.view.insertSubview(visualEffectView, at: 0)
    }
    
    @IBOutlet weak var continueLabel: UILabel!
    @IBOutlet weak var gameOverLabel: UILabel!

    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    
    
    @IBAction func yesContinue(_ sender: Any) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            SideMenuModel.moveScene(to: .battle)
        }
    }
    
    @IBAction func noContinue(_ sender: Any) {
        
//        self.KO.play()
//        self.guaaa.play()
        
        continueLabel.isHidden = true
        yesButton.isHidden = true
        noButton.isHidden = true
        
        self.gameOverLabel.alpha = 0
        self.gameOverLabel.isHidden = false
        UIView.animate(withDuration: 1.5, delay: 0) {
            self.gameOverLabel.alpha = 1
            self.gameOverLabel.font = UIFont(name: "Copperplate", size: 50.0)
        } completion: { (Bool) in
            UIView.animate(withDuration: 1, delay: 2) {
                self.gameOverLabel.alpha = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                SideMenuModel.moveScene(to: .top)
            }
        }
        
    }
    
    @IBAction func showSideMenu(_ sender: Any) {
        let storyboard: UIStoryboard = UIStoryboard(name: "SideMenuVC", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SideMenuVC") as! SideMenuVC
        vc.currentAppScene = .battle
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: true, completion: nil)
    }
    

}
