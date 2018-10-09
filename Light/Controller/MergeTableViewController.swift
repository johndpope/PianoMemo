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
    weak var detailVC: DetailViewController?
//    weak var syncController: Synchronizable!
    var originalNote: Note!

    
    var collapseDetailViewController: Bool = true
    private lazy var noteFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "isTrash == false")
        request.sortDescriptors = [sort]
        return request
    }()
    
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    private var collectionables: [[Collectionable]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEditing(true, animated: false)
        clearsSelectionOnViewWillAppear = true
        
        collectionables.append([originalNote])
        collectionables.append([])
        
        //TODO COCOA: 공유된 메모도 병합에 노출이 안되어야합니다.
        if let context = originalNote?.managedObjectContext {
            var notes: [Note] = []
            do {
                let fetchNotes = try context.fetch(noteFetchRequest)
                if originalNote.isLocked {
                   notes = fetchNotes.filter { !$0.isShared }
                } else {
                    notes = fetchNotes.filter { !$0.isShared && !$0.isLocked }
                }
                
            } catch {
                print("\(MergeTableViewController.self) \(#function)에서 에러")
            }
            collectionables.append(notes)
        }
        
        
        
        
//        if let notes = syncController.mergeableNotes(with: originalNote) {
//            if originalNote.isLocked {
//                collectionables.append(notes.filter { $0.isLocked })
//            } else {
//                collectionables.append(notes.filter { !$0.isLocked })
//            }
//        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? DetailViewController,
            let note = sender as? Note {
            des.note = note
            des.state = .merge
        }
    }
    
    @IBAction func tapCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapDone(_ sender: Any) {
        if let deletes = collectionables[1] as? [Note] {
//            syncController.merge(origin: originalNote, deletes: deletes) { [weak self] in
//                self?.dismiss(animated: true, completion: nil)
//                self?.detailVC?.transparentNavigationController?
//                    .show(message: "Merge succeeded 🙆‍♀️".loc, color: Color.merge)
//            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Current Note".loc
        } else if section == 1 {
            return collectionables[section].count != 0 ? "Notes to Merge".loc : nil
        } else if section == 2{
            return "Available notes for Merge".loc
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .insert:
            //섹션 2에 있는 데이터를 섹션 1의 맨 아래로 옮긴다.
            let collectionable = collectionables[indexPath.section].remove(at: indexPath.row)
            collectionables[1].append(collectionable)
            let newIndexPath = IndexPath(row: collectionables[1].count - 1, section: 1)
            tableView.moveRow(at: indexPath, to: newIndexPath)
            
        case .delete:
            let collectionable = collectionables[indexPath.section].remove(at: indexPath.row)
            collectionables[2].insert(collectionable, at: 0)
            let newIndexPath = IndexPath(row: 0, section: 2)
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
        if indexPath.section == 0 {
            return UITableViewCell.EditingStyle.none
        } else if indexPath.section == 1 {
            return UITableViewCell.EditingStyle.delete
        } else if indexPath.section == 2 {
            return UITableViewCell.EditingStyle.insert
        } else {
            return UITableViewCell.EditingStyle.none
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "NoteTableViewCell") as! UITableViewCell & ViewModelAcceptable
        
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
        return indexPath.section == 1
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
        return indexPath.section != 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let note = collectionables[indexPath.section][indexPath.row] as? Note else { return }
        performSegue(withIdentifier: "DetailViewController", sender: note)
    }
    
//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if scrollView.contentOffset.y > 0,
//            scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) {
//
//            if tableView.numberOfRows(inSection: 2) > 90 {
//                noteFetchRequest.fetchLimit += 50
//                do {
//                    let notes = try managedObjectContext.fetch(noteFetchRequest)
//                    collectionables[2] = notes
//                } catch {
//                    print(error.localizedDescription)
//                }
//                tableView.reloadData()
//            }
//        }
//    }
    
}
