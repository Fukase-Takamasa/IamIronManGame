//
//  NotificationModel.swift
//  AquaVSTaimei
//
//  Created by 深瀬 貴将 on 2021/02/06.
//

import Foundation

extension Notification.Name {
    static let arsagaMapNotifyFromScene = Notification.Name("arsagaMapNotifyFromScene")
    static let arsagaMapNotifyFromVC = Notification.Name("arsagaMapNotifyFromVC")
    
    static let sideMenuNotify = Notification.Name("sideMenuNotify")
}

enum ArsagaMapNotifyFromSceneType {
    case introduction
    case firstEvent
    case secondEvent
}
enum ArsagaMapNotifyFromVCType {
    case didEndFirstEvent
    case didEndSecondEvent
}

enum SideMenuNotifyType {
    case moveScene
    case changeEvent
    case changeZoom
    case toggleDushMode
}

class NotificationModel {
    
    static func moveAppScene(to scene: AppScenes) {
        NotificationCenter.default.post(name: .sideMenuNotify, object: nil, userInfo: ["type": SideMenuNotifyType.moveScene, "moveTo": scene])
    }
    
    
    
    static func changeEvent(to event: ArsagaMapNotifyFromSceneType) {
        NotificationCenter.default.post(name: .sideMenuNotify, object: nil, userInfo: ["type": SideMenuNotifyType.changeEvent, "event": event])
    }
    static func changeZoom(to mode: ZoomMode) {
        NotificationCenter.default.post(name: .sideMenuNotify, object: nil, userInfo: ["type": SideMenuNotifyType.changeZoom, "mode": mode])
    }
    static func toggleDushMode() {
        NotificationCenter.default.post(name: .sideMenuNotify, object: nil, userInfo: ["type": SideMenuNotifyType.toggleDushMode])
    }
   
}
