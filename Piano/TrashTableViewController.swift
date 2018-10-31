//
//  TrashTableViewController.swift
//  Piano
//
//  Created by Kevin Kim on 09/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CoreData
import BiometricAuthentication

class TrashTableViewController: UITableViewController {
    weak var storageService: StorageService!
    var resultsController: NSFetchedResultsController<Note> {
        return storageService.local.trashResultsController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        resultsController.delegate = self
        do {
            try resultsController.performFetch()
        } catch {
            print("\(TrashTableViewController.self) \(#function)에서 에러")
        }
        
        let count = resultsController.fetchedObjects?.count ?? 0
        navigationItem.rightBarButtonItem?.isEnabled = count != 0
//        navigationController?.navigationBar.backgroundColor = UIColor.red
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? TrashDetailViewController,
            let selectedIndexPath = tableView.indexPathForSelectedRow {
            let note = resultsController.object(at: selectedIndexPath)
            des.note = note
            des.storageService = storageService
            return
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return resultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell") as! UITableViewCell & ViewModelAcceptable
        
        let note = resultsController.object(at: indexPath)
        let noteViewModel = NoteViewModel(note: note, viewController: self)
        cell.viewModel = noteViewModel
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle(rawValue: 3) ?? UITableViewCell.EditingStyle.none
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableCell(withIdentifier: "HeaderCell")?.contentView
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 65.5
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let note = resultsController.object(at: indexPath)
        let content = note.content ?? ""
        let isLocked = content.contains(Preference.lockStr)
        let trashAction = UIContextualAction(style: .normal, title:  "🗑", handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            
            if isLocked {
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                    // authentication success
                    self.storageService.local.remove(note: note) {}
                    self.transparentNavigationController?.show(message: "You can restore notes in 30 days.🗑👆".loc)
                    return
                }) { (error) in
                    BioMetricAuthenticator.authenticateWithPasscode(reason: "", success: {
                        // authentication success
                        self.storageService.local.remove(note: note) {}
                        self.transparentNavigationController?.show(message: "You can restore notes in 30 days.🗑👆".loc)
                        return
                    }) { (error) in
                        
                        Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                        return
                    }
                }
            } else {
                self.storageService.local.purge(notes: [note]) {}
                return
            }
            
        })
        trashAction.backgroundColor = Color.white
        
        
        return UISwipeActionsConfiguration(actions: [trashAction])
    }
    
    internal func noteViewModel(indexPath: IndexPath) -> NoteViewModel {
        let note = resultsController.object(at: indexPath)
        return NoteViewModel(note: note, viewController: self)
    }
}

extension TrashTableViewController {
    
    @IBAction func deleteAll(_ sender: UIBarButtonItem) {
        Alert.deleteAll(from: self) { [weak self] in
            guard let self = self else { return }
            self.storageService.local.purgeAll() { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    (self.navigationController as? TransParentNavigationController)?.show(message: "📝Notes are all deleted🌪".loc, color: Color.trash)
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                }
                
            }
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension TrashTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.sync {
            tableView.beginUpdates()
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.sync {
            tableView.endUpdates()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        DispatchQueue.main.sync {
            switch type {
            case .delete:
                guard let indexPath = indexPath else { return }
                self.tableView.deleteRows(at: [indexPath], with: .automatic)

            case .insert:
                guard let newIndexPath = newIndexPath else { return }
                self.tableView.insertRows(at: [newIndexPath], with: .automatic)

            case .update:
                guard let indexPath = indexPath,
                    let note = controller.object(at: indexPath) as? Note,
                    var cell = self.tableView.cellForRow(at: indexPath) as? UITableViewCell & ViewModelAcceptable else { return }
                cell.viewModel = NoteViewModel(note: note, viewController: self)

            case .move:
                guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
                self.tableView.moveRow(at: indexPath, to: newIndexPath)
            }
        }
    }
}
