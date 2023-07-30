//
//  LabelNode.swift
//  IamIronManGame iOS
//
//  Created by 深瀬 on 2023/07/30.
//

import Foundation
import SceneKit

class LabelNode: SCNNode {

    init(text: String, width: CGFloat, textColor: UIColor, panelColor: UIColor, textThickness: CGFloat, panelThickness: CGFloat) {
        super.init()

        //*******************************************************
        // テキストノードの生成
        //*******************************************************
        let str = SCNText(string: text, extrusionDepth: textThickness)
        str.font = UIFont(name: "HiraginoSans-W6", size: 1);
        let textNode = SCNNode(geometry: str)

        // バウンディングボックスから縦横の長さを取得する
        let (min, max) = (textNode.boundingBox)
        let w = CGFloat(max.x - min.x)
        let h = CGFloat(max.y - min.y)
        // 中心になるように移動する
        textNode.position = SCNVector3(-(w/2), -(h/2) - 0.9 , 0.001 + textThickness )
        // 色を設定
        textNode.geometry?.materials.append(SCNMaterial())
        textNode.geometry?.materials.first?.diffuse.contents = textColor

        //*******************************************************
        // パネルノードの生成
        //*******************************************************
        let panelNode = SCNNode(geometry: SCNBox(width: w * 1.1, height: h * 1.1, length: panelThickness, chamferRadius: 0))
        // 色を設定
        panelNode.geometry?.materials.append(SCNMaterial())
        panelNode.geometry?.materials.first?.diffuse.contents = panelColor

        addChildNode(textNode)
        addChildNode(panelNode)
        //*******************************************************
        // サイズを調整する
        //*******************************************************
        let ratio = width / w
        scale = SCNVector3(ratio, ratio, ratio)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
