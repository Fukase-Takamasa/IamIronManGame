//
//  GameViewModel.swift
//  AR-GunMan
//
//  Created by ウルトラ深瀬 on 11/1/23.
//

import RxSwift
import RxCocoa
import BeerKit
import PKHUD

class GameViewModel {
    let bulletsCountImage: Observable<UIImage?>
    let weaponFired: Observable<Void>

    private let disposeBag = DisposeBag()
    
    struct Input {
        let targetHit: Observable<Void>
    }
    
    struct Dependency {
        let motionDetector: MotionDetector
        let currentWeapon: CurrentWeapon
    }
    
    init(input: Input,
         dependency: Dependency) {
        
        self.bulletsCountImage = dependency.currentWeapon.bulletsCountChanged
            .map({dependency.currentWeapon.weaponType.bulletsCountImage(at: $0)})
                
        self.weaponFired = dependency.currentWeapon.fired

        dependency.motionDetector.firingMotionDetected
            .subscribe(onNext: { _ in
                if DeviceTypeHolder.shared.type == .remoCon {
                    BeerKit.sendEvent("fireWeapon")
                }
            }).disposed(by: disposeBag)
        
        dependency.motionDetector.reloadingMotionDetected
            .subscribe(onNext: { _ in
                if DeviceTypeHolder.shared.type == .remoCon {
                    BeerKit.sendEvent("reloadWeapon")
                }
            }).disposed(by: disposeBag)

        input.targetHit
            .subscribe(onNext: { _ in
                AudioUtil.playSound(of: dependency.currentWeapon.weaponType.hitSound)
            }).disposed(by: disposeBag)
        
        BeerKit.onEvent("fireWeapon") { (peerId, data) in
            if DeviceTypeHolder.shared.type == .main {
                dependency.currentWeapon.fire()
            }
        }
        
        BeerKit.onEvent("reloadWeapon") { (peerId, data) in
            if DeviceTypeHolder.shared.type == .main {
                dependency.currentWeapon.reload()
            }
        }
    }
}
