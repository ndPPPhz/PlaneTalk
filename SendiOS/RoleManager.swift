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

class RoleManager: ServerIPProvider {
	private(set) var serverIP: String?
	private(set) var currentDevice: Device
	private(set) var server: Server?

	init(currentDevice: Device) {
		self.currentDevice = currentDevice
	}

	var isServer: Bool {
		return currentDevice.ip == serverIP
	}

	var isThereServer: Bool {
		return serverIP != nil
	}

	private func setIPAsServer(_ IP: String) {
		assert(IP != currentDevice.ip)
		serverIP = IP
	}

	func send(_ message: String) {
		if !isServer, let client = currentDevice as? Client {
			client.sendToServerTCP(message)
		} else if let server = server, isServer {
			server.sendMessageViaTCP(message)
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
		// If a server discovery is coming, it means a new client wants to connect
		case Constant.serverDiscovery:
			// Will send my IP
			let serverResponse = Constant.serverResponse+currentDevice.ip
			currentDevice.sendBroadcastMessage(serverResponse)
			print("New client " + message.senderIP)
		default:
			break
		}
	}

	private func clientHasReceivedBroadcastMessage(_ message: Message) {
		switch message.text {
		case let string where string.contains(Constant.serverResponse):
			guard !isThereServer else {
				print("A server is already available")
				return
			}
			setIPAsServer(message.senderIP)
			print("Found out a server @ " + message.senderIP)
			if let client = currentDevice as? Client {
				client.clearReceptionBroadcastKQueue()
				client.startTCPconnectionToServer()
			}
		default:
			break
		}
	}
}

extension RoleManager: RoleGrantDelegate {
	func askServerPermissions(_ device: Device) {
		guard !isThereServer else {
			return
		}
		currentDevice.clearReceptionBroadcastKQueue()

		self.serverIP = device.ip
		print(Constant.Message.presentMeAsServer)

		let server = Server(ip: currentDevice.ip,
						udp_broadcast_message_socket: currentDevice.udp_broadcast_message_socket,
						udp_reception_message_socket: currentDevice.udp_reception_message_socket,
						networkInformationProvider: currentDevice.networkInformationProvider
		)
		self.server = server
		server.presenter = currentDevice.presenter
		server.broadcastMessagesDelegate = currentDevice.broadcastMessagesDelegate
		currentDevice = server

		server.createBroadcastKqueue()
		server.enableTransmissionToBroadcast()
		server.createTCPSocket()
	}
}
