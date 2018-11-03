//
//  PianoControl.swift
//  PianoNote
//
//  Created by Kevin Kim on 23/03/2018.
//  Copyright © 2018 piano. All rights reserved.
//

import UIKit

class PianoControl: UIControl {
    
    public weak var textView: BlockTextView?
    public weak var pianoView: PianoView?
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        
        guard let textView = self.textView,
            let pianoView = self.pianoView else { return false }
        
        let trigger = textView.pianoTrigger(touch: touch)
        pianoView.setPianoData(trigger: trigger)
        pianoView.playPiano(at: touch)
        return true
        
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        
        guard let textView = self.textView,
            let pianoView = self.pianoView else { return }
        
        pianoView.endPiano { (results) in
            textView.endPiano(with: results)
        }
        
    }
  
    override func cancelTracking(with event: UIEvent?) {
        
        guard let textView = self.textView,
            let pianoView = self.pianoView else { return }
        
        pianoView.endPiano { (results) in
            textView.endPiano(with: results)
        }
        
    }
    
    
    internal func attach(on textView: TextView) {
        removeFromSuperview()
        
        let point = CGPoint(x: 0, y: textView.contentOffset.y + textView.contentInset.top)
        let size = textView.bounds.size
        frame = CGRect(origin: point, size: size)
        textView.addSubview(self)
    }
    
    internal func detach() {
        removeFromSuperview()
    }

}
