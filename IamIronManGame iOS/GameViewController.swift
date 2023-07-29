//
//  GameViewController.swift
//  IamIronManGame iOS
//
//  Created by 深瀬 on 2023/07/29.
//

import UIKit
import RxSwift
import RxCocoa

class GameViewController: UIViewController {
    var viewModel: GameViewModel!
    let sceneManager = GameSceneManager()
    let disposeBag = DisposeBag()
    
    
    @IBOutlet weak var bulletsCountImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: - input
        let vmInput = GameViewModel
            .Input(targetHit: sceneManager.targetHit)
        
        let vmDependency = GameViewModel
            .Dependency(motionDetector: MotionDetector(),
                        currentWeapon: CurrentWeapon(type: .pistol))
        
        viewModel = GameViewModel(input: vmInput, dependency: vmDependency)
        
        //MARK: - output
        viewModel.bulletsCountImage
            .bind(to: bulletsCountImageView.rx.image)
            .disposed(by: disposeBag)

        viewModel.weaponFired
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else {return}
                self.sceneManager.fireWeapon()
            }).disposed(by: disposeBag)
        
        //MARK: - other
        addSceneView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SceneViewSettingUtil.startSession(sceneManager.sceneView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SceneViewSettingUtil.pauseSession(sceneManager.sceneView)
    }
    
    private func addSceneView() {
        sceneManager.sceneView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width / 2, height: self.view.frame.size.height)
        view.insertSubview(sceneManager.sceneView, at: 0)
    }
}
