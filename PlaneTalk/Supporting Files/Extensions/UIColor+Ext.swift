//
//  UIColor+Ext.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 18/04/2021.
//  Copyright © 2021 Annino De Petra. All rights reserved.
//

import UIKit

extension UIColor {
	convenience init(r: CGFloat, g: CGFloat, b: CGFloat, alpha: CGFloat = 1) {
		self.init(red: r/255, green: g/255, blue: b/255, alpha: alpha)
	}
}

extension UIColor {
	static let outgoingMessageBubbleColor = UIColor(r: 70, g: 181, b: 85)
	static let incomingMessageBubbleColor = UIColor(white: 0.972, alpha: 1)
	static let outgoingMessageTextColor = UIColor.white
	static let incomingMessageTextColor = UIColor.black
}
