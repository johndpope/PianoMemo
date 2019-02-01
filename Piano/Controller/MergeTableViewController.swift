//
//  MergeTableViewController.swift
//  Piano
//
//  Created by Kevin Kim on 04/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CoreData

class MergeTableViewController: UITableViewController {
    weak var masterViewController: MasterViewController?
    var noteHandler: NoteHandlable?
    var collapseDetailViewController: Bool = true

    lazy var request: NSFetchRequest<Note> = {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: NoteKey.modifiedAt.rawValue, ascending: false)
        request.predicate = Note.predicateForMerge
        request.sortDescriptors = [sort]
        return request
    }()

    @IBOutlet weak var doneButton: UIBarButtonItem!
    private var collectionables: [[Collectionable]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEditing(true, animated: false)
        clearsSelectionOnViewWillAppear = true

        collectionables.append([])
        guard let noteHandler = noteHandler else { return }
        do {
            let fetched = try noteHandler.context.fetch(request)
            collectionables.append(fetched)
        } catch {
            print(error.localizedDescription)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? MergeDetailViewController,
            let note = sender as? Note {
            des.note = note
        }
    }

    @IBAction func tapCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func tapDone(_ sender: Any) {
        //첫번째 노트에 나머지 노트들을 붙이기
        func merge(with selected: [Note]) {
            guard let noteHandler = noteHandler else { return }
            noteHandler.merge(notes: selected) { [weak self] in
                guard let self = self else { return }
                self.dismiss(animated: true, completion: nil)
                if $0 {
                    self.masterViewController?.transparentNavigationController?
                        .show(message: "Combined Successfully 🙆‍♀️".loc, color: Color.blueNoti)
                }
            }
        }

        if let selected = collectionables[0] as? [Note] {
            let lockNote = selected.first { $0.isLocked }
            switch lockNote {
            case .some:
                let reason = "merge locked note".loc
                Authenticator.requestAuth(reason: reason, success: {
                    merge(with: selected)
                }, failure: { error in
                    
                }, notSet: {
                    merge(with: selected)
                })
            case .none:
                merge(with: selected)
            }
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Notes to Merge".loc
        case 1:
            return collectionables[section].count != 0 ? "Available notes for Merge".loc : nil
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .insert:
            //섹션 2에 있는 데이터를 섹션 1의 맨 아래로 옮긴다.
            let collectionable = collectionables[indexPath.section].remove(at: indexPath.row)
            collectionables[0].append(collectionable)
            let newIndexPath = IndexPath(row: collectionables[0].count - 1, section: 0)
            tableView.moveRow(at: indexPath, to: newIndexPath)

        case .delete:
            let collectionable = collectionables[indexPath.section].remove(at: indexPath.row)
            collectionables[1].insert(collectionable, at: 0)
            let newIndexPath = IndexPath(row: 0, section: 1)
            tableView.moveRow(at: indexPath, to: newIndexPath)
        case .none:
            ()
        }
        doneButton.isEnabled = collectionables[1].count != 0
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Cancel".loc
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        switch indexPath.section {
        case 0:
            return .delete
        case 1:
            return .insert
        default:
            return .none
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell") as! UITableViewCell & ViewModelAcceptable

        let note = collectionables[indexPath.section][indexPath.row] as! Note
        let noteViewModel = NoteViewModel(note: note, viewController: self)
        cell.viewModel = noteViewModel
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collectionables[section].count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return collectionables.count
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let sourceNote = collectionables[sourceIndexPath.section].remove(at: sourceIndexPath.row)
        collectionables[destinationIndexPath.section].insert(sourceNote, at: destinationIndexPath.row)
    }

    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            var row = 0
            if sourceIndexPath.section < proposedDestinationIndexPath.section {
                row = self.tableView(tableView, numberOfRowsInSection: sourceIndexPath.section) - 1
            }
            return IndexPath(row: row, section: sourceIndexPath.section)
        }
        return proposedDestinationIndexPath
    }

    override func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        //TODO: detail2VC를 재사용하고, VCState에 viewer(코멘트만 달 수 있음) 모드 추가하기,
//        guard let note = collectionables[indexPath.section][indexPath.row] as? Note else { return }
//        performSegue(withIdentifier: "MergeDetailViewController", sender: note)
    }

}
