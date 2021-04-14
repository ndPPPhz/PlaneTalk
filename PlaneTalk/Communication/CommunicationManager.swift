//
//  CommunicationManager.swift
//  SendiOS
//
//  Created by Annino De Petra on 20/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

protocol GrantRoleDelegate: AnyObject {
	func deviceClaimingServerPermission()
}

protocol ManagerInterface {
	func startCommunication() throws
	func send(_ message: String)
}

final class CommunicationManager: ManagerInterface {
	enum Constant {
		static let serverDiscovery = "CHAT-SERVER-DISCOVERY"
		static let serverResponse = "CHAT-SERVER-RESPONSE"
		static let separator = "-/-"
	}
	
	enum CommunicationManagerError: Error {
		case broadcastNotAvailable
	}
	
	private var deviceType: DeviceType = .client
	private var currentDevice: Device?
	private var serverIP: String?

	weak var presenter: MessagePresenter?

	private let networkInterfaceConnector: InterfaceConnector
	private let propagationQueue: DispatchQueue

	private var broadcastManager: BroadcastInterface?
	private var clientCommunicationManager: ClientCommunicationInterface?
	private var serverCommunicationManager: ServerCommunicationInterface?

	var broadcastManagerFactory: ((String) -> BroadcastInterface)?
	var clientCommunicationManagerFactory: ((String) -> ClientCommunicationInterface)?
	var serverCommunicationManagerFactory: ((String) -> ServerCommunicationInterface)?
	var broadcastMessagesInterpreter: BroadcastMessageInterpreter?

	init(
		networkInterfaceConnector: InterfaceConnector = NetworkInterfaceConnector(),
		propagationQueue: DispatchQueue = .main
	) {
		self.networkInterfaceConnector = networkInterfaceConnector
		self.propagationQueue = propagationQueue
		NotificationCenter.default.addObserver(self, selector: #selector(closeAll), name: Notification.Name("applicationWillTerminate"), object: nil)
	}

	// MARK: - ManagerInterface
	func startCommunication() throws {
		// Find an interface and connect to it
		let connectedInterface = try networkInterfaceConnector.connect()
		print("Connected to \(connectedInterface.name)")

		guard let broadcastManager = broadcastManagerFactory?(connectedInterface.broadcastIP) else {
			throw CommunicationManagerError.broadcastNotAvailable
		}

		// Create a device object with the information retrieved by the connected network interface
		let currentDevice = Device(
			ip: connectedInterface.ip
		)
		self.currentDevice = currentDevice

		broadcastManager.enableReceptionAndTransmissionUDPMessages()
		broadcastManager.findServer()
		self.broadcastManager = broadcastManager
	}

	func send(_ message: String) {
		switch deviceType {
		case .client:
			clientCommunicationManager?.sendTextToServer(message)
		case .server:
			serverCommunicationManager?.sendServerMessage(message)
		}
	}

	// MARK: - Utilities
	private func presentMessage(chatMessage: ChatMessage) {
		propagationQueue.async { [weak self] in
			self?.presenter?.show(chatMessage: chatMessage)
		}
	}

	@objc func closeAll() {
		broadcastManager?.closeUDPSockets()
		clientCommunicationManager?.closeCommunication()
		serverCommunicationManager?.closeAll()
	}
}

// MARK: - BroadcastMessagingDelegate
extension CommunicationManager: BroadcastMessagingDelegate {
	// A new broadcast message has arrived
	func deviceDidReceiveBroadcastMessage(_ text: String, from sender: String) {
		guard let currentDeviceIP = currentDevice?.ip else {
			print("No current device ip")
			return
		}

		// Since it's broadcast, you can receive your message back then skip it
		guard sender != currentDeviceIP else { return }
		print("Device received broadcast message \(text)")

		if deviceType == .server {
			serverHasReceivedBroadcastText(text, serverIP: currentDeviceIP, senderIP: sender)
		} else {
			clientHasReceivedBroadcastText(text, senderIP: sender)
		}
	}

	// Server has received a client message
	private func serverHasReceivedBroadcastText(_ text: String, serverIP: String, senderIP: String) {
		guard let broadcastMessagesInterpreter = broadcastMessagesInterpreter else {
			print("Nil broadcastMessagesInterpreter")
			return
		}

		guard
			let broadcastMessageType = type(of: broadcastMessagesInterpreter).isValidBroadcastText(text),
			broadcastMessageType == .serverDiscovery
		else {
			assertionFailure("Server has received an unknown message \(text) from: \(senderIP)")
			return
		}

		// The server will reply sending back a response
		broadcastManager?.sendBroadcastMessage(Constant.serverResponse)
		print("New client " + senderIP)
	}

	// Client has received a server message
	private func clientHasReceivedBroadcastText(_ text: String, senderIP: String) {
		guard let broadcastMessagesInterpreter = broadcastMessagesInterpreter else {
			print("Nil broadcastMessagesInterpreter")
			return
		}

		guard
			let broadcastMessageType = type(of: broadcastMessagesInterpreter).isValidBroadcastText(text),
			broadcastMessageType == .serverResponse
		else {
			assertionFailure("Server has received an unknown message \(text) from: \(senderIP)")
			return
		}

		guard serverIP == nil else {
			assertionFailure("Found an already set ServerIP")
			return
		}

		// Save the server IP
		serverIP = senderIP
		print("Found out a server @ " + senderIP)

		// Unbind from the UDP port and connect to the server via TCP
		broadcastManager?.closeUDPSockets()
		deviceType = .client

		guard let clientCommunicationManager = clientCommunicationManagerFactory?(senderIP) else {
			assertionFailure("Unable to initialise a client communication manager")
			return
		}

		clientCommunicationManager.startTCPconnectionToServer()
		self.clientCommunicationManager = clientCommunicationManager
	}
}

// MARK: - ServerCommunicationDelegate
extension CommunicationManager: ServerCommunicationDelegate {
	// Server did send its text
	func serverDidSendItsText(_ text: String) {
		let senderAndText = text.components(separatedBy: Constant.separator)
		let chatMessage = ChatMessage(text: senderAndText[1], senderAlias: "Me", isMyMessage: true)
		presentMessage(chatMessage: chatMessage)
	}

	// Server did send a client text
	func serverDidSendClientText(_ text: String, senderIP: String) {
		print("Showing \(text)")
		let chatMessage = ChatMessage(text: text, senderAlias: senderIP, isMyMessage: false)
		presentMessage(chatMessage: chatMessage)
	}
}

// MARK: - ClientCommunicationDelegate
extension CommunicationManager: ClientCommunicationDelegate {
	func clientDidReceiveMessage(_ text: String) {
		let senderAndText = text.components(separatedBy: Constant.separator)
		let sender = senderAndText[0]
		let text = senderAndText[1]
		let chatMessage = ChatMessage(text: text, senderAlias: sender, isMyMessage: false)
		presentMessage(chatMessage: chatMessage)
	}

	func clientDidSendMessage(_ text: String) {
		let chatMessage = ChatMessage(text: text, senderAlias: "Me", isMyMessage: true)
		presentMessage(chatMessage: chatMessage)
	}

	func clientDidLoseConnectionWithServer() {
		clientCommunicationManager = nil
		broadcastManager = nil
		serverIP = nil
		currentDevice = nil
		
		do {
			print("Retrying start communication")
			try startCommunication()
		} catch {
			print("Unable to re-establish a connection. Error: \(error.localizedDescription)")
		}
	}
}

extension CommunicationManager: GrantRoleDelegate {
	func deviceClaimingServerPermission() {
		// When a client claims to become the server, check if there is already a device which is the current server
		guard
			serverIP == nil,
			let currentDeviceIP = currentDevice?.ip
		else {
			return
		}

		// Set up your IP as serverIP
		serverIP = currentDeviceIP
		print("Hello. I'm the server. Start spreading the news")
		deviceType = .server

		// Create a TCP socket to accept clients requests
		guard let serverCommunicationManager = serverCommunicationManagerFactory?(currentDeviceIP) else {
			assertionFailure("Unable to initialise a server communication manager")
			return
		}
		
		serverCommunicationManager.enableTCPCommunication()
		self.serverCommunicationManager = serverCommunicationManager
	}
}
