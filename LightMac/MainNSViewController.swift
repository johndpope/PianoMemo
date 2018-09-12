//
//  MainNSViewController.swift
//  LightMac
//
//  Created by hoemoon on 10/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Cocoa

class MainNSViewController: NSViewController {
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!

    @objc let backgroundContext: NSManagedObjectContext
    let mainContext: NSManagedObjectContext

    lazy var noteFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedDate", ascending: false)
        request.fetchLimit = 100
        request.sortDescriptors = [sort]
        return request
    }()

    required init?(coder: NSCoder) {
        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
            fatalError()
        }
        backgroundContext = delegate.persistentContainer.newBackgroundContext()
        mainContext = delegate.persistentContainer.viewContext
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.font = NSFont.systemFont(ofSize: 15)
        textView.delegate = self
        tableView.delegate = self
        arrayController.filterPredicate = NSPredicate(value: false)
        setupDummy()
    }
}

extension MainNSViewController {
    func saveIfneed() {
        if !backgroundContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if backgroundContext.hasChanges {
            do {
                try backgroundContext.save()
            } catch {
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    private func setupDummy() {
        guard let notes = try? mainContext.fetch(noteFetchRequest),
            notes.count == 0 else { return }

        for index in 1...50 {
            let note = Note(context: backgroundContext)
            if (index % 2) == 0 {
                note.content = "\(index) Curabitur blandit tempus porttitor."
            } else {
                note.content = "\(index) Maecenas sed diam eget risus varius blandit sit amet non magna."
            }
        }
        saveIfneed()
    }
}

extension MainNSViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? TextView,
            textView.string.count > 0 else {
                arrayController.filterPredicate = NSPredicate(value: false)
                return
        }
        arrayController.filterPredicate = textView.string.predicate(fieldName: "Content")
    }
}

extension MainNSViewController: NSTableViewDelegate {

}
