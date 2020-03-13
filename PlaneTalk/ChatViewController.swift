//
//  ChatViewController.swift
//  SendiOS
//
//  Created by Annino De Petra on 14/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

protocol MessagePresenter: AnyObject {
	func show(chatMessage: ChatMessage)
}

final class ChatViewController: UIViewController {
	private enum Constant {
		static let navigatioBarBackgroundColor = UIColor(white: 0.96, alpha: 1)
		static let keyboardGap: CGFloat = 38
		static let viewBackgroundColor = UIColor(red: 246/255, green: 245/255, blue: 246/255, alpha: 1)
	}

	@IBOutlet private var tableView: UITableView!
	@IBOutlet private var textBoardViewContainerBottomConstraint: NSLayoutConstraint!
	@IBOutlet private var textBoardViewContainer: UIView! {
		didSet {
			textBoardView.delegate = self
			textBoardView.embed(into: textBoardViewContainer)
		}
	}

	private var textBoardView = TextBoardView.instantiateFromNib()
	private var manager: Manager?

	private var messages: [ChatMessage] = [] {
		didSet {
			tableView.reloadData()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		registerForKeyboard()
		addGestureRecognizer()
		setupUI()

		guard let connectedInterface = Connector.connect() else {
			assertionFailure("Error: interface not found")
			return
		}
		initialiseDeviceWith(connectedInterface)
	}

	private func initialiseDeviceWith(_ connectedInterface: Interface) {
		print("Connected to \(connectedInterface.name)")
		let currentDevice = Client(
			ip: connectedInterface.ip,
			broadcastIP: connectedInterface.broadcastIP
		)

		self.manager = Manager(currentDevice: currentDevice)
		manager?.presenter = self

		currentDevice.communicationDelegate = manager
		currentDevice.roleGrantDelegate = manager

		manager?.allowClientToUDPCommunication()
	}

	// MARK: - Utilities
	private func registerForKeyboard() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
	}

	@objc private func keyboardWillShow(_ notification: Notification!) {
		guard
			let userInfo = notification.userInfo,
			let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
			let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
		else {
			return
		}
		let constant = PlatformUtils.hasHomeIndicator ? (endFrame.height - Constant.keyboardGap) : endFrame.height
		setBottomConstraint(value: -constant, duration: duration)
	}

	@objc private func keyboardWillHide(_ notification: Notification!) {
		guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
			return
		}
		setBottomConstraint(value: 0, duration: duration)
	}

	private func setBottomConstraint(value constant: CGFloat, duration: Double) {
		let newBottomConstant = constant
		UIView.animate(withDuration: duration, animations: {
			self.textBoardViewContainerBottomConstraint.constant = newBottomConstant
			self.view.layoutIfNeeded()
		})
	}

	private func addGestureRecognizer() {
		let tap = UITapGestureRecognizer(target: self, action: #selector(didTapOnTableview))
		tableView.addGestureRecognizer(tap)
	}

	private func setupUI() {
		let messageTableViewCellNib = MessageTableViewCell.nib
		tableView.register(messageTableViewCellNib, forCellReuseIdentifier: MessageTableViewCell.reuseIdentifier)
		tableView.delegate = self
		tableView.dataSource = self

		view.backgroundColor = Constant.viewBackgroundColor
		navigationController?.navigationBar.backgroundColor = Constant.navigatioBarBackgroundColor
	}

	@objc private func didTapOnTableview() {
		view.endEditing(true)
	}
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return messages.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(for: indexPath) as MessageTableViewCell
		let chatMessage = messages[indexPath.row]
		let viewData = MessageTableViewCell.ViewData.from(chatMessage)
		cell.configure(with: viewData)
		return cell
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
	}
}

extension ChatViewController: MessagePresenter {
	func show(chatMessage: ChatMessage) {
		textBoardView.clearTextfield()
		messages.append(chatMessage)
	}
}

extension ChatViewController: TextBoardViewDelegate {
	func textBoard(_ textBoard: TextBoardView, didPressSendButtonWith text: String) {
		manager?.send(text)
		view.endEditing(true)
	}
}

extension MessageTableViewCell.ViewData {
	static func from(_ chatMessage: ChatMessage) -> MessageTableViewCell.ViewData {
		let textColor = chatMessage.isMe ? MessageTableViewCell.Constant.outgoingMessageTextColor : MessageTableViewCell.Constant.incomingMessageTextColor
		let backgroundColor = chatMessage.isMe ? MessageTableViewCell.Constant.outgoingMessageBubbleColor : MessageTableViewCell.Constant.incomingMessageBubbleColor

		return MessageTableViewCell.ViewData(
			sender: chatMessage.sender,
			text: chatMessage.text,
			textColor: textColor,
			backgroundColor: backgroundColor,
			alignment: chatMessage.isMe ? .right : .left
		)
	}
}
