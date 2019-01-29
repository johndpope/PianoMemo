//
//  ImagePreviewVC_business.swift
//  Piano
//
//  Created by Kevin Kim on 25/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

extension ImagePreviewViewController {
    internal func showImage() {
        //백그라운드 쓰레드로 PDF 만들고, 메인쓰레드에서는 인디케이터 표시해주고, 완료되면 performSegue로 보내서 확인시키고 그다음 전달하자
        showActivityIndicator()

        DispatchQueue.global().async { [weak self] in
            guard let self = self,
                let strArray = self.note.content?.components(separatedBy: .newlines) else { return }

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
                let portraitMargin: CGFloat = 30
                let landscapeMargin: CGFloat = 20
                let width = UIScreen.main.bounds.width - landscapeMargin * 2
                var rect = resultMutableAttrString.boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                rect.origin.x += landscapeMargin
                rect.origin.y += portraitMargin
                let size = CGSize(width: rect.size.width + landscapeMargin * 2, height: rect.size.height + portraitMargin * 2)
                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                resultMutableAttrString.draw(in: rect)
                let image = UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysOriginal)
                guard let jpegData = image?.jpegData(compressionQuality: 1) else { return }

                self.jpegData = jpegData

                self.hideActivityIndicator()
                return
            }

        }
    }
}
