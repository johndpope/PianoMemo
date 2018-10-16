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
    
    private weak var viewController: ViewController?
    private weak var textView: TextView?
    
    func setup(viewController: ViewController, textView: TextView) {
        self.viewController = viewController
        self.textView = textView
    }
    
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
                    : "Untitled".loc
                
                if let eventDate = event.startDate {
                    var dDayString = eventDate.dDay
                    if dDayString.contains("-") {
                        dDayString.removeCharacters(strings: ["-"])
                        self.dDayLabel.text = "\(dDayString) " + "ago".loc
                    } else {
                        self.dDayLabel.text = "\(dDayString) " + "left".loc
                    }
                }
                
                self.startDateLabel.text = DateFormatter.sharedInstance.string(from: event.startDate)
                self.endDateLabel.text = DateFormatter.sharedInstance.string(from: event.endDate)
            }
        }
    }
    
    @IBAction func register(_ sender: UIButton) {
        
        guard let viewController = viewController,
            let event = data as? EKEvent,
            let textView = textView else { return }
        selectedRange = textView.selectedRange
        
        Access.eventRequest(from: viewController) {
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
                viewController.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    @objc func finishRegistering(_ textView: TextView) {
        
        
    }
    
    private func deleteParagraphAndAnimateHUD() {
        guard let viewController = viewController,
            let textView = textView,
            selectedRange.location != NSNotFound else { return }
        
        let paraRange = (textView.text as NSString).paragraphRange(for: selectedRange)
        textView.textStorage.replaceCharacters(in: paraRange, with: "")
        textView.typingAttributes = Preference.defaultAttr
        textView.delegate?.textViewDidChange?(textView)
        isHidden = true
        
        let message = "📆 Your schedule is successfully registered✨".loc
        viewController.transparentNavigationController?.show(message: message, color: Color.point)
    }
}

extension RecommandEventView: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        switch action {
        case .canceled, .deleted:
            controller.dismiss(animated: true, completion: nil)
            textView?.becomeFirstResponder()
        case .saved:
            controller.dismiss(animated: true, completion: nil)
            deleteParagraphAndAnimateHUD()
            
        }
    
    }
}
