//
//  Device.swift
//  PianoNote
//
//  Created by 김경록 on 2018. 3. 22..
//  Copyright © 2018년 piano. All rights reserved.
//

import UIKit

extension Int {
    
    /// 375 해상도를 기준하고 있는 point를 각 해상도에 맞게 변환한다.
    var fit: CGFloat {
        var size = UIScreen.main.bounds.width
        if size > UIScreen.main.bounds.height {size = UIScreen.main.bounds.height}
        size = (size < 414) ? size : 414
        return size * (CGFloat(self) / 375)
    }
    
}

extension Double {
    
    /// 375 해상도를 기준하고 있는 point를 각 해상도에 맞게 변환한다.
    var fit: CGFloat {
        var size = UIScreen.main.bounds.width
        if size > UIScreen.main.bounds.height {size = UIScreen.main.bounds.height}
        size = (size < 414) ? size : 414
        return size * (CGFloat(self) / 375)
    }
    
}

extension NSObject {
    
    /// 최대 제한 width 값. (812)
    var limitWidth: CGFloat {
        return 812
    }
    
    /**
     Device의 가로 세로중 더 작은 방향의 화면크기 값, iPhone의 최대 minSize인
     414를 넘을시엔 기기간 일정비율 유지를 위해서 414를 반환한다.
     */
    var minSize: CGFloat {
        var size = UIScreen.main.bounds.width
        if size > UIScreen.main.bounds.height {size = UIScreen.main.bounds.height}
        return (size < 414) ? size : 414
    }
    
    /// Device의 가로 세로중 더 큰 방향의 화면크기를 반환한다.
    var maxSize: CGFloat {
        var size = UIScreen.main.bounds.width
        if size < UIScreen.main.bounds.height {size = UIScreen.main.bounds.height}
        return size
    }
    
    /// Device의 화면크기를 반환한다.
    var mainSize: CGSize {
        return UIScreen.main.bounds.size
    }
    
    
    /// StatusBar의 높이를 반환한다.
    var statusHeight: CGFloat {
        #if Piano
        return UIApplication.shared.statusBarFrame.height
        #else
        return 0
        #endif
    }
    
    /// NavigationBar의 높이를 반환한다.
    var naviHeight: CGFloat {
        #if Piano
        guard let navigationController = UIWindow.topVC?.navigationController else {return 0}
        let naviFrame = navigationController.navigationBar.frame
        return naviFrame.origin.y + naviFrame.size.height
        #else
        return 0
        #endif
    }
    
    /// ToolBar의 높이를 반환한다.
    var toolHeight: CGFloat {
        #if Piano
        guard let navigationController = UIWindow.topVC?.navigationController else {return 0}
        return navigationController.toolbar.frame.height
        #else
        return 0
        #endif
    }
    
    /// iPhoneX 대응 safeArea Inset값.
    var safeInset: UIEdgeInsets {
        if UIScreen.main.bounds.size == CGSize(width: 375, height: 812) {
            return UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
        } else if UIScreen.main.bounds.size == CGSize(width: 812, height: 375) {
            return UIEdgeInsets(top: 0, left: 44, bottom: 21, right: 44)
        }
        return .zero
    }
    
    /// 기본 input keyboard height.
    var inputHeight: CGFloat {
        #if Piano
        let isPortrait = UIApplication.shared.statusBarOrientation.isPortrait
        let screenSize = [UIScreen.main.bounds.width, UIScreen.main.bounds.height]
        if screenSize.contains(568) { // 5
            return isPortrait ? 216 : 162
        } else if screenSize.contains(667) { // 8
            return isPortrait ? 216 : 162
        } else if screenSize.contains(736) { // 8+
            return isPortrait ? 226 : 162
        } else if screenSize.contains(812) { // x
            return isPortrait ? 291 : 171
        } else if screenSize.contains(1024) { // pad
            return isPortrait ? 265 : 353
        } else if screenSize.contains(1112) { // pad pro 10.5
            return isPortrait ? 265 : 353
        } else { // pad pro 12.9 (1366)
            return isPortrait ? 328 : 423
        }
        #else
        return 0
        #endif
    }
    
    /**
     Navigation 및 limitWidth를 고려한 safeAreaInset을 반환한다.
     - parameter width : 제한크기에 대한 확인을 진행하려는 width값.
     - returns : 상황이 고려된 inset값.
     */
    func safeArea(from width: CGFloat) -> UIEdgeInsets {
        var inset = safeInset
        let limitInset = (width - limitWidth) / 2
        if limitInset > 0 {
            inset.left += limitInset
            inset.right += limitInset
        }
        return inset
    }
    
    /**
     호출하는 순간의 statusBarOrientation을 참조하여 orientation을 고정/해제한다.
     - parameter lock : 고정여부.
     */
    func device(orientationLock: Bool) {
        #if Piano
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            var orientationMask: UIInterfaceOrientationMask {
                switch UIApplication.shared.statusBarOrientation {
                case .landscapeLeft:
                    return .landscapeLeft
                case .landscapeRight:
                    return .landscapeRight
                default:
                    return .portrait
                }
            }
            appDelegate.orientationLock = orientationLock ? orientationMask : .allButUpsideDown
        }
        #endif
    }
    /*
    
    /**
     Device의 orientation 변화를 감지하고 통지한다.
     - warning : Use unowned or weak for avoid memory leak.
     - parameter completion : 변화된 orientation값.
     */
    func device(orientationDidChange completion: @escaping (UIDeviceOrientation) -> ()) {
        let name = NSNotification.Name.UIDeviceOrientationDidChange
        let notificationRx = NotificationCenter.default.rx.notification(name).takeUntil(rx.deallocated)
        _ = notificationRx.skip(0.5, scheduler: MainScheduler.instance).subscribe { notification in
            switch UIDevice.current.orientation {
            case .portrait, .landscapeLeft, .landscapeRight:
                completion(UIDevice.current.orientation)
            default:
                break
            }
        }
    }
    
    /**
     Device의 keyboard가 올라오려는 순간을 감지하고 통지한다.
     - warning : Use unowned or weak for avoid memory leak.
     - parameter completion : 올라온 keyboard의 height.
     */
    func device(keyboardWillShow completion: @escaping (CGFloat) -> ()) {
        let type = NSNotification.Name.UIKeyboardWillShow
        let notificationRx = NotificationCenter.default.rx.notification(type).takeUntil(rx.deallocated)
        _ = notificationRx.skip(0.5, scheduler: MainScheduler.instance).subscribe {
            if let rect = $0.element?.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect? {
                completion(rect.height)
            } else {
                completion(0)
            }
        }
    }
    
    /**
     Device의 keyboard가 내려간 순간을 감지하고 통지한다.
     - warning : Use unowned or weak for avoid memory leak.
     - parameter completion : 내려간 keyboard의 height.
     */
    func device(keyboardDidHide completion: @escaping (CGFloat) -> ()) {
        let type = NSNotification.Name.UIKeyboardDidHide
        let notificationRx = NotificationCenter.default.rx.notification(type).takeUntil(rx.deallocated)
        _ = notificationRx.skip(0.5, scheduler: MainScheduler.instance).subscribe {
            if let rect = $0.element?.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect? {
                completion(rect.height)
            } else {
                completion(0)
            }
        }
    }
    */
}

