//
//  DetailViewController.swift
//  Piano
//
//  Created by Kevin Kim on 22/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import MobileCoreServices
import EventKitUI

/**
 textViewDidEndEditing에서 데이터 소스에 업로드가 된다. (업로드 될 때에는 뷰의 모든 정보가 키 값으로 변환되어서 텍스트에 저장된다)
 cellForRow에선 단순히 string을 넣어주는 역할만 한다.
 모든 변환은 cell이 하고 있으며
 데이터 인풋인 텍스트뷰가 하고 있다.
 텍스트 안에 있는 키 값들로 효과를 입힌다.
 leading,trailing 액션들을 시행할 경우, 데이터 소스와 뷰가 모두 같이 변한다.
 */

class DetailViewController: UIViewController {

    var note: Note!
    var baseString = ""
    var pianoEditorView: PianoEditorView!
    var noteHandler: NoteHandlable?
//    var timer: Timer!

    @IBOutlet weak var textView: UITextView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerAllNotifications()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if noteHandler != nil {
            setup()
        }
    }

    deinit {
        guard let note = note,
            let content = note.content,
            let noteHandler = noteHandler else { return }
        
        if content.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            noteHandler.purge(notes: [note])
        }
        unRegisterAllNotifications()
    }

    @IBAction func tapTagsButton(_ sender: UIButton) {
        performSegue(withIdentifier: AttachTagViewController.identifier, sender: sender)
    }

    private func setup() {
        guard let pianoEditorView = view.createSubviewIfNeeded(PianoEditorView.self) else { return }
        view.addSubview(pianoEditorView)
        pianoEditorView.translatesAutoresizingMaskIntoConstraints = false
        pianoEditorView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pianoEditorView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pianoEditorView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pianoEditorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        pianoEditorView.setup(state: .normal, viewController: self, note: note)
        pianoEditorView.noteHandler = noteHandler
        self.pianoEditorView = pianoEditorView

        setupForMerge()

        //        addNotification()

    }

    private func setupForMerge() {
        if let note = note, let content = note.content {
            self.baseString = content
            EditingTracker.shared.setEditingNote(note: note)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CATransaction.setCompletionBlock { [weak self] in
            if let pianoEditorView = self?.pianoEditorView {
                pianoEditorView.setFirstCellBecomeResponderIfNeeded()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        super.view.endEditing(true)
        saveNoteIfNeeded(needToSave: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? PDFDetailViewController, let data = sender as? Data {
            des.data = data
            return
        }

        if let des = segue.destination as? ReminderDetailViewController,
            let datas = sender as? (EKEventStore, EKReminder) {

            des.eventStore = datas.0
            des.ekReminder = datas.1
            des.detailVC = self
            return
        }

        if let des = segue.destination as? TransParentNavigationController,
            let vc = des.topViewController as? AttachTagViewController,
            let button = sender as? UIButton {
            vc.note = note
            vc.button = button
            vc.noteHandler = noteHandler
            return
        }
    }

    @objc internal func saveNoteIfNeeded(needToSave: Bool = false) {
        guard let note = note,
            let noteHandler = noteHandler,
            let strArray = pianoEditorView.dataSource.first else { return }

        let content = strArray.joined(separator: "\n")
        if note.content != content {
            noteHandler.update(
                origin: note,
                content: content,
                needToSave: needToSave
            )
        } else if note.content == content, note.hasChanges {
            noteHandler.update(
                origin: note,
                content: content,
                needToSave: needToSave
            )
        }
    }

//    func resetTimer() {
//        if timer != nil {
//            timer.invalidate()
//        }
//        timer = Timer.scheduledTimer(
//            timeInterval: 2.0,
//            target: self,
//            selector: #selector(saveNoteIfNeeded),
//            userInfo: nil,
//            repeats: false
//        )
//    }

    @objc private func merge(_ notification: Notification) {
        guard Thread.isMainThread == false else { return }
        DispatchQueue.main.sync {
            guard let their = notification.userInfo?["newContent"] as? String,
                let first = pianoEditorView.dataSource.first else { return }
            let mine = first.joined(separator: "\n")
            guard mine != their else {
                baseString = mine
                return
            }
            let resolved = Resolver.merge(
                base: baseString,
                mine: mine,
                their: their
            )

            let newComponents = resolved.components(separatedBy: .newlines)
            pianoEditorView.isProcessingMerge = true
            pianoEditorView.dataSource = []
            pianoEditorView.dataSource.append(newComponents)
            // TODO: diff로 업데이트 하는 걸로 바꿔야 함.
            pianoEditorView.tableView.reloadData()
            baseString = resolved
            pianoEditorView.isProcessingMerge = false
        }
    }
}

extension DetailViewController {
    internal func registerAllNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(merge(_:)),
            name: .resolveContent,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(popCurrentViewController),
            name: .popDetail,
            object: nil
        )
    }

    @objc func popCurrentViewController() {
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
        }
    }

    internal func unRegisterAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    override func encodeRestorableState(with coder: NSCoder) {
        guard let note = note else { return }
        coder.encode(note.objectID.uriRepresentation(), forKey: "noteURI")
        super.encodeRestorableState(with: coder)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        if let url = coder.decodeObject(forKey: "noteURI") as? URL {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.decodeNote(url: url) { note in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        switch note {
                        case .some(let note):
                            self.note = note
                            self.noteHandler = appDelegate.noteHandler
                            self.setup()
                        case .none:
                            self.popCurrentViewController()
                        }
                    }
                }
            }
        }
    }

}

extension DetailViewController {

    @IBAction func restore(_ sender: Any) {
        guard let note = note, let noteHandler =  noteHandler else { return }
        noteHandler.restore(notes: [note])
//        managedObjectContext?.restore(origin: note)
        // dismiss(animated: true, completion: nil)
    }

//    @IBAction func addPeople(_ sender: Any) {
//        Feedback.success()
//        guard let note = note,
//            let item = sender as? UIBarButtonItem else {return}
//        // TODO: 네트워크 불능이거나, 아직 업로드 안 된 경우 처리
//        cloudSharingController(note: note, item: item) {
//            [weak self] controller in
//            if let self = self, let controller = controller {
//                OperationQueue.main.addOperation {
//                    self.present(controller, animated: true)
//                }
//            }
//        }
//    }

}

//extension DetailViewController {
//    func cloudSharingController(
//        note: Note,
//        item: UIBarButtonItem,
//        completion: @escaping (UICloudSharingController?) -> Void) {
//
//        guard let record = note.recordArchive?.ckRecorded else { return }
//
//        if let recordID = record.share?.recordID {
//            storageService.remote.requestFetchRecords(by: [recordID], isMine: note.isMine) {
//                [weak self] recordsByRecordID, _ in
//                if let self = self,
//                    let dict = recordsByRecordID,
//                    let share = dict[recordID] as? CKShare {
//
//                    let controller = UICloudSharingController(
//                        share: share,
//                        container: self.storageService.remote.container
//                    )
//                    controller.delegate = self
//                    controller.popoverPresentationController?.barButtonItem = item
//                    completion(controller)
//                }
//            }
//        } else {
//            let controller = UICloudSharingController {
//                [weak self] _, preparationHandler in
//                guard let self = self else { return }
////                self.storageService.remote.requestShare(recordToShare: record, preparationHandler: preparationHandler)
//            }
//            controller.delegate = self
//            controller.popoverPresentationController?.barButtonItem = item
//            completion(controller)
//        }
//    }
//}

//extension DetailViewController: UICloudSharingControllerDelegate {
//    func cloudSharingController(
//        _ csc: UICloudSharingController,
//        failedToSaveShareWithError error: Error) {
//
//        if let ckError = error as? CKError {
//            if ckError.isSpecificErrorCode(code: .serverRecordChanged) {
//                guard let note = note,
//                    let recordID = note.recordArchive?.ckRecorded?.recordID else { return }
//
////                storageService.remote.requestAddFetchedRecords(by: [recordID], isMine: note.isMine) {}
//            }
//        } else {
//            print(error.localizedDescription)
//        }
//    }
//
//    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
//        // 메세지 화면 수준에서 나오면 불림
//        guard let note = note,
//            let recordID = note.recordArchive?.ckRecorded?.recordID else { return }
//
//        if csc.share == nil {
//            storageService.local.update(note: note, isShared: false) {
//                OperationQueue.main.addOperation {
////                    guard let self = self else { return }
//                    //TODO:
////                    self.setNavigationItems(state: self.state)
//                }
//            }
//        }
//
//        storageService.remote.requestAddFetchedRecords(by: [recordID], isMine: note.isMine) {
//            OperationQueue.main.addOperation {
////                guard let self = self else { return }
//                //TODO:
////                self.setNavigationItems(state: self.state)
//            }
//        }
//    }
//
//    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
//        // 메시지로 공유한 후 불림
//        // csc.share == nil
//        // 성공 후에 불림
//        guard let note = note,
//            let recordID = note.recordArchive?.ckRecorded?.recordID else { return }
//
//        if csc.share != nil {
//
//            storageService.local.update(note: note, isShared: true) {
//                OperationQueue.main.addOperation {
////                    guard let self = self else { return }
//                    //TODO:
////                    self.setNavigationItems(state: self.state)
//                }
//            }
//            storageService.remote.requestAddFetchedRecords(by: [recordID], isMine: note.isMine) {
//                OperationQueue.main.addOperation {
////                    guard let self = self else { return }
//                    //TODO:
////                    self.setNavigationItems(state: self.state)
//                }
//            }
//        }
//    }
//
//    func itemTitle(for csc: UICloudSharingController) -> String? {
//        return note?.title
//    }
//
//    func itemType(for csc: UICloudSharingController) -> String? {
//        return kUTTypeContent as String
//    }
//
//    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
//        return nil
//        //TODO:
////        return textView.capture()
//    }
//}

private extension UIView {
    func capture() -> Data? {
        var image: UIImage?
        if #available(iOS 10.0, *) {
            let format = UIGraphicsImageRendererFormat()
            format.opaque = isOpaque
            let renderer = UIGraphicsImageRenderer(size: frame.size, format: format)
            image = renderer.image { _ in
                drawHierarchy(in: frame, afterScreenUpdates: true)
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(frame.size, isOpaque, UIScreen.main.scale)
            drawHierarchy(in: frame, afterScreenUpdates: true)
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return image?.jpegData(compressionQuality: 1)
    }
}

extension DetailViewController: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        switch action {
        case .canceled, .deleted:
            controller.dismiss(animated: true, completion: nil)
        case .saved:
            controller.dismiss(animated: true, completion: nil)
            transparentNavigationController?.show(message: "The schedule has registered".loc, color: Color.blueNoti)

        }
    }

}

extension DetailViewController: EKEventViewDelegate {
    func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
        controller.dismiss(animated: true, completion: nil)
    }
}
