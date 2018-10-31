//
//  MergeTableViewController.swift
//  Piano
//
//  Created by Kevin Kim on 04/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CoreData
import BiometricAuthentication

class MergeTableViewController: UITableViewController {
    weak var storageService: StorageService!
    var originNote: Note!
    weak var detailVC: DetailViewController?
    
    var collapseDetailViewController: Bool = true
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    private var collectionables: [[Collectionable]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEditing(true, animated: false)
        clearsSelectionOnViewWillAppear = true
        
        collectionables.append([originNote])
        collectionables.append([])
        collectionables.append(storageService.local.mergeables(originNote: originNote))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? MergeDetailViewController,
            let note = sender as? Note {
            des.note = note
            des.storageService = storageService
        }
    }
    
    @IBAction func tapCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapDone(_ sender: Any) {
        //첫번째 노트에 나머지 노트들을 붙이기
        
        if let deletes = collectionables[1] as? [Note] {
            let lockNote = deletes.first { $0.isLocked }
        
            if let _ = lockNote {
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                    [weak self] in
                    // authentication success
                    guard let self = self else { return }
                    self.storageService.local.merge(origin: self.originNote, deletes: deletes, completion: {
                        DispatchQueue.main.async {
                            self.dismiss(animated: true, completion: nil)
                            self.detailVC?.needsToUpdateUI = true
                            self.detailVC?.transparentNavigationController?
                                .show(message: "Merge succeeded 🙆‍♀️".loc, color: Color.blueNoti)
                        }
                    })
                    return
                }) { (error) in
                    BioMetricAuthenticator.authenticateWithPasscode(reason: "", success: {
                        [weak self] in
                        // authentication success
                        guard let self = self else { return }
                        self.storageService.local.merge(origin: self.originNote, deletes: deletes, completion: {
                            DispatchQueue.main.async {
                                self.dismiss(animated: true, completion: nil)
                                self.detailVC?.needsToUpdateUI = true
                                self.detailVC?.transparentNavigationController?
                                    .show(message: "Merge succeeded 🙆‍♀️".loc, color: Color.blueNoti)
                            }
                        })
                        return
                    }) { (error) in
                        Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                        return
                    }
                }
            } else {
                storageService.local.merge(origin: originNote, deletes: deletes) {
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.dismiss(animated: true, completion: nil)
                        self.detailVC?.needsToUpdateUI = true
                        self.detailVC?.transparentNavigationController?
                            .show(message: "Merge succeeded 🙆‍♀️".loc, color: Color.blueNoti)
                    }
                }
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Current Note".loc
        } else if section == 1 {
            return "Notes to Merge".loc
        } else if section == 2 {
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
        } else if indexPath.section == 2{
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
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let note = collectionables[indexPath.section][indexPath.row] as? Note else { return }
        performSegue(withIdentifier: "MergeDetailViewController", sender: note)
    }
 
}
