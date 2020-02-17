//
//  Server.swift
//  SendiOS
//
//  Created by Annino De Petra on 20/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

class Server: Device {
	var networkInformationProvider: NetworkInformationProvider
	weak var roleGrantDelegate: RoleGrantDelegate?
	weak var broadcastMessagesDelegate: BroadcastMessagesDeviceDelegate?
	weak var presenter: MessagePresenter?

	let udp_broadcast_message_socket: Int32
	let udp_reception_message_socket: Int32

	private var incoming_tcp_connections_socket: Int32 = -1

	var broadcastKQueue: Int32
	private let tcpKQueue = kqueue()

	private var connectionSockets: [Int32] = []
	private var kEvents: [kevent] = []

	let maxListeningConnections: Int32 = 5

	var ip: String

	init(
		ip: String,
		udp_broadcast_message_socket: Int32,
		udp_reception_message_socket: Int32,
		networkInformationProvider: NetworkInformationProvider
	) {
		self.ip = ip
		self.udp_broadcast_message_socket = udp_broadcast_message_socket
		self.udp_reception_message_socket = udp_reception_message_socket
		self.networkInformationProvider = networkInformationProvider
		broadcastKQueue = kqueue()
	}

	func createTCPSocket() {
		incoming_tcp_connections_socket = socket(AF_INET, SOCK_STREAM, 0)
		if (incoming_tcp_connections_socket == -1) {
			print("socket creation failed...\n");
			exit(-1);
		}

		var incoming_client_tcp_sock_addr = sockaddr_in()

		// assign IP, PORT
		incoming_client_tcp_sock_addr.sin_family = sa_family_t(AF_INET)
		incoming_client_tcp_sock_addr.sin_addr.s_addr = INADDR_ANY
		incoming_client_tcp_sock_addr.sin_port = htons(value: 8010);

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
					}
					close(Int32(fd))
				} else if incoming_tcp_connections_socket == fd {
					handleNewConnection()
				} else if let fd = connectionSockets.first(where: ({ $0 == fd })) {
					incomingMessage(socket: fd)
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
		let connection_socket = withUnsafePointer(to: client_address) { client_address_ptr -> Int32 in
			let raw_client_address_ptr = UnsafeRawPointer(client_address_ptr).bindMemory(to: sockaddr.self, capacity: 1)
			let mutable_raw_client_address_ptr = UnsafeMutablePointer(mutating: raw_client_address_ptr)
			var size = UInt32(MemoryLayout<sockaddr>.stride)
			let connection_fd = accept(incoming_tcp_connections_socket, mutable_raw_client_address_ptr, &size)
			return connection_fd
		}

		if connection_socket < 0 {
			exit(-1)
		}

		connectionSockets.append(connection_socket)

		// Create the kevent structure that sets up our kqueue to listen
        // for notifications
        var sockKevent = kevent(
            ident: UInt(connection_socket),
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

	private func incomingMessage(socket: Int32) {
		let receivedStringBuffer = UnsafeMutableBufferPointer<CChar>.allocate(capacity: 65536)
		let rawPointer = UnsafeMutableRawPointer(receivedStringBuffer.baseAddress)

		let sender = sockaddr_in()
		withUnsafePointer(to: sender) { receiverAddressPtr in
			let r = UnsafeRawPointer(receiverAddressPtr).bindMemory(to: sockaddr.self, capacity: 1)
			let mutR: UnsafeMutablePointer<sockaddr> = UnsafeMutablePointer.init(mutating: r)
			var l = UInt32(MemoryLayout<sockaddr_in>.stride)

			let read_return = recv(socket, rawPointer, 65536, 0)

			guard
				let baseAddress = receivedStringBuffer.baseAddress,
				read_return > 0
			else {
				return
			}

			if getsockname(socket, mutR, &l) == 0 {
				let sockAddrPtr = UnsafeRawPointer(mutR).bindMemory(to: sockaddr_in.self, capacity: 1)
				let sender = String(cString: inet_ntoa(sockAddrPtr.pointee.sin_addr))
				print(sender)
			}
			let string = String(cString: UnsafePointer(baseAddress))
			sendMessageViaTCPWithAddress(string, addressSocket: socket)
		}
	}

	private func sendMessageViaTCPWithAddress(_ message: String, addressSocket: Int32) {
		for event in kEvents where event.ident != UInt(addressSocket) {
			let fd = event.ident

			message.withCString { cString in
				let messageLength = Int(strlen(cString))
				let bytes = send(Int32(fd), cString, messageLength, 0)
				if bytes < 0 {
					print("Error sending TCP Message")
				} else {
					print("Propagated by the server to socket \(addressSocket)")
				}
			}
		}
		presenter?.show(text: message)
	}

	func sendMessageViaTCP(_ message: String) {
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
}
