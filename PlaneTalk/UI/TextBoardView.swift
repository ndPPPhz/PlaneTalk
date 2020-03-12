//
//  TextBoardView.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 12/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

protocol TextBoardViewDelegate: AnyObject {
	func textBoard(_ textBoard: TextBoardView, didPressSendButtonWith text: String)
}

final class TextBoardView: UIView, NibLoadable {
	enum Constant {
		static let blueButtonColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
		static let disabledButtonColor = UIColor(white: 0.85, alpha: 1)
		static let textViewBorderColor = UIColor(white: 0.88, alpha: 1)
		static let textViewInset: CGFloat = 8
		static let textViewBorderWidth: CGFloat = 1
	}

	@IBOutlet private var sendButton: UIButton!
	@IBOutlet private var textView: UITextView!

	weak var delegate: TextBoardViewDelegate?

	override func awakeFromNib() {
		super.awakeFromNib()
		sendButton.layer.cornerRadius = sendButton.frame.height / 2
		sendButton.backgroundColor = Constant.disabledButtonColor

		textView.layer.cornerRadius = textView.frame.height * 0.35
		textView.layer.borderWidth = Constant.textViewBorderWidth
		textView.layer.borderColor = Constant.textViewBorderColor.cgColor
		textView.textContainerInset.left = Constant.textViewInset
		textView.textContainerInset.right = Constant.textViewInset
		textView.delegate = self
	}
	
	func clearTextfield() {
		textView.text = ""
	}

	@IBAction func didTapSendButton(_ sender: Any) {
		delegate?.textBoard(self, didPressSendButtonWith: textView.text)
	}
}

extension TextBoardView: UITextViewDelegate {
	func textViewDidChange(_ textView: UITextView) {
		sendButton.isEnabled = !textView.text.isEmpty
		sendButton.backgroundColor = sendButton.isEnabled ? Constant.blueButtonColor : Constant.disabledButtonColor
	}
}
