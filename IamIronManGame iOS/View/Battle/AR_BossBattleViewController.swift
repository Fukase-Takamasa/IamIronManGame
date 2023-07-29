//
//  AR_BossBattleViewController.swift
//  AquaVSTaimei
//
//  Created by 深瀬 貴将 on 2020/12/31.
//

import UIKit
import SceneKit
import ARKit
import GTProgressBar

class AR_BossBattleViewController: UIViewController {
  
    private var taimeisan = SCNNode()
    private var chihuahua = SCNNode()
    private var bulletNode: SCNNode?
    
    private var taimeisanActionTimer = Timer()
    private var aquaMoveButtonTimer = Timer()
    private var timeCount = Int()
    private var damageLimitCount = 3
    private var taimeisanPausingType: TaimeisanPausingType = .standing
    
    private var taimeisanLifePoint = 100.0
    private var aquaLifePoint = 100.0
    private var aquaSpecailPoint = 0.0
    
    private var isTaimeisanKnockedDown = false
    private var isAquaKnockedDown = false
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var taimeisanLifeBar: GTProgressBar!
    @IBOutlet weak var aquaLifeBar: GTProgressBar!
    @IBOutlet weak var aquaPointBar: GTProgressBar!
    @IBOutlet weak var aquaMoveImage: UIImageView!
    @IBOutlet weak var koImage: UIImageView!
    @IBOutlet weak var aquaMoveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AudioModel.initAudioPlayers()
        
        SceneViewUtil.setupScnView(sceneView,
                                   scnViewDelegate: self,
                                   scnPhysicsContactDelegate: self)
        addChihuahua()
        addTaimeisan()
        setupSwipeGesture()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            AudioModel.playSound(of: .yoro)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showDarkAuraParticle()
            AudioModel.playSound(of: .bossBattle)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            AudioModel.playSound(of: .kakugo)
            self.taimeisanActionTimer = Timer.scheduledTimer(timeInterval: 1.6,
                                                             target: self,
                                                             selector: #selector(self.taimeisanActionTimerUpdated(timer:)),
                                                             userInfo: nil,
                                                             repeats: true
            )
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run(ARWorldTrackingConfiguration())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        taimeisanActionTimer.invalidate()
        aquaMoveButtonTimer.invalidate()
        AudioModel.initAudioPlayers()
    }
    
    @IBAction func showSideMenu(_ sender: Any) {
        self.present(SideMenuVC.instantiate(), animated: true)
    }
    
    private func isCollisionOccuredBetweenAquaAndTaimeisan(nodeA: SCNNode, nodeB: SCNNode) -> Bool {
        return (nodeA.name == "taimeisan" && nodeB.name == "Chihuahua") || (nodeB.name == "taimeisan" && nodeA.name == "Chihuahua")
    }
    
    private func isCollisionOccuredBetweenBulletAndCamera(nodeA: SCNNode, nodeB: SCNNode) -> Bool {
        return (nodeA.name!.contains("bullet") && nodeB.name == "cameraSphere") || (nodeB.name!.contains("bullet") && nodeA.name == "cameraSphere")
    }
    
    private func handleAttackToTaimeisan() {
        guard !isTaimeisanKnockedDown else {
            print("タイメイさんが既にダウンしているので、return")
            return
        }
        
        AudioModel.playSound(of: .besi)
        AudioModel.playSound(of: [Sounds.uu, Sounds.kuo].randomElement()!)
                   
        // 連続攻撃を制御（1.6秒の間に3回まで)
        if damageLimitCount <= 0 { return }
        
        var damege = 2.0
        if chihuahua.childNode(withName: "aquaMoveFire", recursively: false) != nil {
            print("aquaMove発動中なので攻撃力を3倍にします")
            damege *= 3
        }
        
        taimeisanLifePoint -= damege
        print("taimeisanHP: \(taimeisanLifePoint)")
        
        DispatchQueue.main.async {
            self.taimeisanLifeBar.animateTo(progress: CGFloat(self.taimeisanLifePoint / 100)) {
                print("taimeisanProgress: \(self.taimeisanLifeBar.progress)")
                
                if self.taimeisanLifeBar.progress <= 0.3 {
                    AudioModel.playSound(of: .karadaga)
                }
                
                if self.taimeisanLifeBar.progress <= 0.0 {
                    AudioModel.playSound(of: .guaaa)
                    
                    self.KO_Animation()
                    self.taimeisanKnockedDown()
                }
            }
        }
        damageLimitCount -= 1
    }
    
    private func handleAttackToCamera(nodeA: SCNNode, nodeB: SCNNode) {
        guard !isAquaKnockedDown else {
            print("アクアが既にダウンしているので、return")
            return
        }
        
        if chihuahua.childNode(withName: "aquaMoveFire", recursively: false) != nil {
            print("aquaMove発動中は自身へのダメージを無効化します。")
            return
        }
        
        AudioModel.playSound(of: .aquaDamage)

        nodeA.name!.contains("bullet") ? nodeA.removeFromParentNode() : nodeB.removeFromParentNode()
        
        aquaLifePoint -= 10
        
        DispatchQueue.main.async {
            self.aquaLifeBar.animateTo(progress: CGFloat(self.aquaLifePoint / 100)) {
                if self.aquaLifeBar.progress == 0.0 {
                    self.KO_Animation()
                    self.aquaKnockedDown()
                }
            }
        }
    }
    
    @objc func taimeisanActionTimerUpdated(timer: Timer) {
        // タイメイさんのポージングタイプによってマテリアル表面の画像を切り替え
        changeTaimeisanImage(to: taimeisanPausingType)
        
        // 射撃の構えの時
        if taimeisanPausingType == .shooting {
            // 最初の２秒間は除外
            if timeCount <= 2 { return }
            
            // 初回だけは固定で「ソコッ！」の音声にする
            if timeCount == 2 {
                AudioModel.playSound(of: .soko)
                
            }else {
                // 初回以降は「ソコッ！」or「タアッ！」をランダムに再生
                AudioModel.playSound(of: [Sounds.soko, Sounds.taa].randomElement()!)
            }
            
            // 時間差でデスビームを２連続発射
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.shootBullet(index: 1)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.shootBullet(index: 2)
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
        print("taimeisan移動")
    }
    
    private func aquaKnockedDown() {
        isAquaKnockedDown = true
        
        // アクアNodeにノックアウトアニメーション＆完了後の処理
        knockedDownAnimation(to: sceneView.scene.rootNode.childNode(withName: "ChihuahuaParent", recursively: false)!) {
            print("aquaDowned")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                // コンティニュー選択画面を表示
                self.transitToContinueVC()
            }
        }
    }
    
    private func taimeisanKnockedDown() {
        isTaimeisanKnockedDown = true
        
        // カメラ目線制約を解除
        taimeisan.constraints?.first?.isEnabled = false
        taimeisanActionTimer.invalidate()
        
        // タイメイさんNodeにノックアウトアニメーション＆完了後の処理
        knockedDownAnimation(to: sceneView.scene.rootNode.childNode(withName: "taimeisan", recursively: false)!) {
            print("taimeisanDowned")
                       
            //音楽を6秒間でフェードアウト
            AudioModel.audioPlayers[.bossBattle]?.setVolume(.zero, fadeDuration: 6)
            
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
        self.present(ContinueViewController.instantiate(), animated: true)
    }
    
    private func transitToEndingVC() {
        self.present(EndingViewController.instantiate(), animated: false)
    }
    
    //必殺技 アクアムーブ発動ボタン
    @IBAction func tappedAquaMoveButton(_ sender: Any) {
        self.aquaMoveButton.isHidden = true
        aquaMoveButtonTimer.invalidate()
        
        AudioModel.playSound(of: .kyuiin)

        self.aquaMoveImage.frame.origin.x = -60
        self.aquaMoveImage.alpha = 1
        self.aquaMoveImage.isHidden = false
        UIView.animate(withDuration: 2, delay: 0) {
            self.aquaMoveImage.frame.origin.x = 0
        }
        UIView.animate(withDuration: 0.5, delay: 1.2) {
            self.aquaMoveImage.alpha = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            AudioModel.playSound(of: .aquaMove)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.aquaMoveAnimation1()
        }
    }
    
    private func setupSwipeGesture() {
        let directionList: [UISwipeGestureRecognizer.Direction] = [.up, .left, .right, .down]
        
        for direction in directionList {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipe(gesture:)))
            swipeGesture.direction = direction
            self.view.addGestureRecognizer(swipeGesture)
        }
    }

    // プレイヤーが画面をスワイプした時のアクション
    @objc func swipe(gesture: UISwipeGestureRecognizer) {
        
        AudioModel.playSound(of: .hyun)
        
        // スワイプごとに必殺技のポイントを貯める
        aquaSpecailPoint += 4
        // 必殺技ポイントをゲージのUIに反映
        aquaPointBar.animateTo(progress: CGFloat(aquaSpecailPoint / 100)) {
            // 必殺技ポイントが最大まで貯まった場合
            if self.aquaPointBar.progress == 1.0 {
                // 必殺技発動ボタンを有効化
                self.activateAquaMoveButton()
            }
        }
        // スワイプ方向に応じたアクアの攻撃アニメーションを実行
        rollingAnimation(to: gesture.direction)
    }
    
    private func activateAquaMoveButton() {
        self.aquaSpecailPoint = 0
        self.aquaPointBar.animateTo(progress: CGFloat(self.aquaSpecailPoint / 100))
        
        AudioModel.playSound(of: .aquaPointBarFilled)
        
        self.aquaMoveButton.center.y += 30
        self.aquaMoveButton.alpha = 0
        self.aquaMoveButton.isHidden = false
        
        // 必殺技発動ボタンのUIを設定
        UIView.animate(withDuration: 0.8, delay: 0) {
            self.aquaMoveButton.alpha = 1
            self.aquaMoveButton.center.y -= 30
        } completion: { (_) in
            self.animateAquaMoveButton(timer: self.aquaMoveButtonTimer)

            self.aquaMoveButtonTimer = Timer.scheduledTimer(timeInterval: 1,
                                                            target: self,
                                                            selector: #selector(self.animateAquaMoveButton(timer:)),
                                                            userInfo: nil,
                                                            repeats: true)
        }
    }
    
    private func shootBullet(index: Int) {
        self.addBullet(index: index)
        self.animateBullet(index: index)
        AudioModel.playSound(of: .beam)
    }

    
    // MARK: - Setup SceneNode & Particle
    // アクアNodeを設置＆セットアップ
    private func addChihuahua() {
        let scene = SCNScene(named: "art.scnassets/Chihuahua.scn")!
        //注意:scnのファイル名ではなく、Identity欄のnameを指定する
        chihuahua = (scene.rootNode.childNode(withName: "ChihuahuaParent", recursively: false))!
        
        //当たり判定用のphysicBodyを追加（ラップしているparentではなくchihuahua本体に本体と同じ大きさでつける）
        let geometry = chihuahua.childNode(withName: "Chihuahua", recursively: false)!.geometry!
        let shape = SCNPhysicsShape(geometry: geometry, options: [SCNPhysicsShape.Option.scale: chihuahua.childNode(withName: "Chihuahua", recursively: false)!.scale])
        //チワワも相手も両方とも吹っ飛ばない様にstaticを指定（dynamicにするとチワワがそもそもFPS視点固定から外れちゃう。kinematicだと相手が吹っ飛んでしまう）
        chihuahua.childNode(withName: "Chihuahua", recursively: false)!.physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
        chihuahua.childNode(withName: "Chihuahua", recursively: false)!.physicsBody?.isAffectedByGravity = false
        chihuahua.childNode(withName: "Chihuahua", recursively: false)!.physicsBody?.contactTestBitMask = 1
        
        let billBoardConstraint = SCNBillboardConstraint()
        chihuahua.constraints = [billBoardConstraint]
        
        chihuahua.position = sceneView.pointOfView?.position ?? SCNVector3()
        self.sceneView.scene.rootNode.addChildNode(chihuahua)
    }
    
    // タイメイさんNodeを設置＆セットアップ
    private func addTaimeisan() {
        let taimeisanScene = SCNScene(named: "art.scnassets/taimeisan.scn")!
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
    private func addBullet(index: Int) {
        let sphere: SCNGeometry = SCNSphere(radius: 0.07)

        sphere.firstMaterial?.diffuse.contents = UIColor.clear
        
        bulletNode = SCNNode(geometry: sphere)
        let scene = SCNScene(named: "art.scnassets/deathBall.scn")!

        bulletNode?.addChildNode(scene.rootNode.childNode(withName: "deathBall", recursively: false)!)
        guard let bulletNode = bulletNode else {return}
        bulletNode.name = "bullet\(index)"
        bulletNode.scale = SCNVector3(x: 1, y: 1, z: 1)

        bulletNode.position = SCNVector3(x: taimeisan.position.x + 0.1, y: taimeisan.position.y + 0.3, z: taimeisan.position.z)
        
        //当たり判定用のphysicBodyを追加
        let shape = SCNPhysicsShape(geometry: bulletNode.geometry!, options: [SCNPhysicsShape.Option.scale: bulletNode.scale])
        bulletNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
        bulletNode.physicsBody?.contactTestBitMask = 1
        bulletNode.physicsBody?.isAffectedByGravity = false
        
        sceneView.scene.rootNode.addChildNode(bulletNode)
        print("デスビームを設置")
    }
    
    // アクアムーブParticleを設置＆セットアップ
    private func aquaMoveFire() {
        let aquaMoveFireScene = SCNScene(named: "art.scnassets/aquaMoveFire.scn")!
        let aquaMoveFire = aquaMoveFireScene.rootNode.childNode(withName: "aquaMoveFire", recursively: false)!
        let pos = chihuahua.childNode(withName: "Chihuahua", recursively: false)!.position
        aquaMoveFire.position = SCNVector3(x: pos.x, y: pos.y - 0.5, z: pos.z)
        chihuahua.addChildNode(aquaMoveFire)
    }
    
    // タイメイさんのダークオーラParticleを表示
    private func showDarkAuraParticle() {
        self.taimeisan.childNode(withName: "darkAuraParticle", recursively: false)!.particleSystems!.first!.birthRate = 5000
        self.taimeisan.childNode(withName: "darkAuraParticle", recursively: false)!.particleSystems!.first!.blendMode = .screen
    }
    
    // MARK: - Scene Animation
    //デスビームを発射
    private func animateBullet(index: Int) {
        let camera = sceneView.pointOfView!.position
        
        let action = SCNAction.move(to: camera, duration: TimeInterval(1))

        bulletNode?.runAction(action, completionHandler: {
            self.sceneView.scene.rootNode.childNode(withName: "bullet\(index)", recursively: false)?.removeFromParentNode()
        })
        print("デスビームを発射")
    }
    
    private func aquaMoveAnimation1() {
        self.aquaMoveFire()
        
        sceneView.scene.rootNode.childNode(withName: "ChihuahuaParent", recursively: false)?.childNode(withName: "Chihuahua", recursively: false)!.scale = SCNVector3(x: 0.12, y: 0.12, z: 0.12)
        let action = SCNAction.rotateBy(x: 109.15182334904944, y: -236.750350984048, z: 6.912948832203824, duration: 0.1)
        let repe = SCNAction.repeat(action, count: 60)
        sceneView.scene.rootNode.childNode(withName: "ChihuahuaParent", recursively: false)?.childNode(withName: "Chihuahua", recursively: false)!.runAction(repe, completionHandler: {
            print("aquaMoveAnimation")

            self.chihuahua.removeFromParentNode()
            self.chihuahua.childNode(withName: "aquaMoveFire", recursively: false)?.removeFromParentNode()
            
            self.addChihuahua()
        })
    }
    
    private func rollingAnimation(to direction: UISwipeGestureRecognizer.Direction) {
        var action = SCNAction()
        switch direction {
        case .up:
            action = SCNAction.rotateBy(x: -(.pi) * 2, y: 0, z: 0, duration: 0.3)
        case .left:
            action = SCNAction.rotateBy(x: 0, y: -(.pi) * 2, z: (.pi) * 2, duration: 0.3)
        case .right:
            action = SCNAction.rotateBy(x: 0, y: -(.pi) * 2, z: -(.pi) * 2, duration: 0.3)
        case .down:
            action = SCNAction.rotateBy(x: (.pi) * 2, y: 0, z: 0, duration: 0.3)
        default:
            break
        }
        
        sceneView.scene.rootNode.childNode(withName: "ChihuahuaParent", recursively: false)?.childNode(withName: "Chihuahua", recursively: false)!.runAction(action)
    }
    
    private func knockedDownAnimation(to fighterNode: SCNNode, completion: @escaping () -> Void) {
        let downAnimation = SCNAction.rotateBy(x: (.pi) / 4, y: 0, z: 0, duration: 1)
        fighterNode.runAction(downAnimation, completionHandler: {
            completion()
        })
    }
    
    
    // MARK: - UIView Animation
    // 「TapMe！」というボタンにピョコピョコ跳ねるアニメーション
    @objc func animateAquaMoveButton(timer: Timer) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
            self.aquaMoveButton.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        }) { (_) in
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 10, options: .curveEaseOut, animations: {
                self.aquaMoveButton.transform = .identity
                
            }, completion: nil)
        }
    }
    
    // 画面に表示される「KO」という画像をアニメーション
    private func KO_Animation() {
        AudioModel.playSound(of: .KO)
        
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

extension AR_BossBattleViewController: ARSCNViewDelegate {
    //MARK: - 常に更新され続けるdelegateメソッド
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        chihuahua.position = sceneView.pointOfView?.position ?? SCNVector3()
        
        if let cameraSphere = sceneView.scene.rootNode.childNode(withName: "cameraSphere", recursively: false) {
            cameraSphere.position = sceneView.pointOfView!.position
        }
    }
}

extension AR_BossBattleViewController: SCNPhysicsContactDelegate {
    //MARK: - 衝突検知時に呼ばれる
    //MEMO: - このメソッド内でUIの更新を行いたい場合はmainThreadで行う
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        if isCollisionOccuredBetweenAquaAndTaimeisan(nodeA: contact.nodeA,
                                                     nodeB: contact.nodeB) {
            print("タイメイさんとアクアが当たった")
            handleAttackToTaimeisan()
        }
        
        if isCollisionOccuredBetweenBulletAndCamera(nodeA: contact.nodeA,
                                                     nodeB: contact.nodeB) {
            print("デスボールとカメラが当たった")
            handleAttackToCamera(nodeA: contact.nodeA, nodeB: contact.nodeB)
        }
    }
}

