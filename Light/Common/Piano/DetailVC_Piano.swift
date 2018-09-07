//
//  DetailVC_Piano.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 4..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension DetailViewController {
    internal func setupForPiano() {
        guard let pianoView = pianoView,
            let pianoControl = textView.pianoControl,
            let navView = navigationController?.view else { return }
        
        //네비게이션 바 상태 바꿔주고
        setNavigationBar(state: .piano)
        
        //텍스트뷰 세팅해주고
        textView.setupStateForPiano()
        
        //붙여주고
        pianoView.attach(on: navView)
        pianoControl.attach(on: textView)
        
        //연결하기
        connect(pianoView: pianoView, pianoControl: pianoControl, textView: textView)
    }
    
    internal func setupForNormal() {
        setNavigationBar(state: .normal)
        pianoView?.removeFromSuperview()
        textView.cleanPiano()
    }
}

extension DetailViewController {
    internal func connect(pianoView: PianoView, pianoControl: PianoControl, textView: DynamicTextView) {
        pianoControl.textView = textView
        pianoControl.pianoView = pianoView
    }
    
    internal var pianoView: PianoView? {
        return navigationController?.view.createSubviewIfNeeded(PianoView.self)
    }
}
