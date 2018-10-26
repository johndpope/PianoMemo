//
//  Detail2ViewController.swift
//  Piano
//
//  Created by Kevin Kim on 22/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CloudKit
import MobileCoreServices


/**
 textViewDidEndEditing에서 데이터 소스에 업로드가 된다. (업로드 될 때에는 뷰의 모든 정보가 키 값으로 변환되어서 텍스트에 저장된다)
 cellForRow에선 단순히 string(필수)과 attribute(옵션)을 넣어주는 역할만 한다.
 모든 변환은 cell이 하고 있으며
 데이터 인풋인 텍스트뷰가 하고 있다.
 FontType, HighlightType은 좌우 스와이프할 때에만 변한다.
 leading,trailing 액션들을 시행할 경우, 데이터 소스와 뷰가 모두 같이 변한다.
 */

protocol StringType {
    var string: String { get set }
}

extension String: StringType {
    var string: String {
        get {
            return self
        } set {
            self = newValue
        }
    }
}

enum FontType {
    case title
    case subTitle
    case bold
    
    var font: Font {
        switch self {
        case .title:
            return Font.preferredFont(forTextStyle: .title1).black
        case .subTitle:
            return Font.preferredFont(forTextStyle: .title2).black
        case .bold:
            return Font.preferredFont(forTextStyle: .body).black
        }
    }
}

struct AttributedStringType: StringType {
    var string: String
    var fontType: FontType
}

class Detail2ViewController: UIViewController, Detailable {
    func setupForPiano() {
        //
    }
    
    func setupForNormal() {
        //
    }
    
    enum VCState {
        case normal
        case typing
        case piano
    }
    
    @IBOutlet weak var detailToolbar: DetailToolbar!
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var tableView: UITableView!
    var dataSource: [[StringType]] = []
    var note: Note?
    weak var storageService: StorageService!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if storageService == nil {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                self.storageService = appDelegate.storageService
            }
        } else {
            setupDelegate()
            setupByKeyboard()
            setupDataSource()
            setupNavigationItems(state: .normal)
            //        addNotification()
        }

        
    }
    
    private func setupDataSource() {
        guard let note = note, let content = note.content else { return }
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let contents = content.components(separatedBy: .newlines)
            self.dataSource.append(contents)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        }
        
        
    }
    
    private func setupDelegate() {
        detailToolbar.detailable = self
    }
    
    private func setupTableView() {

    }
    
    private func setupByKeyboard() {

        let cell = tableView.visibleCells.first { (cell) -> Bool in
            guard let blockCell = cell as? BlockCell else { return false }
            return blockCell.textView.isFirstResponder
        }
        
        if cell != nil {
            detailToolbar.setup(state: .typing)
            setTableViewInsetTyping(kbHeight: 320)
        } else {
            detailToolbar.setup(state: .normal)
            setTableViewInsetNormal()
        }
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotifications()
    }
}

extension Detail2ViewController {
    internal func registerAllNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeDidChangeNotification(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    internal func unRegisterAllNotifications(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func contentSizeDidChangeNotification(_ notification: Notification) {
        guard let note = note else { return }
//        textView.setup(note: note) { _ in }
    }
    
    @objc func didChangeStatusBarOrientation(_ notification: Notification) {
//        if let pianoControl = textView.pianoControl,
//            let pianoView = pianoView,
//            !textView.isSelectable {
//            connect(pianoView: pianoView, pianoControl: pianoControl, textView: textView)
//            pianoControl.attach(on: textView)
//        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
//        coordinator.animate(alongsideTransition: nil) {[unowned self] (_) in
//            guard let textView = self.textView else { return }
//            if let pianoControl = textView.pianoControl,
//                let pianoView = self.pianoView,
//                !textView.isSelectable {
//                self.connect(pianoView: pianoView, pianoControl: pianoControl, textView: textView)
//                pianoControl.attach(on: textView)
//            }
//        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        setTableViewInsetNormal()
        view.layoutIfNeeded()
//        setNavigationItems(state: .normal)
    }
    
    private func setTableViewInsetNormal(){
        tableView.contentInset.bottom = 100
        tableView.scrollIndicatorInsets.bottom = 0
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            let _ = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }
        setTableViewInsetTyping(kbHeight: kbHeight)
        
//        setNavigationItems(state: .typing)
        view.layoutIfNeeded()
    }
    
    private func setTableViewInsetTyping(kbHeight: CGFloat) {
        let height = kbHeight
        tableView.contentInset.bottom = height + detailToolbar.bounds.height
        tableView.scrollIndicatorInsets.bottom = height + detailToolbar.bounds.height
    }
}

extension Detail2ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let stringType = dataSource[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: BlockCell.reuseIdentifier) as! BlockCell
        cell.textView.detailVC = self
        cell.stringType = stringType
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell")
        let label = cell?.contentView.viewWithTag(1000) as? UILabel

        if let note = note, let id = note.modifiedBy as? CKRecord.ID, note.isShared {
            CKContainer.default().discoverUserIdentity(withUserRecordID: id) { [weak self] userIdentity, error in
                guard let self = self else { return }
                if let name = userIdentity?.nameComponents?.givenName, !name.isEmpty {
                    let str = self.dateStr(from: note)
                    DispatchQueue.main.async {
                        label?.text =  str + ", Latest modified by".loc + " \(name)"
                    }
                }
            }
        } else {
            label?.text = dateStr(from: note)
        }
        return cell?.contentView
    }
    
    private func dateStr(from note: Note?) -> String {
        if let date = note?.modifiedAt {
            let string = DateFormatter.sharedInstance.string(from: date)
            return string
        } else {
            return "Play your thought"
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let cell = tableView.cellForRow(at: indexPath) as? BlockCell else { return false }
        return cell.textView.text.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard let cell = tableView.cellForRow(at: indexPath) as? BlockCell else { return false }
        return cell.textView.text.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
    }
    
//    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//        <#code#>
//    }
}

extension Detail2ViewController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        <#code#>
//    }
//
//    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
//        <#code#>
//    }
//
//    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
//        <#code#>
//    }
//
//    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        <#code#>
//    }
//
//    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        <#code#>
//    }
}

extension Detail2ViewController: UITextViewDelegate {
    
    
    
    func textViewDidChange(_ textView: UITextView) {
        guard let cell = textView.superview?.superview?.superview as? BlockCell,
            let indexPath = tableView.indexPath(for: cell) else { return }
        print(textView.bounds.height)
        
        if (cell.formButton.title(for: .normal)?.count ?? 0) == 0,
            var bulletKey = BulletKey(text: textView.text, selectedRange: textView.selectedRange) {
            switch bulletKey.type {
            case .orderedlist:
                if indexPath.row != 0 {
                    let prevIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
                    bulletKey = adjust(prevIndexPath: prevIndexPath, for: bulletKey)
                }
                
                cell.convertForm(bulletable: bulletKey)
                
                //다음셀들도 적응시킨다.
                adjustAfter(currentIndexPath: indexPath, bulletable: bulletKey)
                
            default:
                cell.convertForm(bulletable: bulletKey)
            }
        }
        
        cell.addCheckAttrIfNeeded()
        
        
        
        reactCellHeight(textView)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        //TODO: 뭘 해야하나..?
    }

    
    func textViewDidEndEditing(_ textView: UITextView) {
        //데이터 소스에 저장하기
        //fontType, 서식을 키로 바꿔주고 텍스트와 결합해서 저장해야함
        guard let cell = textView.superview?.superview?.superview as? BlockCell,
            var text = textView.text,
            let indexPath = tableView.indexPath(for: cell) else { return }
        
        if let str = cell.formButton.title(for: .normal),
            let bulletValue = BulletValue(text: str, selectedRange: NSMakeRange(0, 0)) {
            text = bulletValue.whitespaces.string + bulletValue.key + bulletValue.followStr + text
        }
        
        if let fontType = cell.fontType {
            let attrStrType = AttributedStringType(string: text, fontType: fontType)
            dataSource[indexPath.section][indexPath.row] = attrStrType
        } else {
            dataSource[indexPath.section][indexPath.row] = text
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        guard let cell = textView.superview?.superview?.superview as? BlockCell,
            let indexPath = tableView.indexPath(for: cell) else { return true }
        
        let situation = typingSituation(cell: cell, indexPath: indexPath, selectedRange: textView.selectedRange, replacementText: text)
        
        switch situation {
        case .revertForm:
            cell.revertForm()
        case .removeForm:
            cell.removeForm()
        case .split:
            split(textView: textView, cell: cell, indexPath: indexPath)
            //데이터와 뷰 바인딩(테이블뷰셀 인서트)인 걸 만들어서 호출하기
        case .combine:
            combine(textView: textView, cell: cell, indexPath: indexPath)
        case .stayCurrent:
            return true
        }
        return false
    }
    
    enum TypingSituation {
        case revertForm
        case removeForm
        case combine
        case stayCurrent
        case split
    }
    
    private func typingSituation(cell: BlockCell,
                                 indexPath: IndexPath,
                                 selectedRange: NSRange,
                                 replacementText text: String) -> TypingSituation {
        
        if selectedRange == NSMakeRange(0, 0) {
            //문단 맨 앞에 커서가 있으면서 백스페이스 눌렀을 때
            if !cell.formButton.isHidden {
                //서식이 존재한다면
                if text.count == 0 {
                    return .revertForm
                } else if text == "\n" {
                    return .removeForm
                } else {
                    return .stayCurrent
                }
            }
            
            if indexPath.row != 0, text.count == 0 {
                //TODO: 나중에 텍스트가 아닌 다른 타입일 경우에 이전 셀이 텍스트인 지도 체크해야함
                return .combine
            }
            
            //그 외의 경우
            return .stayCurrent
            
        } else if text == "\n" {
            //개행을 눌렀을 때
            return .split
        } else {
            return .stayCurrent
        }
    }
    
    func split(textView: UITextView, cell: BlockCell, indexPath: IndexPath) {
        
        let insertRange = NSMakeRange(0, textView.selectedRange.lowerBound)
        var insertStr = (textView.text as NSString).substring(with: insertRange)
        //1. form이 있다면 이를 키로 바꾸고 데이터 소스에 저장해야함.
        if let formStr = cell.formButton.title(for: .normal),
            var bulletValue = BulletValue(text: formStr, selectedRange: NSMakeRange(0, 0)) {
            insertStr = bulletValue.whitespaces.string + bulletValue.key + bulletValue.followStr + insertStr
            
            //순서있는 서식이면 숫자  + 1 뿐 아니라 다음 서식들도 업뎃해줘야 하며
            if let currentNum = Int(bulletValue.string) {
                let nextNumStr = "\(UInt(currentNum + 1))"
                bulletValue.string = nextNumStr
                cell.setFormButton(bulletable: bulletValue)
                adjustAfter(currentIndexPath: indexPath, bulletable: bulletValue)
            }
            
            //순서 없는 서식이면 그대로 간다.
            
        } else {
            //2. 남아야 하는 텍스트 대입, 폰트 타입, 폼 버튼는 nil로 세팅한다.
            cell.fontType = nil
        }
        
        if let attrStrType = dataSource[indexPath.section][indexPath.row] as? AttributedStringType {
            let newAttrStrType = AttributedStringType(string: insertStr, fontType: attrStrType.fontType)
            dataSource[indexPath.section].insert(newAttrStrType, at: indexPath.row)
        } else {
            dataSource[indexPath.section].insert(insertStr, at: indexPath.row)
        }
        
        
        
        let leaveRange = NSMakeRange(textView.selectedRange.upperBound,
                                     textView.attributedText.length - textView.selectedRange.upperBound)
        let leaveStr = (textView.text as NSString).substring(with: leaveRange)
        
        //3. 테이블 뷰 갱신시키기
        UIView.performWithoutAnimation {
            tableView.insertRows(at: [indexPath], with: .none)
        }
        
        //checkOn이면 checkOff로 바꿔주기
        cell.setCheckOffIfNeeded()
        
        
        let range = NSMakeRange(0, textView.attributedText.length)
        let leaveAttrString = NSAttributedString(string: leaveStr, attributes: FormAttribute.defaultAttr)
        textView.replaceCharacters(in: range, with: leaveAttrString)
        textView.selectedRange = NSMakeRange(0, 0)
        textView.delegate?.textViewDidChange?(textView)
    }
    
    func combine(textView: UITextView, cell: BlockCell, indexPath: IndexPath) {
        //1. 이전 셀의 텍스트뷰 정보를 불러와서 폰트값을 세팅해줘야 하고, 텍스트를 더해줘야한다.(이미 커서가 앞에 있으니 걍 텍스트뷰의 replace를 쓰면 된다 됨), 서식이 있다면 마찬가지로 서식을 대입해줘야한다. 서식은 텍스트 대입보다 뒤에 대입을 해야, 취소선 등이 적용되게 해야한다.
        let prevIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
        let prevStrType = dataSource[prevIndexPath.section][prevIndexPath.row]
        
        //0. 이전 인덱스의 데이터 소스 및 셀을 지운다.
        dataSource[prevIndexPath.section].remove(at: prevIndexPath.row)
        UIView.performWithoutAnimation {
            tableView.deleteRows(at: [prevIndexPath], with: .none)
        }
        
        //1. 이전 폰트 타입 값을 대입해줘야 한다.
        cell.fontType = (prevStrType as? AttributedStringType)?.fontType
        
        //2. 데이터 소스에있는 키 텍스트 값을 가져와서 결합한다.(타이핑중인 셀은 뷰가 최신이므로 뷰에서 가져오고 타이핑 중이지 않은 건 데이터 소스에서 가져온다)
        let combineText = prevStrType.string + textView.text
        
        
        //3. 텍스트 뷰에 대입시키고 커서를 배치시킨다.
        let newAttrString = NSAttributedString(string: combineText, attributes: FormAttribute.defaultAttr)
        textView.replaceCharacters(in: NSMakeRange(0, textView.attributedText.length), with: newAttrString)
        textView.selectedRange = NSMakeRange(prevStrType.string.utf16.count, 0)
        
        
    }
    
    private func adjustAfter(currentIndexPath: IndexPath, bulletable: Bulletable) {
         var bulletable = bulletable
        var indexPath = IndexPath(row: currentIndexPath.row + 1, section: currentIndexPath.section)
        while indexPath.row < tableView.numberOfRows(inSection: 0) {
            let str = dataSource[indexPath.section][indexPath.row].string
            guard let nextBulletKey = BulletKey(text: str, selectedRange: NSMakeRange(0, 0)),
                bulletable.whitespaces.string == nextBulletKey.whitespaces.string,
                let currentNum = UInt(bulletable.string),
                !bulletable.isSequencial(next: nextBulletKey) else { return }
            
            //1. check overflow
            let nextNumStr = "\(currentNum + 1)"
            bulletable.string = nextNumStr
            guard !bulletable.isOverflow else { return }
            
            //2. set datasource
            (str as NSString).replacingCharacters(in: nextBulletKey.range, with: nextNumStr)
            dataSource[indexPath.section][indexPath.row].string = str
            
            //3. set view
            if let cell = tableView.cellForRow(at: indexPath) as? BlockCell {
                cell.setFormButton(bulletable: bulletable)
            }
            
            
            indexPath.row += 1
        }
        
    }
    
    private func adjust(prevIndexPath: IndexPath, for bulletKey: BulletKey) -> BulletKey {
        //이전 셀이 존재하고, 그 셀이 넘버 타입이고, whitespace까지 같다면, 그 셀 + 1한 값을 bulletKey의 value에 대입
        let str = dataSource[prevIndexPath.section][prevIndexPath.row].string
        guard let prevBulletKey = BulletKey(text: str, selectedRange: NSMakeRange(0, 0)),
            let num = Int(prevBulletKey.string),
            prevBulletKey.whitespaces.string == bulletKey.whitespaces.string
            else { return bulletKey }
        var bulletKey = bulletKey
        bulletKey.string = "\(num + 1)"
        return bulletKey
    }
    
    internal func reactCellHeight(_ textView: UITextView) {
        let index = textView.attributedText.length - 1
        guard index > -1 else {
            UIView.performWithoutAnimation {
                tableView.performBatchUpdates(nil, completion: nil)
            }
            return
        }
        
        let lastLineRect = textView.layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: nil)
        let textViewHeight = textView.bounds.height
        //TODO: 테스트해보면서 20값 해결하기
        guard textView.layoutManager.location(forGlyphAt: index).y == 0
            || textViewHeight - (lastLineRect.origin.y + lastLineRect.height) > 20 else {
                return
        }
        
        UIView.performWithoutAnimation {
            tableView.performBatchUpdates(nil, completion: nil)
        }
    }
}

//MARK: Action
extension Detail2ViewController {
    @IBAction func tapBackground(_ sender: UITapGestureRecognizer) {
        guard !tableView.isEditing else { return }
        //터치 좌표를 계산해서 해당 터치의 y좌표, x좌표는 중앙에 셀이 없는지 체크하고, 없다면 맨 아래쪽 셀 터치한 거와 같은 동작을 하도록 구현하기
//        tableView.indexPathForRow(at: <#T##CGPoint#>)
//        createBlockIfNeeded()
    }
}

extension Detail2ViewController {
    
    @objc func changeTag(_ sender: Any) {
        performSegue(withIdentifier: "AttachTagCollectionViewController", sender: nil)
    }
    
    internal func setupNavigationItems(state: VCState){
        guard let note = note else { return }
        var btns: [BarButtonItem] = []
        switch state {
        case .normal:
            let btn = BarButtonItem(image: note.isShared ? #imageLiteral(resourceName: "addPeople2") : #imageLiteral(resourceName: "addPeople"), style: .plain, target: self, action: #selector(addPeople(_:)))
            btns.append(btn)
            navigationItem.setLeftBarButtonItems(nil, animated: false)
        case .typing:
            //            btns.append(BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:))))
            btns.append(BarButtonItem(image: note.isShared ? #imageLiteral(resourceName: "addPeople2") : #imageLiteral(resourceName: "addPeople"), style: .plain, target: self, action: #selector(addPeople(_:))))
            
            navigationItem.setLeftBarButtonItems(nil, animated: false)
        case .piano:
            let leftBtns = [BarButtonItem(title: "  ", style: .plain, target: nil, action: nil)]
            navigationController?.navigationItem.setLeftBarButtonItems(leftBtns, animated: false)
            navigationItem.setLeftBarButtonItems(leftBtns, animated: false)
            
        }
        setTitleView(state: state)
        navigationItem.setRightBarButtonItems(btns, animated: false)
    }
    
    internal func setTitleView(state: VCState) {
        guard let note = note else { return }
        switch state {
        case .piano:
            if let titleView = view.createSubviewIfNeeded(PianoTitleView.self) {
                titleView.set(text: "Swipe over the text you want to copy✨".loc)
                navigationItem.titleView = titleView
            }
            
        default:
            let tagButton = UIButton(type: .system)
            tagButton.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 200, height: 44))
            tagButton.addTarget(self, action: #selector(changeTag(_:)), for: .touchUpInside)
            navigationItem.titleView = tagButton
            
            setupTagToNavItem()
        }
    }
    
    @IBAction func restore(_ sender: Any) {
        guard let note = note else { return }
        storageService.local.restore(note: note, completion: {})
        // dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addPeople(_ sender: Any) {
        Feedback.success()
        guard let note = note,
            let item = sender as? UIBarButtonItem else {return}
        // TODO: 네트워크 불능이거나, 아직 업로드 안 된 경우 처리
        cloudSharingController(note: note, item: item) {
            [weak self] controller in
            if let self = self, let controller = controller {
                OperationQueue.main.addOperation {
                    self.present(controller, animated: true)
                }
            }
        }
    }
    
    
    @IBAction func tapAttachTag(_ sender: Any) {
        guard let _ = note else { return }
        performSegue(withIdentifier: AttachTagCollectionViewController.identifier, sender: nil)
    }
    
    internal func setupTagToNavItem() {
        guard let note = note,
            let tagBtn = navigationItem.titleView as? UIButton else { return }
        let tags = note.tags ?? ""
        if tags.count != 0 {
            tagBtn.setImage(nil, for: .normal)
            tagBtn.setTitle(tags, for: .normal)
            
        } else {
            tagBtn.setImage(#imageLiteral(resourceName: "addTag"), for: .normal)
            tagBtn.setTitle("", for: .normal)
        }
    }
}

extension Detail2ViewController {
    func cloudSharingController(
        note: Note,
        item: UIBarButtonItem,
        completion: @escaping (UICloudSharingController?) -> Void)  {
        
        guard let record = note.recordArchive?.ckRecorded else { return }
        
        if let recordID = record.share?.recordID {
            storageService.remote.requestFetchRecords(by: [recordID], isMine: note.isMine) {
                [weak self] recordsByRecordID, operationError in
                if let self = self,
                    let dict = recordsByRecordID,
                    let share = dict[recordID] as? CKShare {
                    
                    let controller = UICloudSharingController(
                        share: share,
                        container: self.storageService.remote.container
                    )
                    controller.delegate = self
                    controller.popoverPresentationController?.barButtonItem = item
                    completion(controller)
                }
            }
        } else {
            let controller = UICloudSharingController {
                [weak self] controller, preparationHandler in
                guard let self = self else { return }
                self.storageService.remote.requestShare(recordToShare: record, preparationHandler: preparationHandler)
            }
            controller.delegate = self
            controller.popoverPresentationController?.barButtonItem = item
            completion(controller)
        }
    }
}

extension Detail2ViewController: UICloudSharingControllerDelegate {
    func cloudSharingController(
        _ csc: UICloudSharingController,
        failedToSaveShareWithError error: Error) {
        
        if let ckError = error as? CKError {
            if ckError.isSpecificErrorCode(code: .serverRecordChanged) {
                guard let note = note,
                    let recordID = note.recordArchive?.ckRecorded?.recordID else { return }
                
                storageService.remote.requestAddFetchedRecords(by: [recordID], isMine: note.isMine) {}
            }
        } else {
            print(error.localizedDescription)
        }
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        // 메세지 화면 수준에서 나오면 불림
        guard let note = note,
            let recordID = note.recordArchive?.ckRecorded?.recordID else { return }
        
        if csc.share == nil {
            storageService.local.update(note: note, isShared: false) {
                OperationQueue.main.addOperation { [weak self] in
                    guard let self = self else { return }
                    //TODO:
//                    self.setNavigationItems(state: self.state)
                }
            }
        }
        
        storageService.remote.requestAddFetchedRecords(by: [recordID], isMine: note.isMine) {
            OperationQueue.main.addOperation { [weak self] in
                guard let self = self else { return }
                //TODO:
//                self.setNavigationItems(state: self.state)
            }
        }
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        // 메시지로 공유한 후 불림
        // csc.share == nil
        // 성공 후에 불림
        guard let note = note,
            let recordID = note.recordArchive?.ckRecorded?.recordID else { return }
        
        if csc.share != nil {
            
            storageService.local.update(note: note, isShared: true) {
                OperationQueue.main.addOperation { [weak self] in
                    guard let self = self else { return }
                    //TODO:
//                    self.setNavigationItems(state: self.state)
                }
            }
            storageService.remote.requestAddFetchedRecords(by: [recordID], isMine: note.isMine) {
                OperationQueue.main.addOperation { [weak self] in
                    guard let self = self else { return }
                    //TODO:
//                    self.setNavigationItems(state: self.state)
                }
            }
        }
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return note?.title
    }
    
    func itemType(for csc: UICloudSharingController) -> String? {
        return kUTTypeContent as String
    }
    
    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        return nil
        //TODO:
//        return textView.capture()
    }
}

private extension UIView {
    func capture() -> Data? {
        var image: UIImage?
        if #available(iOS 10.0, *) {
            let format = UIGraphicsImageRendererFormat()
            format.opaque = isOpaque
            let renderer = UIGraphicsImageRenderer(size: frame.size, format: format)
            image = renderer.image { context in
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
