//
//  UIColor-Extension.swift
//  JasperQuiz
//
//  Created by 木村祐太 on 2022/03/11.
//

import Foundation
import UIKit

extension UIColor {
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}
