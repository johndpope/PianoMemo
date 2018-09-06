//
//  MainNSViewController.swift
//  LightMac
//
//  Created by hoemoon on 05/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Cocoa

class MainNSViewController: NSViewController {
    @IBOutlet weak var collectionView: NSCollectionView!
    weak var persistentContainer: NSPersistentContainer!

    var dummy = [Note]()

    lazy var mainContext: NSManagedObjectContext = {
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        return context
    }()

    lazy var backgroundContext: NSManagedObjectContext = {
        return persistentContainer.newBackgroundContext()
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        persistentContainer = (NSApplication.shared.delegate as! AppDelegate).persistentContainer
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self

        for _ in 1...5 {
            let note = Note(context: mainContext)
            note.content = "Curabitur blandit tempus porttitor."
            dummy.append(note)
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

extension MainNSViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return dummy.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        if let cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NoteCell"), for: indexPath) as? NoteCell {
            cell.note = dummy[indexPath.item]
            return cell
        }
        return NSCollectionViewItem()
    }
}
