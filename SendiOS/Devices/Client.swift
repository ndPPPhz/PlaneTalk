//
//  Client.swift
//  SendiOS
//
//  Created by Annino De Petra on 20/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

protocol MessagePresenter: AnyObject {
	func show(text: String)
}

class Client: Device {
	var ip: String

	var udp_broadcast_message_socket: Int32
	var udp_reception_message_socket: Int32
	var client_tcp_socket_fd: Int32

	lazy var tcpEventQueue = kqueue()
	var broadcastKQueue: Int32

	var networkInformationProvider: NetworkInformationProvider
	weak var roleGrantDelegate: RoleGrantDelegate?
	weak var broadcastMessagesDelegate: BroadcastMessagesDeviceDelegate?
	weak var serverIPProvider: ServerIPProvider?
	weak var presenter: MessagePresenter?

	init(ip: String, networkInformationProvider: NetworkInformationProvider) {
		self.ip = ip
		self.networkInformationProvider = networkInformationProvider
		udp_broadcast_message_socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
		udp_reception_message_socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
		client_tcp_socket_fd = socket(AF_INET, SOCK_STREAM, 0)
		broadcastKQueue = kqueue()
	}

	func startTCPconnectionToServer() {
		if (client_tcp_socket_fd == -1) {
			print("TCP Socket creation failed");
			exit(-1);
		}

		guard let serverIP = serverIPProvider?.serverIP else {
			print("You cannot connect to the server without a server")
			return
		}

		// The struct containing the address of the server (for the client)
		let server_tcp_sock_addr = generateTCPSockAddrIn(server_address: serverIP)

		let connect_return = withUnsafePointer(to: server_tcp_sock_addr) { tcpSocketAddressPtr -> Int32 in
			let rawTCPSocketAddressPtr = UnsafeRawPointer(tcpSocketAddressPtr).bindMemory(to: sockaddr.self, capacity: 1)
			let size = UInt32(MemoryLayout<sockaddr>.stride)
			return connect(client_tcp_socket_fd, rawTCPSocketAddressPtr, size)
		}

		if connect_return == -1 {
			print("Connect to the server via TCP failed");
			exit(-1)
		}

		print("Connected via TCP to the Server")
		createTCPKQueue()
	}

	private func createTCPKQueue() {
		if tcpEventQueue == -1 {
			 print("Error creating kqueue")
			 exit(EXIT_FAILURE)
		 }

		// Create the kevent structure that sets up our kqueue to listen
		// for notifications
		var sockKevent = kevent(
			ident: UInt(client_tcp_socket_fd),
			filter: Int16(EVFILT_READ),
			flags: UInt16(EV_ADD | EV_ENABLE),
			fflags: 0,
			data: 0,
			udata: nil
		)

		// This is where the kqueue is register with our
		// interest for the notifications described by
		// our kevent structure sockKevent
		kevent(tcpEventQueue, &sockKevent, 1, nil, 0, nil)
		tcpMessagesWatchLoop()
	}

	private func tcpMessagesWatchLoop() {
		DispatchQueue.global().async { [weak self] in
			while true {
				guard let _self = self else { return }
				var events: [kevent] = Array<kevent>(repeating: kevent(), count: 5)
				let status = kevent(_self.tcpEventQueue, nil, 0, &events, 1, nil)
				_self.receivedTCPConnectionStatus(status, socketKQueue: _self.tcpEventQueue, events: events)
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

				guard fd == client_tcp_socket_fd else {
					print("Message from an unknown socket")
					return
				}

				if (Int32(event.flags) & EV_EOF == EV_EOF) {
					var sockKevent = kevent(
						ident: UInt(fd),
						filter: Int16(EVFILT_READ),
						flags: UInt16(EV_DELETE),
						fflags: 0,
						data: 0,
						udata: nil
					)

					if kevent(tcpEventQueue, &sockKevent, 1, nil, 0, nil) == -1 {
						print("Kevent error")
					}

					print("Server disconnected")
					close(Int32(fd))
				} else {
					handleReceivedTCPMessage(socket: Int32(fd))
				}
			}
		default:
			print("Error reading kevent")
			close(socketKQueue)
			exit(EXIT_FAILURE)
		}
	}

	private func handleReceivedTCPMessage(socket: Int32) {
		let receivedStringBuffer = UnsafeMutableBufferPointer<CChar>.allocate(capacity: 65536)
		let receivedStringBufferRawPointer = UnsafeMutableRawPointer(receivedStringBuffer.baseAddress)

		let returnBytes = recv(socket, receivedStringBufferRawPointer, 65536, 0)

		guard
			let baseAddress = receivedStringBuffer.baseAddress,
			returnBytes > 0
		else {
			print("Nothing to read from the buffer")
			return
		}

		let string = String(cString: UnsafePointer(baseAddress))
		print("Received by the server: \(string)")
		presenter?.show(text: string)

	}

	func sendToServerTCP(_ text: String) {
		text.withCString { cstr -> Void in
			var server_tcp_sock_addr = sockaddr_in()

			// assign IP, PORT
			server_tcp_sock_addr.sin_family = sa_family_t(AF_INET)
			server_tcp_sock_addr.sin_addr.s_addr = inet_addr(serverIPProvider?.serverIP)
			server_tcp_sock_addr.sin_port = htons(value: 8010);

			let sentBytes: Int = withUnsafePointer(to: &server_tcp_sock_addr) {
				let tcpMessageLength = Int(strlen(cstr))
				let p = UnsafeRawPointer($0).bindMemory(to: sockaddr.self, capacity: 1)
				return sendto(client_tcp_socket_fd, cstr, tcpMessageLength, 0, p, UInt32(MemoryLayout<sockaddr_in>.stride))
			}

			guard sentBytes > 0 else {
				print("Error while sending")
				return
			}
			print("Sent to the server: \(text)")
			presenter?.show(text: text)
		}
	}
}
