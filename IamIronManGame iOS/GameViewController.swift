//
//  GameViewController.swift
//  IamIronManGame iOS
//
//  Created by 深瀬 on 2023/07/29.
//

import UIKit
import RxSwift
import RxCocoa
import SceneKit
import ARKit
import GTProgressBar
import BeerKit

class GameViewController: UIViewController {
    var viewModel: GameViewModel!
    let disposeBag = DisposeBag()
    
    var sceneView = ARSCNView()
    
    // - node
    private var originalBulletNode = SCNNode()
    private var pistolParentNode = SCNNode()
    private var taimeisan = SCNNode()
    private var taimeiBulletNode: SCNNode?
    private var remoConPistolParentNode = SCNNode()
    
    private var currentWeapon: WeaponType = .pistol

    private var taimeisanActionTimer = Timer()
    private var timeCount = Int()
    private var damageLimitCount = 3
    private var taimeisanPausingType: TaimeisanPausingType = .standing
    private var taimeisanLifePoint = 100.0
    private var playerLifePoint = 100.0
    private var isTaimeisanKnockedDown = false
    private var isPlayerKnockedDown = false
    private var isWorldMapSent = false
    
    // - notification
    private let _targetHit = PublishRelay<Void>()
    
    @IBOutlet weak var bulletsCountImageView: UIImageView!
    @IBOutlet weak var taimeisanLifeBar: GTProgressBar!
    @IBOutlet weak var playerLifeBar: GTProgressBar!
    @IBOutlet weak var koImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: - input
        let vmInput = GameViewModel
            .Input(targetHit: _targetHit.asObservable())
        
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
                self.fireWeapon()
            }).disposed(by: disposeBag)

        BeerKit.onEvent("worldMap") { (peerId, data) in
            if DeviceTypeHolder.shared.type == .main { return }
            guard let data = data else { return }
            guard let unarchived = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [ARWorldMap.classForKeyedUnarchiver()], from: data),
                  let worldMap = unarchived as? ARWorldMap else {
                return
            }
            // Run the session with the received world map.
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            configuration.initialWorldMap = worldMap
            self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        
        BeerKit.onEvent("remoConInfoInMap") { peerID, data in
            guard let data = data else { return }
            if DeviceTypeHolder.shared.type == .main {
                do {
                    let remoConInfo = try JSONDecoder().decode(RemoConInfoInMap.self, from: data)
                    self.moveWeaponOnRemoCon(remoConInfo: remoConInfo)
                    print("moveWeaponOnRemoConした")
                } catch {
                    print("moveWeaponOnRemoConできなかった")
                }
            }
        }
        
        //MARK: - other
        addSceneView()
        
        //各武器をセットアップ
        pistolParentNode = setupWeaponNode(type: .pistol)
        originalBulletNode = createOriginalBulletNode()
        
        switch DeviceTypeHolder.shared.type {
        case .main:
//            startGame()
//            showWeapon(.pistol)
            addPistolForRemoCon()
            break
        case .remoCon:
            break
        case .camera:
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SceneViewSettingUtil.startSession(sceneView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SceneViewSettingUtil.pauseSession(sceneView)
        taimeisanActionTimer.invalidate()
        AudioUtil.initAudioPlayers()
    }
    
    private func addSceneView() {
        sceneView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width / 2, height: self.view.frame.size.height)
        view.insertSubview(sceneView, at: 0)
        SceneViewSettingUtil.setupSceneView(sceneView, sceneViewDelegate: self, physicContactDelegate: self,arSessionDelegate: self)
    }
    
    private func sendWorldMapToOtherDevices() {
        sceneView
            .session
            .getCurrentWorldMap { worldMap, error in
                print("getCurrentWorldMap worldMap: \(String(describing: worldMap)) error: \(String(describing: error))")
                guard let map = worldMap else {
                    print("Error: \(error!.localizedDescription)")
                    return
                }
                guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true) else {
                    fatalError("can't encode map")
                }
                BeerKit.sendEvent("worldMap", data: data)
                print("worldMapを送信した worldMap, \(map), data: \(data)")
            }
    }
    
    //指定された武器を表示
    func showWeapon(_ type: WeaponType) {
        currentWeapon = type
        switchWeapon()
    }
    
    //現在選択中の武器の発砲に関わるアニメーション処理などを実行
    func fireWeapon() {
        shootPlayerBullet()
        pistolNode().runAction(SceneAnimationUtil.shootingMotion())
    }

    private func setupWeaponNode(type: WeaponType) -> SCNNode {
        let weaponParentNode = SceneNodeUtil.loadScnFile(of: GameConst.getWeaponScnAssetsPath(type), nodeName: "\(type.name)Parent")
//        SceneNodeUtil.addBillboardConstraint(weaponParentNode)
//        weaponParentNode.position = SceneNodeUtil.getCameraPosition(sceneView)
        return weaponParentNode
    }
    
    private func pistolNode() -> SCNNode {
        return pistolParentNode.childNode(withName: WeaponType.pistol.name, recursively: false) ?? SCNNode()
    }
    
    private func switchWeapon() {
        SceneNodeUtil.removeOtherWeapon(except: currentWeapon, scnView: sceneView)
        switch currentWeapon {
        case .pistol:
            sceneView.scene.rootNode.addChildNode(pistolParentNode)
            pistolNode().runAction(SceneAnimationUtil.gunnerShakeAnimationNormal())
        case .bazooka:
            break
        }
    }

    private func createOriginalBulletNode() -> SCNNode {
        let sphere: SCNGeometry = SCNSphere(radius: 0.05)
        let customYellow = UIColor(red: 253/255, green: 202/255, blue: 119/255, alpha: 1)
        
        sphere.firstMaterial?.diffuse.contents = customYellow
        originalBulletNode = SCNNode(geometry: sphere)
        originalBulletNode.name = GameConst.bulletNodeName
        originalBulletNode.scale = SCNVector3(x: 1, y: 1, z: 1)
        
        //当たり判定用のphysicBodyを追加
        let shape = SCNPhysicsShape(geometry: sphere, options: nil)
        originalBulletNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        originalBulletNode.physicsBody?.contactTestBitMask = 1
        originalBulletNode.physicsBody?.isAffectedByGravity = false
        return originalBulletNode
    }

    //弾ノードを発射
    private func shootPlayerBullet() {
        //メモリ節約のため、オリジナルをクローンして使う
        let clonedBulletNode = originalBulletNode.clone()
        clonedBulletNode.position = SceneNodeUtil.getCameraPosition(sceneView)
        sceneView.scene.rootNode.addChildNode(clonedBulletNode)
        clonedBulletNode.runAction(
            SceneAnimationUtil.shootBulletToCenterOfCamera(sceneView.pointOfView), completionHandler: {
                clonedBulletNode.removeFromParentNode()
            }
        )
    }

    private func moveWeaponOnRemoCon(remoConInfo: RemoConInfoInMap) {
        remoConPistolParentNode.position = SCNVector3(
            x: remoConInfo.position.x,
            y: remoConInfo.position.y,
            z: remoConInfo.position.z
        )
        remoConPistolParentNode.eulerAngles = SCNVector3(
            x: remoConInfo.angle.x,
            y: remoConInfo.angle.y,
            z: remoConInfo.angle.z
        )
    }
    
    private func isTargetHit(contact: SCNPhysicsContact) -> Bool {
        return (contact.nodeA.name == GameConst.bulletNodeName && contact.nodeB.name == GameConst.targetNodeName) ||
            (contact.nodeB.name == GameConst.bulletNodeName && contact.nodeA.name == GameConst.targetNodeName)
    }
        
    private func startGame() {
        addTaimeisan()
        addCameraSphere()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            AudioUtil.playSound(of: .yoro)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showDarkAuraParticle()
            AudioUtil.playSound(of: .bossBattle)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            AudioUtil.playSound(of: .kakugo)
            self.taimeisanActionTimer = Timer.scheduledTimer(timeInterval: 1.6,
                                                             target: self,
                                                             selector: #selector(self.taimeisanActionTimerUpdated(timer:)),
                                                             userInfo: nil,
                                                             repeats: true
            )
        }
    }
    
    private func isCollisionOccuredBetweenPlayerAndTaimeisan(nodeA: SCNNode, nodeB: SCNNode) -> Bool {
        return (nodeA.name == "taimeisan" && nodeB.name!.contains("playerBullet")) || (nodeB.name == "taimeisan" && nodeA.name!.contains("playerBullet"))
    }
    
    private func isCollisionOccuredBetweenTaimeiBulletAndCamera(nodeA: SCNNode, nodeB: SCNNode) -> Bool {
        return (nodeA.name!.contains("taimeiBullet") && nodeB.name == "cameraSphere") || (nodeB.name!.contains("taimeiBullet") && nodeA.name == "cameraSphere")
    }
    
    private func handleAttackToTaimeisan(nodeA: SCNNode, nodeB: SCNNode) {
        guard !isTaimeisanKnockedDown else {
            return
        }
        
        AudioUtil.playSound(of: .besi)
        AudioUtil.playSound(of: [Sounds.uu, Sounds.kuo].randomElement()!)
        
        nodeA.name!.contains("playerBullet") ? nodeA.removeFromParentNode() : nodeB.removeFromParentNode()
                   
        // 連続攻撃を制御（1.6秒の間に3回まで)
        if damageLimitCount <= 0 { return }
        
        var damege = 2.0
//        if chihuahua.childNode(withName: "aquaMoveFire", recursively: false) != nil {
//            print("aquaMove発動中なので攻撃力を3倍にします")
//            damege *= 3
//        }
        
        taimeisanLifePoint -= damege
        
        DispatchQueue.main.async {
            self.taimeisanLifeBar.animateTo(progress: CGFloat(self.taimeisanLifePoint / 100)) {
                
                if self.taimeisanLifeBar.progress <= 0.3 {
                    AudioUtil.playSound(of: .karadaga)
                }
                
                if self.taimeisanLifeBar.progress <= 0.0 {
                    AudioUtil.playSound(of: .guaaa)
                    
                    self.KO_Animation()
                    self.taimeisanKnockedDown()
                }
            }
        }
        damageLimitCount -= 1
    }
    
    private func handleAttackToCamera(nodeA: SCNNode, nodeB: SCNNode) {
        guard !isPlayerKnockedDown else {
            return
        }
        
//        if chihuahua.childNode(withName: "aquaMoveFire", recursively: false) != nil {
//            print("aquaMove発動中は自身へのダメージを無効化します。")
//            return
//        }
        
        AudioUtil.playSound(of: .aquaDamage)

        nodeA.name!.contains("taimeiBullet") ? nodeA.removeFromParentNode() : nodeB.removeFromParentNode()
        
        playerLifePoint -= 10
        
        DispatchQueue.main.async {
            self.playerLifeBar.animateTo(progress: CGFloat(self.playerLifePoint / 100)) {
                if self.playerLifeBar.progress == 0.0 {
                    self.KO_Animation()
                    self.playerKnockedDown()
                }
            }
        }
    }
    
    @objc func taimeisanActionTimerUpdated(timer: Timer) {
        // タイメイさんのポージングタイプによってマテリアル表面の画像を切り替え
        changeTaimeisanImage(to: taimeisanPausingType)
        
        // 射撃の構えの時
    shootingActionScope: if taimeisanPausingType == .shooting {
        
        // 最初の２秒間は除外
        if timeCount <= 2 {
            break shootingActionScope
        }
        
        // 初回だけは固定で「ソコッ！」の音声にする
        if timeCount == 2 {
            AudioUtil.playSound(of: .soko)
            
        }else {
            // 初回以降は「ソコッ！」or「タアッ！」をランダムに再生
            AudioUtil.playSound(of: [Sounds.soko, Sounds.taa].randomElement()!)
        }
        
        // 時間差でデスビームを２連続発射
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.shootTaimeiBullet(index: 1)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.shootTaimeiBullet(index: 2)
        }
    }
        
        // 5回に1回はランダムな座標へ移動させる
        if timeCount % 5 == 0 {
            moveTaimeisanToRandomPosition()
        }
        
        taimeisanPausingType = taimeisanPausingType.toggledValue
        timeCount += 1
        damageLimitCount = 3
    }

    private func changeTaimeisanImage(to type: TaimeisanPausingType) {
        let geometry = taimeisan.geometry
        geometry?.firstMaterial?.diffuse.contents = UIImage(named: "taimeisan_\(type.rawValue).png")
        taimeisan.geometry = geometry!
    }
    
    private func moveTaimeisanToRandomPosition() {
        let ramdomTarget = SCNVector3(x: Float.random(in: -1.5...1.5), y: taimeisan.position.y, z: Float.random(in: -1.5...1.5))
        let action = SCNAction.move(to: ramdomTarget, duration: 3)
        taimeisan.runAction(action)
    }
    
    private func playerKnockedDown() {
        isPlayerKnockedDown = true
        
        // アクアNodeにノックアウトアニメーション＆完了後の処理
//        knockedDownAnimation(to: sceneView.scene.rootNode.childNode(withName: "ChihuahuaParent", recursively: false)!) {
//            print("aquaDowned")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                // コンティニュー選択画面を表示
                self.transitToContinueVC()
            }
//        }
    }
    
    private func taimeisanKnockedDown() {
        isTaimeisanKnockedDown = true
        
        // カメラ目線制約を解除
        taimeisan.constraints?.first?.isEnabled = false
        taimeisanActionTimer.invalidate()
        
        // タイメイさんNodeにノックアウトアニメーション＆完了後の処理
        knockedDownAnimation(to: sceneView.scene.rootNode.childNode(withName: "taimeisan", recursively: false)!) {
                       
            //音楽を6秒間でフェードアウト
            AudioUtil.audioPlayers[.bossBattle]?.setVolume(.zero, fadeDuration: 6)
            
            // 画面を6秒間で白くフェードアウト
            self.showWhiteFadingView()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                // エンディング画面へ遷移
                self.transitToEndingVC()
            }
        }
    }
    
    private func showWhiteFadingView() {
        DispatchQueue.main.async {
            let view = UIView(frame: self.view.frame)
            view.backgroundColor = .white
            view.alpha = 0
            self.view.addSubview(view)
            //画面を白くフェードアウト
            UIView.animate(withDuration: 6) {
                view.alpha = 1
            }
        }
    }

    private func transitToContinueVC() {
//        self.present(ContinueViewController.instantiate(), animated: true)
    }
    
    private func transitToEndingVC() {
//        self.present(EndingViewController.instantiate(), animated: false)
    }
    
    private func shootTaimeiBullet(index: Int) {
        self.addTaimeiBullet(index: index)
        self.animateTaimeiBullet(index: index)
        AudioUtil.playSound(of: .beam)
    }

    
    // MARK: - Setup SceneNode & Particle
    // タイメイさんNodeを設置＆セットアップ
    private func addTaimeisan() {
        let taimeisanScene = SCNScene(named: "Art.scnassets/Taimeisan/taimeisan.scn")!
        taimeisan = taimeisanScene.rootNode.childNode(withName: "taimeisan", recursively: false)!
        let taimeisanGeometry = taimeisan.geometry!
        let taimeisanShape = SCNPhysicsShape(geometry: taimeisanGeometry, options: [SCNPhysicsShape.Option.scale: taimeisan.scale])
        //衝突される側だが動かない様にするため、kinematicを指定（staticだとうまくいかなかった）
        taimeisan.physicsBody = SCNPhysicsBody(type: .kinematic, shape: taimeisanShape)
        taimeisan.physicsBody?.isAffectedByGravity = false
        taimeisan.physicsBody?.contactTestBitMask = 1
        //particleの操作　最初はbirthRate=0にしておく
        taimeisan.childNode(withName: "darkAuraParticle", recursively: false)!.particleSystems!.first!.birthRate = 0

        let cameraPos = sceneView.pointOfView?.position ?? SCNVector3()
        taimeisan.position = SCNVector3(x: cameraPos.x, y: cameraPos.y, z: cameraPos.z - 1.5)
        
        //常にカメラを向く制約
        let billBoardConstraint = SCNBillboardConstraint()
        taimeisan.constraints = [billBoardConstraint]
        
        sceneView.scene.rootNode.addChildNode(taimeisan)
    }
    
    // リモコンに追従させるピストルを設置
    private func addPistolForRemoCon() {
        let pistolScene = SCNScene(named: "Art.scnassets/Weapon/RemoConPistol/remoConPistol.scn")!
        remoConPistolParentNode = pistolScene.rootNode.childNode(withName: "pistolParent", recursively: false)!
        sceneView.scene.rootNode.addChildNode(remoConPistolParentNode)
    }
    
    //プレイヤーへの攻撃当たり判定用Nodeを設置＆セットアップ
    private func addCameraSphere() {
        let sphere: SCNGeometry = SCNSphere(radius: 0.07)
        
        sphere.firstMaterial?.diffuse.contents = UIColor.clear
        let cameraSphere = SCNNode(geometry: sphere)
        cameraSphere.name = "cameraSphere"
        cameraSphere.scale = SCNVector3(x: 1, y: 1, z: 1)

        cameraSphere.position = sceneView.pointOfView!.position
        
        //当たり判定用のphysicBodyを追加
        let shape = SCNPhysicsShape(geometry: sphere, options: [SCNPhysicsShape.Option.scale: cameraSphere.scale])
        cameraSphere.physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
        cameraSphere.physicsBody?.contactTestBitMask = 1
        cameraSphere.physicsBody?.isAffectedByGravity = false
        
        sceneView.scene.rootNode.addChildNode(cameraSphere)
    }
    
    //デスビームNodeを設置＆セットアップ
    private func addTaimeiBullet(index: Int) {
        let sphere: SCNGeometry = SCNSphere(radius: 0.07)

        sphere.firstMaterial?.diffuse.contents = UIColor.clear
        
        taimeiBulletNode = SCNNode(geometry: sphere)
        let scene = SCNScene(named: "Art.scnassets/ParticleSystem/deathBall.scn")!

        taimeiBulletNode?.addChildNode(scene.rootNode.childNode(withName: "deathBall", recursively: false)!)
        guard let bulletNode = taimeiBulletNode else {return}
        bulletNode.name = "taimeiBullet\(index)"
        bulletNode.scale = SCNVector3(x: 1, y: 1, z: 1)

        bulletNode.position = SCNVector3(x: taimeisan.position.x + 0.1, y: taimeisan.position.y + 0.3, z: taimeisan.position.z)
        
        //当たり判定用のphysicBodyを追加
        let shape = SCNPhysicsShape(geometry: bulletNode.geometry!, options: [SCNPhysicsShape.Option.scale: bulletNode.scale])
        bulletNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
        bulletNode.physicsBody?.contactTestBitMask = 1
        bulletNode.physicsBody?.isAffectedByGravity = false
        
        sceneView.scene.rootNode.addChildNode(bulletNode)
    }
    
    // タイメイさんのダークオーラParticleを表示
    private func showDarkAuraParticle() {
        self.taimeisan.childNode(withName: "darkAuraParticle", recursively: false)!.particleSystems!.first!.birthRate = 5000
        self.taimeisan.childNode(withName: "darkAuraParticle", recursively: false)!.particleSystems!.first!.blendMode = .screen
    }
    
    // MARK: - Scene Animation
    //デスビームを発射
    private func animateTaimeiBullet(index: Int) {
        let camera = sceneView.pointOfView!.position
        
        let action = SCNAction.move(to: camera, duration: TimeInterval(1))

        taimeiBulletNode?.runAction(action, completionHandler: {
            self.sceneView.scene.rootNode.childNode(withName: "taimeiBullet\(index)", recursively: false)?.removeFromParentNode()
        })
    }
    
    private func knockedDownAnimation(to fighterNode: SCNNode, completion: @escaping () -> Void) {
        let downAnimation = SCNAction.rotateBy(x: (.pi) / 4, y: 0, z: 0, duration: 1)
        fighterNode.runAction(downAnimation, completionHandler: {
            completion()
        })
    }
    
    
    // MARK: - UIView Animation
    // 画面に表示される「KO」という画像をアニメーション
    private func KO_Animation() {
        AudioUtil.playSound(of: .KO)
        
        self.koImage.alpha = 0
        self.koImage.isHidden = false
        UIView.animate(withDuration: 1, delay: 0) {
            self.koImage.alpha = 1
            self.koImage.bounds.size.width *= 0.7
            self.koImage.bounds.size.height *= 0.7
        } completion: { (Bool) in
            UIView.animate(withDuration: 1, delay: 3) {
                self.koImage.alpha = 0
            }
        }
    }
    
}

extension GameViewController: ARSCNViewDelegate {
    //MARK: - 常に更新され続けるdelegateメソッド
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        switch DeviceTypeHolder.shared.type {
        case .main:
            // ゴーグル内の端末位置に設置してる当たり判定用のノードをカメラ位置に移動させ続ける
            if let cameraSphere = sceneView.scene.rootNode.childNode(withName: "cameraSphere", recursively: false) {
                cameraSphere.position = sceneView.pointOfView!.position
            }
        case .remoCon:
            //現在表示中の武器をラップしている空のオブジェクトを常にカメラと同じPositionに移動させ続ける
//            keepWeaponInFPSPosition()
            guard let camera = sceneView.pointOfView else {
                return
            }
            let entity = SceneNodeUtil.createRemoConInfoEntity(from: camera)
            let data: Data = try! JSONEncoder().encode(entity)
            BeerKit.sendEvent("remoConInfoInMap", data: data)
        default:
            break
        }
    }
}

extension GameViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch frame.worldMappingStatus {
        case .extending, .mapped:
            if isWorldMapSent { return }
            print("十分にマップされたのでイベント送信で他のデバイスに共有する")
            sendWorldMapToOtherDevices()
            isWorldMapSent = true
        default:
            break
        }
    }
}

extension GameViewController: SCNPhysicsContactDelegate {
    //MARK: - 衝突検知時に呼ばれる
    //MEMO: - このメソッド内でUIの更新を行いたい場合はmainThreadで行う
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        if isCollisionOccuredBetweenPlayerAndTaimeisan(nodeA: contact.nodeA,
                                                     nodeB: contact.nodeB) {
            handleAttackToTaimeisan(nodeA: contact.nodeA, nodeB: contact.nodeB)
        }
        
        if isCollisionOccuredBetweenTaimeiBulletAndCamera(nodeA: contact.nodeA,
                                                     nodeB: contact.nodeB) {
            handleAttackToCamera(nodeA: contact.nodeA, nodeB: contact.nodeB)
        }
    }
}

