//
//  RecommandEventView.swift
//  Piano
//
//  Created by Kevin Kim on 20/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit

class RecommandEventView: UIView, RecommandDataAcceptable {
    
    weak var mainViewController: MainViewController?
    @IBOutlet weak var dDayLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var registerButton: UIButton!
    

    
    var data: Recommandable? {
        didSet {
            guard let event = data as? EKEvent else { return }
            isHidden = false
            titleLabel.text = event.title
            dDayLabel.text = "TODO"
            startDateLabel.text = DateFormatter.sharedInstance.string(from: event.startDate)
            endDateLabel.text = DateFormatter.sharedInstance.string(from: event.endDate)
            registerButton.titleLabel?.text = "터치하여 캘린더에 등록해보세요."
        }
    }
    
    @IBAction func register(_ sender: UIButton) {
        
        guard let vc = mainViewController,
            let event = data as? EKEvent,
            let textView = vc.bottomView.textView else { return }
        
        Access.eventRequest(from: vc) {
            let eventStore = EKEventStore()
            let newEvent = EKEvent(eventStore: eventStore)
            newEvent.title = event.title
            newEvent.startDate = event.startDate
            newEvent.endDate = event.endDate
            newEvent.calendar = event.calendar
            
            do {
                try eventStore.save(newEvent, span: .thisEvent)
                
                DispatchQueue.main.async {
                    sender.titleLabel?.text = "등록완료"
                }
                
                UIView.animate(withDuration: 0.3, delay: 1, options: [], animations: {
                    self.isHidden = true
                }, completion: nil)
                
                UIView.animate(withDuration: 0.3, delay: 1, options: [], animations: {
                    self.isHidden = true
                }, completion: { (bool) in
                    guard bool else { return }
                    let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
                    textView.textStorage.replaceCharacters(in: paraRange, with: "")
                })
                
                
            } catch {
                print("event를 register에서 저장하다 에러: \(error.localizedDescription)")
            }
            
        }
    }
}
