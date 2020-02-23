//
//  RoleManager.swift
//  SendiOS
//
//  Created by Annino De Petra on 20/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

protocol ServerIPProvider: AnyObject {
	var serverIP: String? { get }
}

protocol BroadcastMessagesDeviceDelegate: AnyObject {
	func deviceDidReceiveMessage(message: Message)
}

protocol RoleGrantDelegate: AnyObject {
	func askServerPermissions(_ device: Device)
}

final class RoleManager: ServerIPProvider {

	// The instance of the current device
	private var currentDevice: BroadcastDevice
	// If the current device is also the server, then this var wont be nil
	private var server: Server?
	// The serverIP as it's ServerIPProvider
	var serverIP: String?

	init(currentDevice: BroadcastDevice) {
		self.currentDevice = currentDevice
	}

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
			server.sendServerMessage(message)
		}
	}
}

extension RoleManager: BroadcastMessagesDeviceDelegate {
	func deviceDidReceiveMessage(message: Message) {
		// Don't receive myself broadcast messages
		guard message.senderIP != currentDevice.ip else { return }

		if isServer {
			serverHasReceivedBroadcastMessage(message)
		} else {
			clientHasReceivedBroadcastMessage(message)
		}
	}

	private func serverHasReceivedBroadcastMessage(_ message: Message) {
		// From other devices
		switch message.text {
		// If a server discovery message is coming, it means a new client wants to connect
		case Constant.serverDiscovery:
			// The server will reply sending back its IP
			let serverResponse = Constant.serverResponse + currentDevice.ip
			currentDevice.sendBroadcastMessage(serverResponse)
			print("New client " + message.senderIP)
		default:
			break
		}
	}

	private func clientHasReceivedBroadcastMessage(_ message: Message) {
		// The client has received a message
		switch message.text {
		// If it's from the server
		case let string where string.contains(Constant.serverResponse):
			guard !isThereServer else {
				print("A server is already available")
				return
			}
			// Save the server IP
			serverIP = message.senderIP

			print("Found out a server @ " + message.senderIP)

			// Unbind from the UDP port and connect to the server via TCP
			if let client = currentDevice as? Client {
				client.clearReceptionBroadcastKQueue()
				client.startTCPconnectionToServer()
			}
		default:
			// Reject any other broadcast message
			break
		}
	}
}

extension RoleManager: RoleGrantDelegate {
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
		server.presenter = currentDevice.presenter
		server.broadcastMessagesDelegate = currentDevice.broadcastMessagesDelegate
		currentDevice = server

		// Reenable the reception and transmission of the broadcast messages
		server.createBroadcastKqueue()
		server.enableTransmissionToBroadcast()
		// Create a TCP socket to accept clients requests
		server.createTCPSocket()
	}
}
