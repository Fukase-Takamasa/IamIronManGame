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
    
//    let isSendRemoConInfo: Observable<Bool>

    private let disposeBag = DisposeBag()
    
    struct Input {
        let targetHit: Observable<Void>
        let isSendRemoConInfo: BehaviorRelay<Bool>
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
        
//        let _isSendRemoConInfo = BehaviorRelay<Bool>(value: false)
//        self.isSendRemoConInfo = input.isSendRemoConInfo.asObservable()

        dependency.motionDetector.firingMotionDetected
            .subscribe(onNext: { _ in
                if DeviceTypeHolder.shared.type == .remoCon {
                    if isContinueVCVisible {
                        BeerKit.sendEvent("yesContinue")
                        print("firingMotionDetected yesContinue")
                        print("vm yesContinue流した")
                    }else if input.isSendRemoConInfo.value {
                        print("firingMotionDetected fireWeapon")
                        BeerKit.sendEvent("fireWeapon")
                    }else {
                        print("firingMotionDetected decreaseStepValue")
//                        BeerKit.sendEvent("decreaseStepValue")
                    }
                }
            }).disposed(by: disposeBag)
        
        dependency.motionDetector.reloadingMotionDetected
            .subscribe(onNext: { _ in
                if DeviceTypeHolder.shared.type == .remoCon {
                    if isContinueVCVisible {
                        print("reloadingMotionDetected noContinue")
                        BeerKit.sendEvent("noContinue")
                        print("vm noContinue流した")
                    }else if input.isSendRemoConInfo.value {
                        print("reloadingMotionDetected reloadWeapon")
                        BeerKit.sendEvent("reloadWeapon")
                    }else {
                        print("reloadingMotionDetected increaseStepValue")
//                        BeerKit.sendEvent("increaseStepValue")
                    }
                }
            }).disposed(by: disposeBag)
        
        dependency.motionDetector.secretEventMotionDetected
            .subscribe(onNext: { _ in
                if DeviceTypeHolder.shared.type == .remoCon {
                    BeerKit.sendEvent("secretEvent")
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

extension String {
    func toData() -> Data? {
        return self.data(using: .utf8)
    }
}

extension Data {
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}

extension Int {
    func toData() -> Data {
        return withUnsafeBytes(of: self) { Data($0) }
    }
}

extension Data {
    func toInt() -> Int? {
        return self.withUnsafeBytes { $0.load(as: Int.self) }
    }
}
