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
    @IBOutlet weak var inputTextView: NSTextView!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet var arrayController: NSArrayController!
    weak var persistentContainer: NSPersistentContainer!

    @objc var managedContext: NSManagedObjectContext!

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
        collectionView.menuDelegate = self
    }

    @IBAction func createNote(_ sender: Any) {
        guard inputTextView.string.count > 0 else { return }
        let note = Note(context: managedContext)
        note.createdDate = Date()
        note.modifiedDate = Date()
        note.content = inputTextView.string

        arrayController.addObject(note)
        try? arrayController.managedObjectContext?.save()
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

extension MainNSViewController: CollectionViewMenuDelegate {
    func removeNote(at index: Int) {
        arrayController.remove(atArrangedObjectIndex: index)
        try? arrayController.managedObjectContext?.save()
    }
}
