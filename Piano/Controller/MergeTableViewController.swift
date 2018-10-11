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
    weak var syncController: Synchronizable!
    
    var collapseDetailViewController: Bool = true
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    private var collectionables: [[Collectionable]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEditing(true, animated: false)
        clearsSelectionOnViewWillAppear = true
        
        collectionables.append([])
        
        //TODO COCOA: 공유된 메모는 병합에 노출이 안되어야합니다. 잠금된 메모의 경우, 노출해도 무방합니다.(병합이 메모리스트로 빠져나왔기 때문에 original Note가 의미가 없어져서 병합해도 무방)
        if let notes = syncController.mergeables {
            collectionables.append(notes.filter { !$0.isShared })
        }
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
        //첫번째 노트에 나머지 노트들을 붙이기
        if var merges = collectionables[0] as? [Note] {
//            let fullContent = merges.reduce("") { (result, note) -> String in
//                return result + (note.content ?? "") + "\n"
//            }
            let firstNote = merges.removeFirst()
            let deletes = merges
            syncController.merge(origin: firstNote, deletes: deletes)
            dismiss(animated: true, completion: nil)
//            detailVC?.transparentNavigationController?
//                .show(message: "Merge succeeded 🙆‍♀️".loc, color: Color.merge)

        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Notes to Merge".loc
        } else if section == 1 {
            return collectionables[section].count != 0 ? "Available notes for Merge".loc : nil
        } else {
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
        doneButton.isEnabled = collectionables[0].count != 0
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Cancel".loc
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 0 {
            return UITableViewCell.EditingStyle.delete
        } else if indexPath.section == 1 {
            return UITableViewCell.EditingStyle.insert
        } else {
            return UITableViewCell.EditingStyle.none
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
