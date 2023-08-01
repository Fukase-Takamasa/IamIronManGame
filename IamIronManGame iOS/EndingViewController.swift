//
//  EndingViewController.swift
//  IamIronManGame iOS
//
//  Created by 深瀬 on 2023/08/01.
//

import UIKit
import RxSwift
import RxCocoa
import BeerKit

class EndingViewController: UIViewController {
    let disposeBag = DisposeBag()

    @IBOutlet weak var thanksLabel: UILabel!
    
    @IBOutlet weak var kanLabel: UILabel!
    @IBOutlet weak var backToTopPageButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.backToTopPageButton.isHidden = true
        
        backToTopPageButton.rx.tap
            .subscribe(onNext: { [weak self] element in
                guard let self = self else { return }
                BeerKit.sendEvent("backToTopPage")
                self.presentingViewController?.presentingViewController?.dismiss(animated: true)
            }).disposed(by: disposeBag)

        AudioUtil.playSound(of: .ultraSoulHey)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: {
            self.thanksLabel.isHidden = true
            self.kanLabel.isHidden = false
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3, execute: {
            self.backToTopPageButton.isHidden = false
        })
    }

}
