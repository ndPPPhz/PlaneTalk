//
//  Manager.swift
//  SendiOS
//
//  Created by Annino De Petra on 20/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

protocol ServerIPProvider: AnyObject {
	var serverIP: String? { get }
}

protocol CommunicationDelegate: AnyObject {
	func deviceDidReceiveBroadcastMessage(_ text: String, from sender: String)
	func deviceDidReceiveTCPText(_ text: String)
	func deviceDidSendText(_ text: String)

	// Ask the messageFactory to generate the
	func serverWantsToSendOwnTCPText(_ text: String) -> String
	func serverWantsToSendClientTCPText(_ text: String, senderIP: String) -> String

	func serverDidSendText(_ text: String)
	func serverDidSendClientText(_ text: String, clientIP: String)
	func serverDidSendInformationText(_ text: String)
	var discoveryServerString: String { get }
}

protocol ManagerDelegate: AnyObject {
	func askServerPermissions(_ device: Device)
}

final class Manager: ServerIPProvider {

	// The instance of the current device
	private var currentDevice: BroadcastDevice
	// If the current device is also the server, then this var wont be nil
	private var server: Server?
	// The serverIP as it's ServerIPProvider
	var serverIP: String?

	private let messageFactory: MessageFactory

	init(currentDevice: BroadcastDevice) {
		self.currentDevice = currentDevice
		self.messageFactory = MessageFactory(device: currentDevice)
	}

	var presenter: MessagePresenter?

	var isServer: Bool {
		return currentDevice.ip == serverIP
	}

	var isThereServer: Bool {
		return serverIP != nil
	}

	func send(_ message: String) {
		if
			!isServer,
			let client = currentDevice as? Client
		{
			client.sendToServerTCP(message)
		} else if
			let server = server,
			isServer
		{
			server.sendServerText(message)
		}
	}

	func allowClientToUDPCommunication() {
		// Open a socket, create a queue for handling the oncoming events, enable transmission of broadcast messages and find a server
		currentDevice.bindForUDPMessages()
		currentDevice.createBroadcastKqueue()
		currentDevice.enableTransmissionToBroadcast()
		currentDevice.findServer()
	}
}

extension Manager: CommunicationDelegate {
	func serverWantsToSendClientTCPText(_ text: String, senderIP: String) -> String {
		return messageFactory.generateClientMessageToBeSent(from: text, senderIP: senderIP)
	}

	// MARK: - UDP Broadcast
	func deviceDidReceiveBroadcastMessage(_ text: String, from sender: String) {
		// Generate Message
		let message = messageFactory.receivedUDPMessage(text, from: sender)
		// Since it's broadcast, you can receive your message back then skip it
		guard message.senderIP != currentDevice.ip else { return }

		if isServer {
			serverHasReceivedBroadcastMessage(message)
		} else {
			clientHasReceivedBroadcastMessage(message)
		}
	}

	private func serverHasReceivedBroadcastMessage(_ message: Message) {
		switch message.text {
		// If the server receives a discovery message it means that a new client wants to connect
		case messageFactory.discoveryMessage:
			// The server will reply sending back its IP
			let serverResponse = messageFactory.serverBroadcastAuthenticationResponse
			currentDevice.sendBroadcastMessage(serverResponse)
			print("New client " + message.senderIP)
		default:
			assertionFailure("Server has received an unknown message \(message.text)")
			break
		}
	}

	private func clientHasReceivedBroadcastMessage(_ message: Message) {
		switch message.text {
		// If it's the server response to the discovery message
		case let string where string.contains(messageFactory.serverBroadcastAuthenticationResponseTemplate):
			guard !isThereServer else {
				assertionFailure("A server is already available @ \(serverIP!)")
				return
			}

			// Save the server IP
			let serverIP = message.senderIP
			self.serverIP = serverIP
			print("Found out a server @ " + message.senderIP)

			// Unbind from the UDP port and connect to the server via TCP
			if let client = currentDevice as? Client {
				client.clearReceptionBroadcastKQueue()
				client.startTCPconnectionToServer(serverIP: serverIP)
			}
		default:
			assertionFailure("Client has received an unknown message \(message.text)")
			break
		}
	}

	// MARK: - TCP
	// Server
	func serverWantsToSendOwnTCPText(_ text: String) -> String {
		return messageFactory.generateServerOwnMessage(from: text)
	}

	func serverDidSendText(_ text: String) {
		let chatMessage = ChatMessage(text: text, sender: "Me", isMe: true)
		presentMessage(chatMessage: chatMessage)
	}

	func serverDidSendClientText(_ text: String, clientIP: String) {
		let chatMessage = ChatMessage(text: text, sender: clientIP, isMe: false)
		presentMessage(chatMessage: chatMessage)
	}

	func serverDidSendInformationText(_ text: String) {
		let chatMessage = ChatMessage(text: text, sender: "Information", isMe: false)
		presentMessage(chatMessage: chatMessage)
	}

	// Client
	func deviceDidReceiveTCPText(_ text: String) {
		let message = messageFactory.getTextAndServer(from: text)
		let chatMessage = ChatMessage(text: message.text, sender: message.senderIP, isMe: false)
		presentMessage(chatMessage: chatMessage)
	}

	var discoveryServerString: String {
		return messageFactory.discoveryMessage
	}

	func deviceDidSendText(_ text: String) {
		let chatMessage = ChatMessage(text: text, sender: "Me", isMe: true)
		presentMessage(chatMessage: chatMessage)
	}

	func presentMessage(chatMessage: ChatMessage) {
		DispatchQueue.main.async { [weak self] in
			guard let _self = self else { return }
			_self.presenter?.show(chatMessage: chatMessage)
		}
	}
}

extension Manager: ManagerDelegate {
	func askServerPermissions(_ device: Device) {
		// When a client claims to become the server, check if there is already a device which is the current server
		guard !isThereServer else {
			return
		}

		// The current device is about to become server.
		// Clear the queue of events
		currentDevice.clearReceptionBroadcastKQueue()
		// Set up your IP as serverIP
		serverIP = device.ip

		print(Constant.Message.presentMeAsServer)

		// Create an instance of the Server class
		let server = Server(ip: currentDevice.ip,
							broadcastIP: currentDevice.broadcastIP,
							udp_broadcast_message_socket: currentDevice.udp_broadcast_message_socket,
							udp_reception_message_socket: currentDevice.udp_reception_message_socket
		)

		self.server = server
		server.communicationDelegate = currentDevice.communicationDelegate
		currentDevice = server

		// Reenable the reception and transmission of the broadcast messages
		server.createBroadcastKqueue()
		server.enableTransmissionToBroadcast()
		// Create a TCP socket to accept clients requests
		server.createTCPSocket()
	}
}
