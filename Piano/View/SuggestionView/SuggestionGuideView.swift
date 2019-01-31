//
//  SuggestionGuideView.swift
//  Piano
//
//  Created by Kevin Kim on 29/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class SuggestionGuideView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!

}

extension SuggestionGuideView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }
}
