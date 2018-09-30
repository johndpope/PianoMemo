//
//  RecommandEventView.swift
//  Piano
//
//  Created by Kevin Kim on 20/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKitUI

class RecommandEventView: UIView, RecommandDataAcceptable {
    
    weak var mainViewController: MainViewController?
    @IBOutlet weak var dDayLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var registerButton: UIButton!
    var selectedRange = NSMakeRange(0, 0)
    
    var data: Recommandable? {
        didSet {
            DispatchQueue.main.async { [ weak self] in
                guard let `self` = self else { return }
                
                guard let event = self.data as? EKEvent else {
                    self.isHidden = true
                    return
                }
                
                self.isHidden = false
                
                self.titleLabel.text = event.title.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
                    ? event.title
                    : "제목 없음".loc
                
                if let integer = Date().days(sinceDate: event.startDate) {
                    if integer > 0 {
                        self.dDayLabel.text = "D+\(integer)"
                    } else if integer == 0 {
                        self.dDayLabel.text = "D-Day".loc
                    } else {
                        self.dDayLabel.text = "D\(integer)"
                    }
                }
                
                
                self.startDateLabel.text = DateFormatter.sharedInstance.string(from: event.startDate)
                self.endDateLabel.text = DateFormatter.sharedInstance.string(from: event.endDate)
                self.registerButton.setTitle("터치하여 캘린더에 등록해보세요.", for: .normal)
                
            }
        }
    }
    
    @IBAction func register(_ sender: UIButton) {
        
        guard let vc = mainViewController,
            let event = data as? EKEvent,
            let textView = vc.bottomView.textView else { return }
        selectedRange = textView.selectedRange
        
        Access.eventRequest(from: vc) {
            let eventStore = EKEventStore()
            let newEvent = EKEvent(eventStore: eventStore)
            newEvent.title = event.title
            newEvent.startDate = event.startDate
            newEvent.endDate = event.endDate
            newEvent.calendar = eventStore.defaultCalendarForNewEvents
            
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                
                let vc = EKEventEditViewController()
                vc.eventStore = eventStore
                vc.event = newEvent
                vc.editViewDelegate = self
                self.mainViewController?.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    @objc func finishRegistering(_ textView: TextView) {
        
        
    }
    
    private func deleteParagraphAndAnimateHUD() {
        guard let mainVC = mainViewController,
            let textView = mainVC.bottomView.textView else { return }
        
        let paraRange = (textView.text as NSString).paragraphRange(for: selectedRange)
        textView.textStorage.replaceCharacters(in: paraRange, with: "")
        textView.typingAttributes = Preference.defaultAttr
        mainVC.bottomView.textViewDidChange(textView)
        isHidden = true
        
        let message = "✨일정이 등록되었어요✨".loc
        (mainVC.navigationController as? TransParentNavigationController)?.show(message: message)
    }
}

extension RecommandEventView: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        switch action {
        case .canceled, .deleted:
            controller.dismiss(animated: true, completion: nil)
            mainViewController?.bottomView.textView.becomeFirstResponder()
        case .saved:
            controller.dismiss(animated: true, completion: nil)
            deleteParagraphAndAnimateHUD()
            
        }
    
    }
}
