//
//  BlockTableViewController.swift
//  Piano
//
//  Created by Kevin Kim on 16/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

//TODO: TextViewDidChange에서 데이터 소스에 저장 안했을 때 발생하는 문제가 있을까?
//엔드에디팅일 때 저장하면 되는 거 아닌가? 어차피 화면을 떠나든, 앱이 종료되든, endEditing이 호출되고 그다음 저장될 것이므로. -> 확인해보자.
//정규식을 활용해서

class BlockTableViewController: UITableViewController {
    enum BlockTableState {
        case normal
        case typing
        case editing
        case piano
        case trash
    }
    
    internal var note: Note!
    internal var noteHandler: NoteHandlable!
    internal var state: BlockTableState = .normal {
        didSet {
            //toolbar setup
            
        }
    }
    private var baseString = ""
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        guard noteHandler != nil else { return }
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        setFirstCellBecomeResponderIfNeeded()
        unRegisterAllNotifications()
//        saveNoteIfNeeded()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

   

}

extension BlockTableViewController {
    private func setup() {
        setupForMerge()
        setBackgroundViewForTouchEvent()
    }
    
    private func setBackgroundViewForTouchEvent(){
        
        let view = UIView()
        view.backgroundColor = .clear
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapBackground(_:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        self.tableView.backgroundView = view
    }
    
    @IBAction func tapBackground(_ sender: UITapGestureRecognizer) {
        
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
//        DispatchQueue.main.sync {
//            guard let their = note?.content,
//                let first = pianoEditorView.dataSource.first else { return }
//
//            let mine = first.joined(separator: "\n")
//            guard mine != their else {
//                baseString = mine
//                return
//            }
//            let resolved = Resolver.merge(
//                base: baseString,
//                mine: mine,
//                their: their
//            )
//
//            let newComponents = resolved.components(separatedBy: .newlines)
//            pianoEditorView.dataSource = []
//            pianoEditorView.dataSource.append(newComponents)
//            pianoEditorView.tableView.reloadData()
//
//            baseString = resolved
//        }
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
