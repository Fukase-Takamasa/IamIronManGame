//
//  NotificationModel.swift
//  AquaVSTaimei
//
//  Created by 深瀬 貴将 on 2021/02/06.
//

import Foundation

extension Notification.Name {
    static let sideMenuNotify = Notification.Name("sideMenuNotify")
}

enum SideMenuNotifyType {
    case moveScene
}

class NotificationModel {
//    static func moveAppScene(to scene: AppScenes) {
//        NotificationCenter.default.post(name: .sideMenuNotify, object: nil, userInfo: ["type": SideMenuNotifyType.moveScene, "moveTo": scene])
//    }
}
