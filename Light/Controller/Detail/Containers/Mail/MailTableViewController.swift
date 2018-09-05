//
//  MailTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class MailTableViewController: UITableViewController {
    
    private var note: Note? {
        return (navigationController?.parent as? DetailViewController)?.note
    }
    private var fetchedMail = [Mail]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetch()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let mailDetailVC = segue.destination as? MailDetailViewController {
            mailDetailVC.html = sender as? String
        }
    }
    
}

extension MailTableViewController: ContainerDatasource {
    
    func reset() {
        fetchedMail = []
        tableView.reloadData()
    }
    
    func startFetch() {
        
    }
    
}

extension MailTableViewController {
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    private func request() {
        guard let mailCollection = note?.mailCollection?.sorted(by: {
            ($0 as! Mail).linkedDate! < ($1 as! Mail).linkedDate!}) else {return}
        fetchedMail = mailCollection.map({$0 as! Mail}).reversed()
    }
    
}

extension MailTableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedMail.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MailTableViewCell") as! MailTableViewCell
        cell.configure(fetchedMail[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let html = fetchedMail[indexPath.row].html else {return}
        open(with: html)
    }
    
    private func open(with html: String) {
        performSegue(withIdentifier: "MailDetailViewController", sender: html)
    }
    
}
