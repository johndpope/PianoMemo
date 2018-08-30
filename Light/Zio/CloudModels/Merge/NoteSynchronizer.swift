//
//  NoteSynchronizer.swift
//  PianoNote
//
//  Created by 김범수 on 2018. 4. 3..
//  Copyright © 2018년 piano. All rights reserved.
//

/*
import Foundation
import CloudKit
//import RealmSwift
//import InteractiveTextEngine_iOS

class NoteSynchronizer {
    
    let recordName: String
    let id: String
    let isShared: Bool
    let textView: PianoTextView
    
    init?(textView: PianoTextView) {
        guard let realm = try? Realm(),
            let note = realm.object(ofType: RealmNoteModel.self, forPrimaryKey: textView.noteID) else {return nil}
        self.recordName = note.recordName
        self.id = note.id
        self.isShared = note.isInSharedDB
        self.textView = textView
    }
    
    enum SynchronizerError: Error {
        case saveError
    }
    
    private func sync(with blocks: [Diff3Block], and attributedString: NSAttributedString) {
        var offset = 0
        
        blocks.forEach {
            switch $0 {
            case .add(let index, let range):
                let replacement = attributedString.attributedSubstring(from: range)
                insert(replacement, at: index+offset)
                offset += range.length
            case .delete(let range):
                delete(in: NSMakeRange(range.location + offset, range.length))
                offset -= range.length
            case .change(_, let myRange, let serverRange):
                let replacement = attributedString.attributedSubstring(from: serverRange)
                replace(in: NSMakeRange(myRange.location + offset, myRange.length), with: replacement)
                offset += serverRange.length - myRange.length
            default: break
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.textView.startDisplayLink()
        }
        
        
    }
    
    private func sync(with blocks: [Diff3Block], and attributedString: NSAttributedString, serverRecord: CKRecord) {
        sync(with: blocks, and: attributedString)
        
        DispatchQueue.main.sync { [weak self] in
            guard let attributedString = self?.textView.attributedText else {
                return
            }
            let (content, attributes) = attributedString.getStringWithPianoAttributes()
            let attributeData = (try? JSONEncoder().encode(attributes)) ?? Data()
            
            serverRecord[Schema.Note.content] = content as CKRecordValue
            serverRecord[Schema.Note.attributes] = attributeData as CKRecordValue
        }
    }
    
    
    private func insert(_ attributedString: NSAttributedString, at index: Int) {
        DispatchQueue.main.sync { [weak self] in
            //TODO: pick background color
//            let backgroundLayer = InteractiveBackgroundLayer()
////            backgroundLayer.backgroundColor = UIColor.orange.cgColor
//            self?.textView.layer.insertSublayer(backgroundLayer, at: 0)

            let newAttributedString = NSMutableAttributedString(attributedString: attributedString)
            newAttributedString.addAttribute(.animatingBackground, value: true, range: NSMakeRange(0, newAttributedString.length))

            self?.textView.textStorage.insert(newAttributedString, at: index)
        }
    }
    
    private func delete(in range: NSRange) {
        DispatchQueue.main.sync { [weak self] in
            self?.textView.textStorage.deleteCharacters(in: range)
        }
    }
    
    private func replace(in range: NSRange, with attributedString: NSAttributedString) {
        DispatchQueue.main.sync { [weak self] in

//            let backgroundLayer = InteractiveBackgroundLayer()
////            backgroundLayer.backgroundColor = UIColor.orange.cgColor
//            self?.textView.layer.insertSublayer(backgroundLayer, at: 0)

            let newAttributedString = NSMutableAttributedString(attributedString: attributedString)
            newAttributedString.addAttribute(.animatingBackground, value: true, range: NSMakeRange(0, newAttributedString.length))

            self?.textView.textStorage.replaceCharacters(in: range, with: newAttributedString)
        }
    }
    
    func registerToCloud() {
        let database = isShared ? CloudManager.shared.sharedDatabase : CloudManager.shared.privateDatabase
        
        database.register(synchronizer: self)
    }
    
    func unregisterFromCloud() {
        let database = isShared ? CloudManager.shared.sharedDatabase : CloudManager.shared.privateDatabase
        
        database.unregister(synchronizer: self)
    }
    
    func serverContentChanged(_ record: CKRecord) {
        guard let noteModel = record.parseRecord(isShared: isShared) as? RealmNoteModel else {return}
        
        if let realm = try? Realm(),
            let oldNote = realm.object(ofType: RealmNoteModel.self, forPrimaryKey: noteModel.id) {
            
            textView.isSyncing = true
            if oldNote.content != noteModel.content {
                let oldContent = oldNote.content
                let serverContent = noteModel.content
                DispatchQueue.main.sync {
                    let currentString = textView.textStorage.string
                    
                    DispatchQueue.global(qos: .utility).async { [weak self] in
                        let serverAttributesData = noteModel.attributes
                        let serverAttributes = try! JSONDecoder().decode([AttributeModel].self, from: serverAttributesData)
                        let serverAttributedString = NSMutableAttributedString(string: noteModel.content)
                        serverAttributedString.addAttributes(FormAttributes.defaultAttributes, range: NSMakeRange(0, serverAttributedString.length))
                        serverAttributes.forEach { serverAttributedString.add(attribute: $0) }
                        
                        print("ancestore: \n"+oldContent)
                        print("my: \n"+currentString)
                        print("server: \n"+serverContent)
                        let diff3Maker = Diff3Maker(ancestor: oldContent, a: currentString, b: serverContent)
                        let diff3Chunks = diff3Maker.mergeInLineLevel().flatMap { chunk -> [Diff3Block] in
                            if case let .change(oRange, aRange, bRange) = chunk {
                                let oString = oldContent.substring(with: oRange)
                                let aString = currentString.substring(with: aRange)
                                let bString = serverContent.substring(with: bRange)
                                
                                let wordDiffMaker = Diff3Maker(ancestor: oString, a: aString, b: bString, separator: "")
                                return wordDiffMaker.mergeInWordLevel(oOffset: oRange.lowerBound, aOffset: aRange.lowerBound, bOffset: bRange.lowerBound)
                                
                            } else if case let .conflict(oRange, aRange, bRange) = chunk {
                                let oString = oldContent.substring(with: oRange)
                                let aString = currentString.substring(with: aRange)
                                let bString = serverContent.substring(with: bRange)
                                
                                let wordDiffMaker = Diff3Maker(ancestor: oString, a: aString, b: bString, separator: "")
                                return wordDiffMaker.mergeInWordLevel(oOffset: oRange.lowerBound, aOffset: aRange.lowerBound, bOffset: bRange.lowerBound)
                            } else { return [chunk] }
                        }
                        
                        self?.sync(with: diff3Chunks, and: serverAttributedString)
                    }
                }
                
                
                
                
            } else if oldNote.attributes != noteModel.attributes {
                
                let myAttributes = try! JSONDecoder().decode([AttributeModel].self, from: oldNote.attributes)
                let serverAttributes = try! JSONDecoder().decode([AttributeModel].self, from: noteModel.attributes)
                
                var mySet = Set<AttributeModel>(myAttributes)
                var serverSet = Set<AttributeModel>(serverAttributes)
                mySet.subtract(serverAttributes)
                serverSet.subtract(myAttributes)
                
                DispatchQueue.main.sync {
                    mySet.forEach {
                        textView.textStorage.delete(attribute: $0)
                    }
                    serverSet.forEach {
                        textView.textStorage.add(attribute: $0)
                    }
                }
                
            }

            if let colorThemeCode = record[Schema.Note.colorThemeCode] as? String,
                let preset = ColorPreset(rawValue: colorThemeCode) {
//                let color = UIColor(hex6: newBackgroundColor)
                DispatchQueue.main.async { [weak self] in
//                    self?.textView.backgroundColor = color
                    self?.textView.resetColors(preset: preset)
                }
            }
            textView.isSyncing = false
        }
    }
    
    func resolveConflict(ancestorRecord: CKRecord, myRecord: CKRecord, serverRecord: CKRecord, completion: @escaping  (Bool) -> ()) {
        
        let myModified = myRecord.modificationDate ?? Date(timeIntervalSince1970: 0)
        let serverModified = serverRecord.modificationDate ?? Date(timeIntervalSince1970: 0)
        
        let ancestorContent = (ancestorRecord[Schema.Note.content] as? String) ?? ""
        let serverContent = serverRecord[Schema.Note.content] as! String
        
        let ancestorAttributesData = (ancestorRecord[Schema.Note.attributes] as? Data) ?? "[]".data(using: .utf8)!
        let serverAttributesData = serverRecord[Schema.Note.attributes] as! Data
        
        let ancestorAttributes = (try? JSONDecoder().decode([AttributeModel].self, from: ancestorAttributesData)) ?? []
        let serverAttributes = (try? JSONDecoder().decode([AttributeModel].self, from: serverAttributesData)) ?? []
        
        let serverAttributedString = NSMutableAttributedString(string: serverContent)
        serverAttributedString.addAttributes(FormAttributes.defaultAttributes, range: NSMakeRange(0, serverAttributedString.length))
        serverAttributes.forEach { serverAttributedString.add(attribute: $0) }
        
        
        
        textView.isSyncing = true
        
        
        
        if ancestorContent != serverContent {
            DispatchQueue.main.sync {
                let currentString = self.textView.textStorage.string
                
                DispatchQueue.global(qos: .utility).async { [weak self] in
                    print("ancestore: \n"+ancestorContent)
                    print("my: \n"+currentString)
                    print("server: \n"+serverContent)
                    let diff3Maker = Diff3Maker(ancestor: ancestorContent, a: currentString, b: serverContent)
                    let diff3Chunks = diff3Maker.mergeInLineLevel().flatMap { chunk -> [Diff3Block] in
                        if case let .change(oRange, aRange, bRange) = chunk {
                            let oString = ancestorContent.substring(with: oRange)
                            let aString = currentString.substring(with: aRange)
                            let bString = serverContent.substring(with: bRange)
                            
                            let wordDiffMaker = Diff3Maker(ancestor: oString, a: aString, b: bString, separator: "")
                            return wordDiffMaker.mergeInWordLevel(oOffset: oRange.lowerBound, aOffset: aRange.lowerBound, bOffset: bRange.lowerBound)
                            
                        } else if case let .conflict(oRange, aRange, bRange) = chunk {
                            let oString = ancestorContent.substring(with: oRange)
                            let aString = currentString.substring(with: aRange)
                            let bString = serverContent.substring(with: bRange)
                            
                            let wordDiffMaker = Diff3Maker(ancestor: oString, a: aString, b: bString, separator: "")
                            return wordDiffMaker.mergeInWordLevel(oOffset: oRange.lowerBound, aOffset: aRange.lowerBound, bOffset: bRange.lowerBound)
                        } else { return [chunk] }
                    }
                    
                    self?.sync(with: diff3Chunks, and: serverAttributedString, serverRecord: serverRecord)
                    DispatchQueue.main.async {
                        self?.textView.isSyncing = false
                    }
                    completion(true)
                }
            }
        } else if ancestorAttributesData != serverAttributesData {
            //Let's just union it
            DispatchQueue.main.sync { [weak self] in
                guard let (_, currentAttributes) = self?.textView.get() else {print("get attributes error!");return}
                
                var myDeleteSet = Set<AttributeModel>(ancestorAttributes)
                var myAddSet = Set<AttributeModel>(currentAttributes)
                myDeleteSet.subtract(currentAttributes)
                myAddSet.subtract(ancestorAttributes)
                
                var serverDeleteSet = Set<AttributeModel>(ancestorAttributes)
                var serverAddSet = Set<AttributeModel>(serverAttributes)
                serverDeleteSet.subtract(serverAttributes)
                serverAddSet.subtract(ancestorAttributes)
                
                let deletedSet = myDeleteSet.union(serverDeleteSet)
                let addSet = myAddSet.union(serverAddSet)
                
                deletedSet.forEach { self?.textView.textStorage.delete(attribute: $0) }
                addSet.forEach { self?.textView.textStorage.add(attribute: $0) }
                
                self?.textView.isSyncing = false
            }
            completion(true)
        } else {
            if myModified.compare(serverModified) == .orderedDescending {
                
                if let serverCategory = serverRecord[Schema.Note.tags] as? String,
                    let myCategory = myRecord[Schema.Note.tags] as? String,
                    serverCategory != myCategory {
                    
                    serverRecord[Schema.Note.tags] = myRecord[Schema.Note.tags]
                    completion(true)
                    textView.isSyncing = false
                    return
                }
                
            }
            
            completion(false)
            textView.isSyncing = false
            completion(false)
        }
    }
    
    func saveContent(completion: ((Error?) -> Void)?) {
        
        guard let realm = try? Realm(),
            let note = realm.object(ofType: RealmNoteModel.self, forPrimaryKey: id) else {return completion?(SynchronizerError.saveError) ?? ()}
        let (text, pianoAttributes) = textView.attributedText.getStringWithPianoAttributes()
        let attributeData = (try? JSONEncoder().encode(pianoAttributes)) ?? Data()

        let dic = note.getRecordWithURL()
        let localRecord = dic.object(forKey: Schema.dicRecordKey) as! CKRecord

        localRecord[Schema.Note.content] = text as CKRecordValue
        localRecord[Schema.Note.attributes] = attributeData as CKRecordValue
        
        let database:RxCloudDatabase = isShared ? CloudManager.shared.sharedDatabase : CloudManager.shared.privateDatabase

        database.upload(record: localRecord) { _, error in
            (dic.object(forKey: Schema.dicURLsKey) as! [URL]).forEach {
                try? FileManager.default.removeItem(at: $0)
            }
            guard error == nil else { return completion?(error!) ?? () }
        }
    }
}

*/
