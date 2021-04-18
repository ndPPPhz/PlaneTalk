//
//  MessageTableViewCell.swift
//  SendiOS
//
//  Created by Annino De Petra on 23/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

final class MessageTableViewCell: UITableViewCell, NibLoadable {
	enum Constant {
		static let labelMargin: CGFloat = 24
		static let cornerRadiusRatio: CGFloat = 0.08
	}

	@IBOutlet private var senderLabel: UILabel!
	@IBOutlet private var messageLabel: UILabel!
	@IBOutlet private var messageLabelLeadingConstraint: NSLayoutConstraint!
	@IBOutlet private var senderLabelTopConstraint: NSLayoutConstraint!
	@IBOutlet private var messageLabelBottomConstraint: NSLayoutConstraint!
	@IBOutlet private var messageLabelTrailingConstraint: NSLayoutConstraint!

	private let messageBubbleView = UIView()

	override func awakeFromNib() {
		super.awakeFromNib()
		setupCell()
	}

	private func setupCell() {
		// Set margins via code
		messageLabelLeadingConstraint.constant = Constant.labelMargin
		messageLabelBottomConstraint.constant = Constant.labelMargin
		messageLabelTrailingConstraint.constant = Constant.labelMargin

		messageBubbleView.translatesAutoresizingMaskIntoConstraints = false
		contentView.insertSubview(messageBubbleView, belowSubview: messageLabel)

		messageBubbleView.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor, constant: -Constant.labelMargin / 2).isActive = true
		messageBubbleView.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: Constant.labelMargin / 2).isActive = true
		messageBubbleView.topAnchor.constraint(equalTo: senderLabel.topAnchor, constant: -Constant.labelMargin / 2).isActive = true
		messageBubbleView.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: Constant.labelMargin / 2).isActive = true

		selectionStyle = .none
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		messageBubbleView.layer.cornerRadius = frame.height * Constant.cornerRadiusRatio
		if senderLabel.intrinsicContentSize.width > messageLabel.intrinsicContentSize.width {
			messageBubbleView.trailingAnchor.constraint(
				equalTo: senderLabel.trailingAnchor,
				constant: Constant.labelMargin / 2
			).isActive = true
		}
	}
}

extension MessageTableViewCell {
	struct ViewData: Equatable {
		enum Alignment: Equatable {
			case left, right
		}

		let sender: String
		let text: String
		let textColor: UIColor
		let backgroundColor: UIColor
		let alignment: Alignment
	}
}

extension MessageTableViewCell: ViewDataConfigurable {
	func configure(with viewData: MessageTableViewCell.ViewData) {
		messageLabel.text = viewData.text
		messageBubbleView.backgroundColor = viewData.backgroundColor
		messageLabel.textColor = viewData.textColor
		senderLabel.text = viewData.sender

		switch viewData.alignment {
		case .left:
			messageLabelLeadingConstraint.isActive = true
			messageLabelTrailingConstraint.isActive = false
		case .right:
			messageLabelLeadingConstraint.isActive = false
			messageLabelTrailingConstraint.isActive = true
		}
	}
}
