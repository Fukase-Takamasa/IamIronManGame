//
//  TopViewController.swift
//  IamIronManGame iOS
//
//  Created by 深瀬 on 2023/07/29.
//

import UIKit
import RxSwift
import RxCocoa
import BeerKit
import PKHUD

class TopViewController: UIViewController {
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var chooseMainDeviceButton: UIButton!
    @IBOutlet weak var chooseRemoConDeviceButton: UIButton!
    @IBOutlet weak var chooseCameraDeviceButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        chooseMainDeviceButton.rx.tap
            .subscribe(onNext: { element in
                DeviceTypeHolder.shared.type = .main
                self.transitToGameView()
            }).disposed(by: disposeBag)
        
        chooseRemoConDeviceButton.rx.tap
            .subscribe(onNext: { element in
                DeviceTypeHolder.shared.type = .remoCon
                self.transitToGameView()
            }).disposed(by: disposeBag)
        
        chooseCameraDeviceButton.rx.tap
            .subscribe(onNext: { element in
                DeviceTypeHolder.shared.type = .camera
                self.transitToGameView()
            }).disposed(by: disposeBag)
        
        BeerKit.onConnect { (myPeerId, peerId) in
            DispatchQueue.main.async {
                print("\(peerId.displayName)と接続しました")
                HUD.flash(.labeledSuccess(title: "端末と接続しました", subtitle: "表示名:\(peerId.displayName)"), delay: 2.0)
            }
        }
    }
    
    private func transitToGameView() {
        let storyboard: UIStoryboard = UIStoryboard(name: "GameViewController", bundle: nil)
        let vc = storyboard.instantiateInitialViewController() as! GameViewController
        self.present(vc, animated: true)
    }
}
