//
//  MailTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class MailTableViewController: UITableViewController, ContainerDatasource {
    
    private var note: Note? {
        get {
            return (navigationController?.parent as? DetailViewController)?.note
        } set {
            (navigationController?.parent as? DetailViewController)?.note = newValue
        }
    }
    
    private var fetchedData = [Mail]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestFetch()
    }
    
    func reset() {
        
    }
    
    func startFetch() {
        //requestFetch()
    }
    
    private func requestFetch() {
        guard let mailCollection = note?.mailCollection else {return}
        fetchedData = mailCollection.map({$0 as! Mail}).reversed()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedData.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MailTableViewCell") as! MailTableViewCell
        cell.configure(fetchedData[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
}
