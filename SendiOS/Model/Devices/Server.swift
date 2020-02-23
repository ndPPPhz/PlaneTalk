//
//  Server.swift
//  SendiOS
//
//  Created by Annino De Petra on 20/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

final class Server: BroadcastDevice {
	weak var roleGrantDelegate: RoleGrantDelegate?
	weak var broadcastMessagesDelegate: BroadcastMessagesDeviceDelegate?
	weak var presenter: MessagePresenter?

	// Server udp broadcast socket
	let udp_broadcast_message_socket: Int32
	// Server udp reception socket
	let udp_reception_message_socket: Int32

	// Incoming TCP connections socket
	private var incoming_tcp_connections_socket: Int32 = -1

	// Kqueue to organise broadcast events
	lazy var broadcastKQueue: Int32 = kqueue()
	// Kqueue to organise tcp events
	private let tcpKQueue: Int32 = kqueue()

	// Map of the fd and their IPs
	private var connectionSockets: [Int32: User] = [:]
	// Array of all the kevents
	private var kEvents: [kevent] = []

	let maxListeningConnections: Int32 = 5

	private var nickname: String?
	var ip: String
	var broadcastIP: String

	init(
		ip: String,
		broadcastIP: String,
		udp_broadcast_message_socket: Int32,
		udp_reception_message_socket: Int32
	) {
		self.ip = ip
		self.broadcastIP = broadcastIP
		self.udp_broadcast_message_socket = udp_broadcast_message_socket
		self.udp_reception_message_socket = udp_reception_message_socket
	}

	func createTCPSocket() {
		incoming_tcp_connections_socket = socket(AF_INET, SOCK_STREAM, 0)
		if (incoming_tcp_connections_socket == -1) {
			print("socket creation failed...\n");
			exit(-1);
		}

		let incoming_client_tcp_sock_addr = generateReceiverSockAddrInTemplate(port: tcpPort)

		// Binding
		let bindReturn = withUnsafePointer(to: incoming_client_tcp_sock_addr) { tcp_sock_addr_ptr -> Int32 in
			let r = UnsafeRawPointer(tcp_sock_addr_ptr).bindMemory(to: sockaddr.self, capacity: 1)
			return bind(incoming_tcp_connections_socket, r, UInt32(MemoryLayout<sockaddr_in>.stride))
		}

		guard bindReturn == 0 else {
			print("Couldn't bind the device to the TCP port")
			exit(-1)
		}

		let listenReturn = listen(incoming_tcp_connections_socket, maxListeningConnections)

		guard listenReturn == 0 else {
			print("Couldn't listen to the TCP port")
			exit(-1)
		}

		print("Created TCP socket. Server awaiting")
		createIncomingConnectionsSocketKQueue()
	}

	private func createIncomingConnectionsSocketKQueue() {
		if tcpKQueue == -1 {
			 print("Error creating kqueue")
			 exit(EXIT_FAILURE)
		 }

		// Create the kevent structure that sets up our kqueue to listen
        // for notifications
        var sockKevent = kevent(
            ident: UInt(incoming_tcp_connections_socket),
            filter: Int16(EVFILT_READ),
            flags: UInt16(EV_ADD | EV_ENABLE),
            fflags: 0,
            data: 0,
            udata: nil
        )

		// This is where the kqueue is register with our
		 // interest for the notifications described by
		 // our kevent structure sockKevent
		 kevent(tcpKQueue, &sockKevent, 1, nil, 0, nil)

		watchEvents()
	}

	private func watchEvents() {
        DispatchQueue.global(qos: .default).async { [weak self] in
			guard let _self = self else { return }
			var events: [kevent] = Array<kevent>(repeating: kevent(), count: 5)
            while true {
				let status = kevent(_self.tcpKQueue, nil, 0, &events, 1, nil)
				_self.receivedTCPConnectionStatus(status, socketKQueue: _self.tcpKQueue, events: events)
            }
        }
	}

	private func receivedTCPConnectionStatus(_ status: Int32, socketKQueue: Int32, events: [kevent]) {
		switch status {
		case 0:
			print("Timeout")
		case 1...:
			for i in 0..<status {
				let event = events[Int(i)]
				let fd = event.ident
				if (Int32(event.flags) & EV_EOF == EV_EOF) {
					var sockKevent = kevent(
						ident: UInt(fd),
						filter: Int16(EVFILT_READ),
						flags: UInt16(EV_DELETE),
						fflags: 0,
						data: 0,
						udata: nil
					)

					if kevent(tcpKQueue, &sockKevent, 1, nil, 0, nil) == -1 {
						print("Kevent error")
					}
					print("Bye bye socket \(fd)")
					if let index = kEvents.lastIndex(where: { $0.ident == fd }) {
						kEvents.remove(at: index)
						connectionSockets.removeValue(forKey: Int32(fd))
					}
					close(Int32(fd))
				} else if incoming_tcp_connections_socket == fd {
					handleNewConnection()
				} else if let fd_and_user = connectionSockets.first(where: ({ $0.key == fd })) {
					incomingMessage(socket: fd_and_user.key, user: fd_and_user.value)
				}
			}
		default:
			print("Error reading kevent")
			close(socketKQueue)
			exit(EXIT_FAILURE)
		}
	}

	private func handleNewConnection() {
		let client_address = sockaddr_in()
		let connection_socket_and_client_ip: (fd: Int32, IP: String) = withUnsafePointer(to: client_address) { client_address_ptr -> (Int32, String) in
			let raw_client_address_ptr = UnsafeRawPointer(client_address_ptr).bindMemory(to: sockaddr.self, capacity: 1)
			let mutable_raw_client_address_ptr = UnsafeMutablePointer(mutating: raw_client_address_ptr)
			var size = UInt32(MemoryLayout<sockaddr>.stride)
			let connection_fd = accept(incoming_tcp_connections_socket, mutable_raw_client_address_ptr, &size)
			let clientIP = String(cString: inet_ntoa(client_address_ptr.pointee.sin_addr))
			return (connection_fd, clientIP)
		}

		if connection_socket_and_client_ip.fd < 0 {
			exit(-1)
		}

		connectionSockets[connection_socket_and_client_ip.fd] = User(IP: connection_socket_and_client_ip.IP)

		// Create the kevent structure that sets up our kqueue to listen
        // for notifications
        var sockKevent = kevent(
			ident: UInt(connection_socket_and_client_ip.fd),
            filter: Int16(EVFILT_READ),
            flags: UInt16(EV_ADD | EV_ENABLE),
            fflags: 0,
            data: 0,
            udata: nil
        )

		kEvents.append(sockKevent)

		kevent(tcpKQueue, &sockKevent, 1, nil, 0, nil)
		print("TCP Connection accepted")
	}

	// A message from a client is coming
	private func incomingMessage(socket: Int32, user: User) {
		let receivedStringBuffer = UnsafeMutableBufferPointer<CChar>.allocate(capacity: 65536)
		let rawPointer = UnsafeMutableRawPointer(receivedStringBuffer.baseAddress)

		let read_return = recv(socket, rawPointer, 65536, 0)

		guard
			let baseAddress = receivedStringBuffer.baseAddress,
			read_return > 0
		else {
			return
		}
		let string = String(cString: UnsafePointer(baseAddress))
		// Handle the message in order to understand whether is a standard message or a nick change request
		handleClientMessage(string, socket: socket, user: user)
	}

	private func handleClientMessage(_ string: String, socket: Int32, user: User) {
		// Check if it's a nickname change request
		if let newNickname = checkPossibleChangeNicknameRegex(in: string) {
			connectionSockets[socket]?.changeNickname(newNickname)
			sendMessageToEveryone("\(user.IP) is now \(newNickname)")
		} else {
			let sender = user.nickname == nil ? user.IP : user.nickname!
			sendClientMessage("\(sender): \(string)", clientSocket: socket)
		}
	}

	// Send the message of the client whose socket is clientSocket to all of the other clients
	private func sendClientMessage(_ message: String, clientSocket: Int32) {
		for event in kEvents where event.ident != UInt(clientSocket) {
			let fd = event.ident

			message.withCString { cString in
				let messageLength = Int(strlen(cString))
				let bytes = send(Int32(fd), cString, messageLength, 0)
				if bytes < 0 {
					print("Error sending TCP Message")
				} else {
					print("Propagated by the server to socket \(clientSocket)")
				}
			}
		}
		presenter?.show(text: message)
	}

	func sendServerMessage(_ message: String) {
		// Check if it's a nickname change request
		if let newNickname = checkPossibleChangeNicknameRegex(in: message) {
			nickname = newNickname
			sendMessageToEveryone("\(ip) is now \(newNickname)")
		} else {
			let serverAlias = nickname == nil ? ip : nickname!
			let messageForEveryone = "\(serverAlias): \(message)"

			for event in kEvents {
				let fd = event.ident

				messageForEveryone.withCString { cString in
					let messageLength = Int(strlen(cString))
					let bytes = send(Int32(fd), cString, messageLength, 0)
					if bytes < 0 {
						print("Error sending TCP Message")
					} else {
						print("Sent by server: \(message)")
						presenter?.show(text: message)
					}
				}
			}
		}
	}

	func sendMessageToEveryone(_ message: String) {
		for event in kEvents {
			let fd = event.ident

			message.withCString { cString in
				let messageLength = Int(strlen(cString))
				let bytes = send(Int32(fd), cString, messageLength, 0)
				if bytes < 0 {
					print("Error sending TCP Message")
				} else {
					print("Sent by server: \(message)")
					presenter?.show(text: message)
				}
			}
		}
	}

	private func checkPossibleChangeNicknameRegex(in string: String) -> String? {
		let regexRange = NSRange(string.startIndex..., in: string)

		guard
			let regex = try? NSRegularExpression(pattern: Constant.nicknameRegex),
			let match = regex.matches(in: string, range: regexRange).first
		else {
			return nil
		}

		let matchRange = match.range(at: 1)

		guard matchRange != NSRange(location: NSNotFound, length: 0) else {
			print("Regex error")
			return nil
		}
		let nickname = (string as NSString).substring(with: matchRange)
		return nickname
	}
}