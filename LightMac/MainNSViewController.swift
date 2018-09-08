//
//  MainNSViewController.swift
//  LightMac
//
//  Created by hoemoon on 05/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Cocoa

class MainNSViewController: NSViewController {
    @IBOutlet weak var collectionView: MainCollectionView!
    weak var persistentContainer: NSPersistentContainer!

    @objc let managedContext: NSManagedObjectContext

    required init?(coder: NSCoder) {
        managedContext = (NSApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        super.init(coder: coder)
    }

    lazy var backgroundContext: NSManagedObjectContext = {
        return persistentContainer.newBackgroundContext()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        let cell = NSNib(nibNamed: NSNib.Name(rawValue: "NoteCell"), bundle: nil)
        collectionView.register(cell, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NoteCell"))
        collectionView.delegate = self
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

extension MainNSViewController: NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return NSSize(width: 200, height: 300)
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        
    }
}

extension MainNSViewController {
    func saveIfneed() {
        if !managedContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if managedContext.hasChanges {
            do {
                try managedContext.save()
            } catch {
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    private func setupDummy() {
        for _ in 1...5 {
            let note = Note(context: managedContext)
            note.content = "Curabitur blandit tempus porttitor."
        }
        saveIfneed()
    }
}
