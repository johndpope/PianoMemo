//
//  NoteViewController.swift
//  Piano
//
//  Created by Kevin Kim on 15/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class NoteViewController: UIViewController {

    var note: Note!
    var baseString = ""
    var pianoEditorView: PianoEditorView!
    var noteHandler: NoteHandlable!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard noteHandler != nil else { return }
        setup()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CATransaction.setCompletionBlock { [weak self] in
            guard let self = self,
                let pianoEditorView = self.pianoEditorView else { return }
            pianoEditorView.setFirstCellBecomeResponderIfNeeded()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
        unRegisterAllNotifications()
        guard let pianoEditorView = pianoEditorView else { return }
        pianoEditorView.saveNoteIfNeeded()
    }

}

extension NoteViewController {
    private func setup() {
        guard let pianoEditorView = view.createSubviewIfNeeded(PianoEditorView.self) else { return }
        view.addSubview(pianoEditorView)
        pianoEditorView.translatesAutoresizingMaskIntoConstraints = false
        pianoEditorView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pianoEditorView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pianoEditorView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pianoEditorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        pianoEditorView.setup(state: .normal, viewController: self, note: note)
        pianoEditorView.noteHandler = noteHandler
        self.pianoEditorView = pianoEditorView

        setupForMerge()

        //        addNotification()

    }

    private func setupForMerge() {
        if let note = note, let content = note.content {
            self.baseString = content
            EditingTracker.shared.setEditingNote(note: note)
        }
    }

    internal func registerAllNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(merge(_:)),
            name: .resolveContent,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(popCurrentViewController),
            name: .popDetail,
            object: nil
        )
    }

    @objc func popCurrentViewController() {
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc private func merge(_ notification: Notification) {
        DispatchQueue.main.sync {
            guard let their = note?.content,
                let first = pianoEditorView.dataSource.first else { return }

            let mine = first.joined(separator: "\n")
            guard mine != their else {
                baseString = mine
                return
            }
            let resolved = Resolver.merge(
                base: baseString,
                mine: mine,
                their: their
            )

            let newComponents = resolved.components(separatedBy: .newlines)
            pianoEditorView.dataSource = []
            pianoEditorView.dataSource.append(newComponents)
            pianoEditorView.tableView.reloadData()

            baseString = resolved
        }
    }

    internal func unRegisterAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    override func encodeRestorableState(with coder: NSCoder) {
        guard let note = note else { return }
        coder.encode(note.objectID.uriRepresentation(), forKey: "noteURI")
        super.encodeRestorableState(with: coder)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        if let url = coder.decodeObject(forKey: "noteURI") as? URL {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.decodeNote(url: url) { note in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        switch note {
                        case .some(let note):
                            self.note = note
                            self.noteHandler = appDelegate.noteHandler
                            self.setup()
                        case .none:
                            self.popCurrentViewController()
                        }
                    }
                }
            }
        }
    }
}
