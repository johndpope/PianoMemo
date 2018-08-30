//
//  MailTableVC_Action.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension MailTableViewController {
    
    enum MailType: Int {
        case receive = 0
        case send
    }
    
    @IBAction func switchSegment(_ sender: SegmentControl) {
        guard let type = MailType(rawValue: sender.selectedSegmentIndex) else { return }
        
        switch type {
        case .receive:
            //TODO: 테이블 뷰 받은메일로 리로드
            ()
        case .send:
            //TODO: 테이블 뷰 보낸메일로 리로드
            ()
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func add(_ sender: Any) {
        //TODO: 연결할 메일 리스트 바로 띄워주기
    }
    
    
}
