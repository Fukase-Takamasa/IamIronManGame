//
//  TopViewController.swift
//  IamIronManGame iOS
//
//  Created by 深瀬 on 2023/07/29.
//

import UIKit
import RxSwift
import RxCocoa

class TopViewController: UIViewController {
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var chooseMainDeviceButton: UIButton!
    @IBOutlet weak var chooseRemoConDeviceButton: UIButton!
    @IBOutlet weak var chooseCameraDeviceButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        chooseMainDeviceButton.rx.tap
            .subscribe(onNext: { element in
                let storyboard: UIStoryboard = UIStoryboard(name: "GameViewController", bundle: nil)
                let vc = storyboard.instantiateInitialViewController() as! GameViewController
                self.present(vc, animated: true)
            }).disposed(by: disposeBag)
        
        chooseRemoConDeviceButton.rx.tap
            .subscribe(onNext: { element in
//                let storyboard: UIStoryboard = UIStoryboard(name: "GameViewController", bundle: nil)
//                let vc = storyboard.instantiateInitialViewController() as! GameViewController
//                self.present(vc, animated: true)
            }).disposed(by: disposeBag)
        
        chooseCameraDeviceButton.rx.tap
            .subscribe(onNext: { element in
//                let storyboard: UIStoryboard = UIStoryboard(name: "GameViewController", bundle: nil)
//                let vc = storyboard.instantiateInitialViewController() as! GameViewController
//                self.present(vc, animated: true)
            }).disposed(by: disposeBag)
    }
}
