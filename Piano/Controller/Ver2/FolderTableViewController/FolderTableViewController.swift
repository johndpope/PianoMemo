//
//  FolderTableViewController.swift
//  Piano
//
//  Created by Kevin Kim on 25/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

//Mockup Data
struct MockFolder {
    let emojiStr: String
    let name: String
    let noteCount: Int
}

//개발자는 디비에서 다음 두가지만 하면 된다.
//upload
//sync
//


class FolderTableViewController: UITableViewController {
    enum Section: Int {
        case all
        
        case custom
        
        case inTrash
    }
    
    //FetchResultsController로 변경해야함
    //0번째 섹션은 모든 메모
    //1번째 섹션은 커스텀 메모(NSFetchedResultsController가 관여하는 곳)
    //2번째 섹션은 삭제된 메모
    //folderType = 0이면 모든 메모,
    var folders: [MockFolder] = []
    
    deinit {
        print("FolderTableViewController deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        splitViewController?.delegate = self
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        let folder1 = MockFolder(emojiStr: "😍", name: "Piano", noteCount: 10)
        let folder2 = MockFolder(emojiStr: "💀", name: "Business", noteCount: 5)
        folders.append(contentsOf: [folder1, folder2])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? NoteTableViewController,
            let cell = sender as? FolderTableViewCell,
            let indexPath = tableView.indexPath(for: cell) {
            
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == 1 else { return 1 }
        
        return folders.count
        
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: FolderTableViewCell.reuseIdentifier, for: indexPath) as! FolderTableViewCell
        
        switch Section(rawValue: indexPath.section)! {
        case .all:
            cell.nameLabel.text = "모든 메모".loc
            cell.countLabel.text = "20"
            cell.emojiLabel.isHidden = true
            
        case .custom:
            let folder = folders[indexPath.row]
            cell.nameLabel.text = folder.name
            cell.countLabel.text = "\(folder.noteCount)"
            cell.emojiLabel.text = folder.emojiStr
            cell.emojiLabel.isHidden = false
        case .inTrash:
        
            cell.nameLabel.text = "삭제된 메모".loc
            cell.countLabel.text = "0"
            cell.emojiLabel.isHidden = true
        }
        

        return cell
    }
    

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return indexPath.section == 1
    }
 

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

