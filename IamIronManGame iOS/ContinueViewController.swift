//
//  ContinueViewController.swift
//  AquaVSTaimei
//
//  Created by 深瀬 貴将 on 2021/02/06.
//

import UIKit
import RxSwift
import RxCocoa
import BeerKit

protocol ContinueVCDelegate: AnyObject {
    func yesButtonTapped()
    func noButtonTapped()
}

class ContinueViewController: UIViewController {

    let disposeBag = DisposeBag()
    weak var delegate: ContinueVCDelegate?

    @IBOutlet weak var continueLabel: UILabel!
    @IBOutlet weak var gameOverLabel: UILabel!

    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        yesButton.rx.tap
            .subscribe(onNext: { element in
                self.retryGame()
            }).disposed(by: disposeBag)
        
        noButton.rx.tap
            .subscribe(onNext: { element in
                self.showGameOverViewAndBackToTopPage()
            }).disposed(by: disposeBag)
        
        BeerKit.onEvent("yesContinue") { peerID, data in
            self.yesButton.sendActions(for: .touchUpInside)
            print("vc onEvent yesContinue")
        }
        
        BeerKit.onEvent("noContinue") { peerID, data in
            self.noButton.sendActions(for: .touchUpInside)
            print("vc onEvent noContinue")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        BeerKit.sendEvent("isContinueVCVisible", data: true.toData() ?? Data())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        BeerKit.sendEvent("isContinueVCVisible", data: false.toData() ?? Data())
    }
    
    func retryGame() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.delegate?.yesButtonTapped()
            self.dismiss(animated: true)
        }
    }
    
    func showGameOverViewAndBackToTopPage() {
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
                self.presentingViewController?.presentingViewController?.dismiss(animated: true)
            }
        }
    }
}
