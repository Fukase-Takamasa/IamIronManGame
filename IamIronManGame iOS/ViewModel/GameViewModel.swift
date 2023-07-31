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
        
        var isContinueVCVisible = false

        dependency.motionDetector.firingMotionDetected
            .subscribe(onNext: { _ in
                if DeviceTypeHolder.shared.type == .remoCon {
                    if isContinueVCVisible {
                        BeerKit.sendEvent("yesContinue")
                        print("vm yesContinue流した")
                    }else {
                        BeerKit.sendEvent("fireWeapon")
                    }
                }
            }).disposed(by: disposeBag)
        
        dependency.motionDetector.reloadingMotionDetected
            .subscribe(onNext: { _ in
                if DeviceTypeHolder.shared.type == .remoCon {
                    if isContinueVCVisible {
                        BeerKit.sendEvent("noContinue")
                        print("vm noContinue流した")
                    }else {
                        BeerKit.sendEvent("reloadWeapon")
                    }
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
        
        BeerKit.onEvent("isContinueVCVisible") { (peerId, data) in
            guard let data = data else { return }
            if DeviceTypeHolder.shared.type == .remoCon {
                isContinueVCVisible = data.toBool() ?? false
            }
        }
    }
}

extension Bool {
    func toData() -> Data? {
        return withUnsafeBytes(of: self) { Data($0) }
    }
}

extension Data {
    func toBool() -> Bool? {
        return self.withUnsafeBytes { $0.load(as: Bool.self) }
    }
}
