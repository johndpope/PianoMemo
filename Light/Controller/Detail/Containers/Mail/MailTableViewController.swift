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
    private var fetchedMail = [[String : [Mail]]]()
    
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
        
    }
    
    func startFetch() {
        
    }
    
}

extension MailTableViewController {
    
    private func fetch() {
        DispatchQueue.global().async {
            self.request()
        }
    }
    
    private func request() {
        guard let mailCollection = note?.mailCollection?
            .sorted(by: {($0 as! Mail).date! > ($1 as! Mail).date!})
            .sorted(by: {($0 as! Mail).label! < ($1 as! Mail).label!})else {return}
        fetchedMail.removeAll()
        mailCollection.map({$0 as! Mail}).forEach { mail in
            if let index = fetchedMail.index(where: {$0.keys.first == mail.label!}) {
                fetchedMail[index][mail.label!]?.append(mail)
            } else {
                fetchedMail.append([mail.label! : [mail]])
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
}

extension MailTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedMail.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedMail[section].values.first?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (fetchedMail[section].keys.first ?? "").lowercased().loc
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MailTableViewCell") as! MailTableViewCell
        guard let mail = fetchedMail[indexPath.section].values.first?[indexPath.row] else {return UITableViewCell()}
        cell.configure(mail)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let selectedMail = fetchedMail[indexPath.section].values.first?[indexPath.row] else {return}
        guard let html = selectedMail.html else {return}
        open(with: html)
    }
    
    private func open(with html: String) {
        performSegue(withIdentifier: "MailDetailViewController", sender: html)
    }
    
}
