//
//  MessageTableViewCell.swift
//  SendiOS
//
//  Created by Annino De Petra on 23/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

class MessageTableViewCell: UITableViewCell {

	@IBOutlet var messageLabel: UILabel!
	private let shapeLayer = CAShapeLayer()

	func configureWithText(_ text: String) {
		messageLabel.text = text
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		// Setup round rect mask
		var roundedRect = bounds
		roundedRect.size = CGSize(width: messageLabel.intrinsicContentSize.width + 16, height: messageLabel.intrinsicContentSize.height + 16)

		
		shapeLayer.path = UIBezierPath(roundedRect: roundedRect, cornerRadius: (messageLabel.intrinsicContentSize.height + 16) * 0.2).cgPath
		layer.mask = shapeLayer
	}

}
