//
//  ChatViewController.swift
//  SendiOS
//
//  Created by Annino De Petra on 14/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

final class ChatViewController: UIViewController {
	private enum Constant {
		static let navigatioBarBackgroundColor = UIColor(white: 0.96, alpha: 1)
		static let keyboardGap: CGFloat = 38
		static let viewBackgroundColor = UIColor(red: 246/255, green: 245/255, blue: 246/255, alpha: 1)
	}

	@IBOutlet private var tableView: UIChatTableView!
	@IBOutlet private var textBoardViewContainerBottomConstraint: NSLayoutConstraint!
	@IBOutlet private var textBoardViewContainer: UIView! {
		didSet {
			textBoardView.delegate = self
			textBoardView.embed(into: textBoardViewContainer)
		}
	}

	@IBOutlet private var overlayView: UIView!
	@IBOutlet weak var connectViewContainerView: UIView! {
		didSet {
			connectView.embed(into: connectViewContainerView)
		}
	}

	private lazy var connectView: ConnectView = {
		let connectView = UINib(nibName: "ConnectView", bundle: .main).instantiate(withOwner: nil, options: nil).first as! ConnectView
		return connectView
	}()

	private var textBoardView = TextBoardView.instantiateFromNib()
	private var viewModel: ChatViewModelInterface?

	private var messages: [ChatMessage] = [] {
		didSet {
			tableView.reloadDataWithCompletion { [weak self] in
				guard let _self = self else { return }

				// When the content height is bigger that the tableview frame's height, it means that the
				// content is exceeding the table view frame (id est the visible space) and then
				// scroll to the bottom
				let difference = _self.tableView.contentSize.height - _self.tableView.frame.height
				if difference > 0 {
					_self.tableView.setContentOffset(CGPoint(x: 0, y: difference), animated: false)
				}
			}
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		registerForKeyboard()
		addGestureRecognizer()
		setupUI()
		start()
	}

	private func start() {
		let manager = CommunicationManager()
		let broadcastMessageFactory = BroadcastMessageFactory()

		let chatViewModel = ChatViewModel(manager: manager)

		let broadcastManagerFactory : (String) -> BroadcastInterface = { broadcastIP in
			let broadcastManager = BroadcastManager(broadcastIP: broadcastIP, messageFactory: broadcastMessageFactory)
			broadcastManager.broadcastMessagingDelegate = manager
			broadcastManager.grantRoleDelegate = manager
			return broadcastManager
		}

		let clientCommunicationManagerFactory: (String) -> ClientCommunicationInterface = { serverIP in
			let clientCommunicationManager = ClientCommunicationManager(serverIP: serverIP)
			clientCommunicationManager.clientCommunicationDelegate = chatViewModel
			clientCommunicationManager.clientConnectionDelegate = manager
			return clientCommunicationManager
		}

		let serverCommunicationManagerFactory: (String) -> ServerCommunicationInterface = { serverIP in
			let serverMessageFactory = ServerMessageFactory(serverIP: serverIP)
			let serverCommunicationManager = ServerCommunicationManager(
				serverMessageFactory: serverMessageFactory
			)
			serverCommunicationManager.serverTCPCommunicationDelegate = chatViewModel
			return serverCommunicationManager
		}

		manager.broadcastManagerFactory = broadcastManagerFactory
		manager.clientCommunicationManagerFactory = clientCommunicationManagerFactory
		manager.serverCommunicationManagerFactory = serverCommunicationManagerFactory
		manager.broadcastMessagesInterpreter = broadcastMessageFactory
		manager.delegate = chatViewModel

		chatViewModel.enableCommunication()
		chatViewModel.presenter = self
		chatViewModel.delegate = self
		
		viewModel = chatViewModel
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

		let searchButtonViewData = ConnectView.ViewData.ButtonViewData(
			title: "Search server",
			color: .white,
			backgroundColor: .init(red: 32/255, green: 99/255, blue: 155/255, alpha: 1),
			tapHanlder: { [weak self] in
				self?.connectView.showActivityIndicator(true)
				self?.viewModel?.searchServer()
			}
		)

		let serverButtonViewData = ConnectView.ViewData.ButtonViewData(
			title: "Become server",
			color: .white,
			backgroundColor: .init(red: 32/255, green: 99/255, blue: 155/255, alpha: 1),
			tapHanlder: { [weak self] in
				self?.viewModel?.askServerPermissions()
				self?.hideOverlay()
			}
		)

		connectView.configure(
			with: .init(
				searchButtonViewData: searchButtonViewData,
				serverButtonViewData: serverButtonViewData
			)
		)
	}

	private func hideOverlay() {
		overlayView.isHidden = true
		connectViewContainerView.isHidden = true
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

extension ChatViewController: ChatViewModelDelegate {
	func didFindServer() {
		connectView.showActivityIndicator(false)
		hideOverlay()
		viewModel?.connectToServer()
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
		viewModel?.send(text)
		view.endEditing(true)
	}
}

extension MessageTableViewCell.ViewData {
	static func from(_ chatMessage: ChatMessage) -> MessageTableViewCell.ViewData {
		let textColor = chatMessage.isMyMessage ? MessageTableViewCell.Constant.outgoingMessageTextColor : MessageTableViewCell.Constant.incomingMessageTextColor
		let backgroundColor = chatMessage.isMyMessage ? MessageTableViewCell.Constant.outgoingMessageBubbleColor : MessageTableViewCell.Constant.incomingMessageBubbleColor

		return MessageTableViewCell.ViewData(
			sender: chatMessage.senderAlias,
			text: chatMessage.text,
			textColor: textColor,
			backgroundColor: backgroundColor,
			alignment: chatMessage.isMyMessage ? .right : .left
		)
	}
}
