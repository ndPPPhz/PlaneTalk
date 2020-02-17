//
//  ViewController.swift
//  SendiOS
//
//  Created by Annino De Petra on 14/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

enum Constant {
	static let serverDiscovery = "CHAT-SERVER-DISCOVERY"
	static let serverResponse = "CHAT-SERVER-RESPONSE-"

	enum Message {
		static let searchingServer = "Searching a server nearby"
		static let presentMeAsServer = "Hello. I'm the server. Start spreading the news"
	}
}

func htons(value: CUnsignedShort) -> CUnsignedShort {
    return (value << 8) + (value >> 8)
}

class ViewController: UIViewController {

	@IBOutlet private var textViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet private var tableView: UITableView!
	@IBOutlet private var textView: UITextView!

	private var roleManager: RoleManager!
	private var networkInformationProvider: NetworkInformationProvider?

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

		retrieveNetworkInformation()

		roleManager.currentDevice.bindForUDPMessages()
		roleManager.currentDevice.createBroadcastKqueue()
		
		roleManager.currentDevice.enableTransmissionToBroadcast()
		roleManager.currentDevice.findServer()
	}

	private func retrieveNetworkInformation() {
		let availableInterfaces = InterfaceFinder.getAvailableInterfaces()
		connectToInterface(availableInterfaces)
	}

	private func connectToInterface(_ interfaces: [Interface]) {
		let hotspotCondition: (Interface) -> Bool = { interface in
			return interface.name.contains("bridge")
		}

		let wlanCondition: (Interface) -> Bool = { interface in
			return interface.name == "en0"
		}

		let foundInterfaceClosure: (Interface) -> Void = { interface in
			print("Connected to \(interface.name)")
			let currentDevice = Client(ip: interface.ip, networkInformationProvider: interface)
			self.roleManager = RoleManager(currentDevice: currentDevice)
			currentDevice.broadcastMessagesDelegate = self.roleManager
			currentDevice.roleGrantDelegate = self.roleManager
			currentDevice.serverIPProvider = self.roleManager
			currentDevice.presenter = self
			self.networkInformationProvider = interface
		}

		// First check if the hotstop is available then wlan
		if let hotspotInterface = interfaces.first (where: hotspotCondition) {
			foundInterfaceClosure(hotspotInterface)
		} else if let wlanInterface = interfaces.first (where: wlanCondition) {
			foundInterfaceClosure(wlanInterface)
		} else {
			print("Error: interface not found")
			exit(-1)
		}
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

		UIView.animate(withDuration: duration, delay: 0, options: [], animations: {
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
		roleManager.send(textView.text)
		view.endEditing(true)
	}
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return messages.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
		cell.textLabel?.text = messages[indexPath.row]
		return cell
	}


}

extension Notification {
	/// Returns the frame of the keyboard.
	///
	/// - Note: If the keyboard is hidden due to a hardware keyboard then its
	///         height remains the same but it's just hidden offscreen with a Y offset.
	public var keyboardFrame: CGRect {
		guard let userInfo = userInfo, let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
			return .zero
		}

		return keyboardFrame
	}
}

extension ViewController: MessagePresenter {
	func show(text: String) {
		addNewMessage(text)
	}
}
