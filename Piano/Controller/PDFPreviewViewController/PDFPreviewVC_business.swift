//
//  PDFPreviewVC_business.swift
//  Piano
//
//  Created by Kevin Kim on 25/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import UIKit
import PDFKit

extension PDFPreviewViewController {
    internal func registerAllNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation(_:)), name: Application.didChangeStatusBarOrientationNotification, object: nil)
    }

    internal func saveFile(completion: @escaping (URL?) -> Void) {
        guard let document = pdfView.document else { return }
        do {
            let documentDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            let fileURL = documentDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
            if document.write(to: fileURL) {
                completion(fileURL)
            } else {
                completion(nil)
            }

        } catch {
            completion(nil)
        }
    }

    internal func removeFile(url: URL?) {
        guard let url = url else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print(error)
        }
    }

    internal func sendPDF() {
        //백그라운드 쓰레드로 PDF 만들고, 메인쓰레드에서는 인디케이터 표시해주고, 완료되면 performSegue로 보내서 확인시키고 그다음 전달하자
        showActivityIndicator()

        DispatchQueue.global().async { [weak self] in
            guard let self = self,
                let strArray = self.note?.content?.components(separatedBy: .newlines) else { return }

            let resultMutableAttrString = NSMutableAttributedString(string: "")
            strArray.forEach {
                //헤더 키가 있다면, 헤더 키를 제거하고, 헤더 폰트를 대입해준다.
                //헤더 키가 없고, 불렛 키가 있다면, 불렛 키를 불렛 밸류로 만들어주고, 문단 스타일을 적용시킨다.
                //피아노 키가 있다면 형광펜으로 대체시킨다.
                let mutableAttrStr = NSMutableAttributedString(string: $0, attributes: FormAttribute.defaultAttrForPDF)
                if let headerKey = HeaderKey(text: $0, selectedRange: NSRange(location: 0, length: 0)) {
                    mutableAttrStr.replaceCharacters(in: headerKey.rangeToRemove, with: "")
                    mutableAttrStr.addAttributes([.font: headerKey.fontForPDF,
                                                  .paragraphStyle: headerKey.paraStyleForPDF()], range: NSRange(location: 0, length: mutableAttrStr.length))

                } else if let bulletKey = PianoBullet(type: .key, text: $0, selectedRange: NSRange(location: 0, length: 0)) {
                    if bulletKey.isOn {
                        mutableAttrStr.addAttributes(FormAttribute.strikeThroughAttr, range: NSRange(location: bulletKey.baselineIndex, length: mutableAttrStr.length - bulletKey.baselineIndex))
                    }

                    let bulletValueAttrStr = NSAttributedString(string: bulletKey.value, attributes: FormAttribute.formAttrForPDF)
                    mutableAttrStr.replaceCharacters(in: bulletKey.range, with: bulletValueAttrStr)
                    mutableAttrStr.addAttributes([.paragraphStyle: bulletKey.paraStyleForPDF()], range: NSRange(location: 0, length: mutableAttrStr.length))
                }

                while true {
                    guard let highlightKey = HighlightKey(text: mutableAttrStr.string, selectedRange: NSRange(location: 0, length: mutableAttrStr.length)) else { break }

                    mutableAttrStr.addAttributes([.backgroundColor: Color.highlight], range: highlightKey.range)
                    mutableAttrStr.replaceCharacters(in: highlightKey.endDoubleColonRange, with: "")
                    mutableAttrStr.replaceCharacters(in: highlightKey.frontDoubleColonRange, with: "")
                }

                mutableAttrStr.append(NSAttributedString(string: "\n", attributes: FormAttribute.defaultAttrForPDF))
                resultMutableAttrString.append(mutableAttrStr)
            }

            resultMutableAttrString.replaceCharacters(in: NSRange(location: resultMutableAttrString.length - 1, length: 1), with: "")

            DispatchQueue.main.async {
                let printFormatter = UISimpleTextPrintFormatter(attributedText: resultMutableAttrString)
                let renderer = UIPrintPageRenderer()
                renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
                // A4 size
                let pageSize = CGSize(width: 595.2, height: 841.8)

                // Use this to get US Letter size instead
                // let pageSize = CGSize(width: 612, height: 792)

                // create some sensible margins
                let pageMargins = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72)

                // calculate the printable rect from the above two
                let printableRect = CGRect(x: pageMargins.left, y: pageMargins.top, width: pageSize.width - pageMargins.left - pageMargins.right, height: pageSize.height - pageMargins.top - pageMargins.bottom)

                // and here's the overall paper rectangle
                let paperRect = CGRect(x: 0, y: 0, width: pageSize.width, height: pageSize.height)

                renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
                renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

                let pdfData = NSMutableData()

                UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
                renderer.prepare(forDrawingPages: NSRange(location: 0, length: renderer.numberOfPages))

                let bounds = UIGraphicsGetPDFContextBounds()

                for i in 0  ..< renderer.numberOfPages {
                    UIGraphicsBeginPDFPage()

                    renderer.drawPage(at: i, in: bounds)
                }

                UIGraphicsEndPDFContext()

                self.pdfView.document = PDFDocument(data: (pdfData as Data))
                self.pdfView.scaleFactor = self.view.bounds.width / 595.2
                self.pdfView.maxScaleFactor = 1.5
                self.pdfView.minScaleFactor = self.view.bounds.width / 700
                self.hideActivityIndicator()
            }
        }

        Analytics.logEvent(shareNote: note, format: "pdf")
    }
}
