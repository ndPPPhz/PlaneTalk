//
//  ChatViewController.swift
//  SendiOS
//
//  Created by Annino De Petra on 14/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

protocol MessagePresenter: AnyObject {
	func show(text: String, isMine: Bool)
}

final class ChatViewController: UIViewController {
	enum Constant {
		static let navigatioBarBackgroundColor = UIColor(white: 0.96, alpha: 1)
		static let keyboardGap: CGFloat = 38
		static let viewBackgroundColor = UIColor(red: 246/255, green: 245/255, blue: 246/255, alpha: 1)
		static let outgoingMessageBubbleColor = UIColor(red: 70/255, green: 181/255, blue: 85/255, alpha: 1)
		static let incomingMessageBubbleColor = UIColor(white: 0.972, alpha: 1)
	}

	@IBOutlet private var tableView: UITableView!
	@IBOutlet private var textBoardViewContainerBottomConstraint: NSLayoutConstraint!
	@IBOutlet private var textBoardViewContainer: UIView! {
		didSet {
			textBoardView.embed(into: textBoardViewContainer)
		}
	}

	private var textBoardView = TextBoardView.instantiateFromNib()
	private var roleManager: RoleManager?

	private var messages: [(String, Bool)] = [
		("Hello guys", true),
		("What are you doing", false),
		("I'm wasting my time here at home watching tv series and nothing else. I would like to hang out with some friends to be honest", true),
		("You're fucking ridicolous cause you don't know exactly lorem ipsum dolet and you cannot be called developer if you dont know it. What's wrong with out dummy engineer", false),
		("Hello guys", true),
		("What are you doing", false),
		("I'm wasting my time here at home watching tv series and nothing else. I would like to hang out with some friends to be honest", true),
		("You're fucking ridicolous cause you don't know exactly lorem ipsum dolet and you cannot be called developer if you dont know it. What's wrong with out dummy engineer", false),
		("Hello guys", true),
		("What are you doing", false),
		("I'm wasting my time here at home watching tv series and nothing else. I would like to hang out with some friends to be honest", true),
		("You're fucking ridicolous cause you don't know exactly lorem ipsum dolet and you cannot be called developer if you dont know it. What's wrong with out dummy engineer", false),
	] {
		didSet {
			tableView.reloadData()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		registerForKeyboard()
		addGestureRecognizer()
		setupUI()

		navigationController?.navigationBar.backgroundColor = Constant.navigatioBarBackgroundColor
		let availableInterfaces = retrieveNetworkInformation()
//		connectToInterface(availableInterfaces)
	}

	private func retrieveNetworkInformation() ->  [Interface] {
		let availableInterfaces = InterfaceFinder.getAvailableInterfaces()
		return availableInterfaces
	}

	private func connectToInterface(_ interfaces: [Interface]) {
		let connector = Connector(availableInterfaces: interfaces)
		guard let connectedInterface = connector.connect() else {
			print("Error: interface not found")
			return
		}
		print("Connected to \(connectedInterface.name)")
		initialiseDeviceWith(connectedInterface)
	}

	private func initialiseDeviceWith(_ connectedInterface: Interface) {
		let currentDevice = Client(
			ip: connectedInterface.ip,
			broadcastIP: connectedInterface.broadcastIP
		)

		self.roleManager = RoleManager(currentDevice: currentDevice)
		currentDevice.broadcastMessagesDelegate = roleManager
		currentDevice.roleGrantDelegate = roleManager
		currentDevice.serverIPProvider = roleManager
		currentDevice.presenter = self

		// Open a socket, create a queue for handling the oncoming events, enable transmission of broadcast messages and find a server
		currentDevice.bindForUDPMessages()
		currentDevice.createBroadcastKqueue()
		currentDevice.enableTransmissionToBroadcast()
		currentDevice.findServer()
	}

	private func addNewMessage(_ message: String, isMine: Bool) {
		DispatchQueue.main.async { [weak self] in
		   guard let _self = self else { return }
			_self.textBoardView.clearTextfield()
		   _self.messages.append((message, isMine))
		}
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
		let constant = PlatformUtils.hasHomeIndicator ? -(endFrame.height - Constant.keyboardGap) : endFrame.height
		setBottomConstraint(constant, duration: duration)
	}

	@objc private func keyboardWillHide(_ notification: Notification!) {
		guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
			return
		}
		setBottomConstraint(0, duration: duration)
	}

	private func setBottomConstraint(_ constant: CGFloat, duration: Double) {
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
		let cell = tableView.dequeueReusableCell(withIdentifier: "BubbleView", for: indexPath) as! MessageTableViewCell


		let message = messages[indexPath.row]
		let viewData = MessageTableViewCell.ViewData(
			text: message.0, textColor: message.1 ? .white : .black,
			backgroundColor: message.1 ? Constant.outgoingMessageBubbleColor : Constant.incomingMessageBubbleColor,
			alignment: message.1 ? .right : .left
		)

		cell.configure(with: viewData)
		return cell
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
	}
}

extension ChatViewController: MessagePresenter {
	func show(text: String, isMine: Bool) {
		addNewMessage(text, isMine: isMine)
	}
}

extension ChatViewController: TextBoardViewDelegate {
	func textBoard(_ textBoard: TextBoardView, didPressSendButtonWith text: String) {
		roleManager?.send(text)
		view.endEditing(true)
	}
}
