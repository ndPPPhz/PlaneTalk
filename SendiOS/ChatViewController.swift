//
//  ChatViewController.swift
//  SendiOS
//
//  Created by Annino De Petra on 14/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

protocol MessagePresenter: AnyObject {
	func show(text: String)
}

final class ChatViewController: UIViewController {
	@IBOutlet private var textViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet private var tableView: UITableView!
	@IBOutlet private var textView: UITextView!

	private var roleManager: RoleManager?

	private var messages: [String] = [] {
		didSet {
			tableView.reloadData()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		registerForKeyboard()
		addGestureRecognizer()
		setupTableview()

		let availableInterfaces = retrieveNetworkInformation()
		connectToInterface(availableInterfaces)
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
		let currentDevice = Client(ip: connectedInterface.ip,
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

	private func addNewMessage(_ message: String) {
		DispatchQueue.main.async { [weak self] in
		   guard let _self = self else { return }
		   _self.textView.text = ""
		   _self.messages.insert(message, at: 0)
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
		setBottomConstraint(endFrame.height, duration: duration)
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
			self.textViewBottomConstraint.constant = newBottomConstant
			self.view.layoutIfNeeded()
		}, completion: nil)
	}

	private func addGestureRecognizer() {
		let tap = UITapGestureRecognizer(target: self, action: #selector(didTapOnTableview))
		tableView.addGestureRecognizer(tap)
	}

	private func setupTableview() {
		tableView.delegate = self
		tableView.dataSource = self
	}

	@objc private func didTapOnTableview() {
		view.endEditing(true)
	}

	@IBAction func didTapSendButton(_ sender: Any) {
		roleManager?.send(textView.text)
		view.endEditing(true)
	}
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return messages.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
		cell.textLabel?.text = messages[indexPath.row]
		return cell
	}
}

extension ChatViewController: MessagePresenter {
	func show(text: String) {
		addNewMessage(text)
	}
}
