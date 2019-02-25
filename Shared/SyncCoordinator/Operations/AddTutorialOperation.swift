//
//  AddTutorialOperation.swift
//  Piano
//
//  Created by hoemoon on 17/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData

/// 튜토리얼을 생성합니다.
class AddTutorialOperation: AsyncOperation {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    override func main() {
        guard KeyValueStore.default.bool(forKey: "didAddTutorials") == false else {
            self.state = .Finished
            return
        }
        context.perform { [weak self] in
            guard let self = self else { return }
            if Note.count(in: self.context) == 0 {
                self.context.createLocally(content: "5. How to add the schedules\n♩ Write down the time/details to add your schedules.\n✷ Ex: Meeting with Cocoa at 3 pm\n✷ When you write something after using shortcut keys and putting a spacing, you can also add it on reminder.\n✷ Ex: -To buy iPhone charger.".loc, tags: "")
                self.context.createLocally(content: "4. How to use Emoji List\n♩ Use the shortcut keys (-,* etc), and put a space to make it list.\n✷ Both shortcut keys and emoji can be modified in the Customized List of the settings.".loc, tags: "")
                self.context.createLocally(content: "3. How to highlight\n♩ Click the ‘Highlighter’ button below.\n✷ Slide the texts you want to highlight from left to right.\n✷ When you slide from right to left, the highlight will be gone.\n✷ Go to “How to use” in Setting to see further information.".loc, tags: "")
                self.context.createLocally(content: "2. How to tag with Memo\n♩ On any memo, tap and hold the tag to paste it into the memo you want to tag with.\n✷ If you'd like to un-tag it, paste the same tag back into the memo.\n✷ Go to “How to use” in Setting to see further information.".loc, tags: "")
                self.context.createLocally(content: "1. The quickest way to copy the text\n♩ slide texts to the left side to copy them\n✷ Tap Select on the upper right, and you can copy the text you like.\n✷ Click “Convert” on the bottom right to send the memo as Clipboard, image or PDF.\n✷ Go to “How to use” in Navigate to see further information.".loc, tags: "")
                KeyValueStore.default.set(true, forKey: "didAddTutorials")
            }
            self.state = .Finished
        }
    }
}
