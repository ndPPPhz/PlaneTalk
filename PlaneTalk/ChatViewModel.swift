//
//  ChatViewModel.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 17/04/2021.
//  Copyright © 2021 Annino De Petra. All rights reserved.
//

import Foundation

protocol ChatViewModelInterface {
	func enableCommunication()
	func searchServer()
	func connectToServer()
	func askServerPermissions()
	func send(_ message: String)
}

protocol MessagePresenter: AnyObject {
	func show(chatMessage: ChatMessage)
}

protocol ChatViewModelDelegate: AnyObject {
	func didFindServer()
	func clientDidLeave()
}

final class ChatViewModel: ChatViewModelInterface {
	enum Constant {
		static let separator = "-/-"
	}

	private let propagationQueue: DispatchQueue
	private let manager: ManagerInterface & GrantRoleDelegate
	weak var presenter: MessagePresenter?
	weak var delegate: ChatViewModelDelegate?
	
	init(
		manager: ManagerInterface & GrantRoleDelegate,
		propagationQueue: DispatchQueue = .main
	) {
		self.manager = manager
		self.propagationQueue = propagationQueue
	}

	func enableCommunication() {
		do {
			try manager.enableCommunication()
		} catch {
			// propagate error
		}
	}

	func searchServer() {
		manager.searchServer()
	}

	func askServerPermissions() {
		manager.deviceClaimingServerPermission()
	}

	func connectToServer() {
		manager.connectToServer()
	}

	func send(_ message: String) {
		manager.send(message)
	}
}

extension ChatViewModel: ManagerDelegate {
	func managerDidFindServer(_ serverIP: String) {
		delegate?.didFindServer()
	}

	func clientDidLeave() {
		delegate?.clientDidLeave()
	}
}

// MARK: - ServerCommunicationDelegate
extension ChatViewModel: ServerCommunicationDelegate {
	// Server did send its text
	func serverDidSendItsText(_ text: String) {
		let senderAndText = text.components(separatedBy: Constant.separator)
		let chatMessage = ChatMessage(text: senderAndText[1], senderAlias: "Me", isSentByMe: true)
		presentMessage(chatMessage: chatMessage)
	}

	// Server did send a client text
	func serverDidSendClientText(_ text: String, senderIP: String) {
		print("Showing \(text)")
		let chatMessage = ChatMessage(text: text, senderAlias: senderIP, isSentByMe: false)
		presentMessage(chatMessage: chatMessage)
	}
}

extension ChatViewModel: ClientCommunicationDelegate {
	func clientDidReceiveMessage(_ text: String) {
		let senderAndText = text.components(separatedBy: Constant.separator)
		let sender = senderAndText[0]
		let text = senderAndText[1]
		let chatMessage = ChatMessage(text: text, senderAlias: sender, isSentByMe: false)
		presentMessage(chatMessage: chatMessage)
	}

	func clientDidSendMessage(_ text: String) {
		let chatMessage = ChatMessage(text: text, senderAlias: "Me", isSentByMe: true)
		presentMessage(chatMessage: chatMessage)
	}

	private func presentMessage(chatMessage: ChatMessage) {
		propagationQueue.async { [weak self] in
			self?.presenter?.show(chatMessage: chatMessage)
		}
	}
}

