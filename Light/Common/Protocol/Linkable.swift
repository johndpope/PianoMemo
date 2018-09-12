//
//  Linkable.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 10..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

enum UniversialLink {
    case usage
    case pianist
    case facebook
    case homepage
    case appStore
    
    func openURL(fromVC viewController: ViewController) {
        switch self {
        case .facebook:
            //TODO: 이거 앱 링크로 바꿔야 함
            let facebookStr = "https://www.facebook.com/OurLovePiano/"
            guard let url = URL(string: facebookStr) else { return }
            Application.shared.open(url, options: [:], completionHandler: nil)
        case .pianist:
            //TODO: 피아니스트 화면 열어주기
            ()
        case .usage:
            //TODO: 사용법 화면 열어주기
            ()
        case .homepage:
            let homepageStr = "https://www.pianonoteapp.com"
            guard let url = URL(string: homepageStr) else { return }
            Application.shared.open(url, options: [:], completionHandler: nil)
            
        case .appStore:
            //TODO: 앱 링크 여기에 적기
            let appStoreStr = ""
            guard let url = URL(string: appStoreStr) else { return }
            Application.shared.open(url, options: [:], completionHandler: nil)
        }
        
    }
    
    var string: String {
        switch self {
        case .facebook:
            return "페이스북"
        case .pianist:
            return "피아니스트"
        case .usage:
            return "사용법"
        case .homepage:
            return "홈페이지"
        case .appStore:
            return "리뷰남기기"
        }
    }
}

protocol Linkable {
    var link: UniversialLink { get set }
}
