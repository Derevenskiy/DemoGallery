//
//  UIViewExtensions.swift
//  DemoGallery
//
//  Created by Chernyshov Artem Alekseevich on 23.03.2024.
//

import UIKit

public extension UIView {
    func addSubviews(_ views: [UIView]) {
        views.forEach {
            addSubview($0)
        }
    }
}
