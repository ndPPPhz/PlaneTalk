//
//  InterfaceFinder.swift
//  SendiOS
//
//  Created by Annino De Petra on 20/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

final class InterfaceFinder {
	static func getAvailableInterfaces() -> [Interface] {
		var availableInterfaces: [Interface] = []
		let interface_address = ifaddrs()

		// Get all the interfaces
		withUnsafePointer(to: interface_address) { interfaceAddressPtr in
			let unsafePtr: UnsafeMutablePointer?  = UnsafeMutablePointer(mutating: interfaceAddressPtr)
			withUnsafePointer(to: unsafePtr) { doubleInterfaceAddressPtr in
				let interfacesAddressPtrToPrt: UnsafeMutablePointer? = UnsafeMutablePointer(mutating: doubleInterfaceAddressPtr)

				// Returns 0 if is ok and doubleInterfaceAddressPtr will containt a struct with the first int and a link to the next one
				guard getifaddrs(interfacesAddressPtrToPrt) == 0 else {
					return
				}

				guard var interfaceAddress = interfacesAddressPtrToPrt?.pointee?.pointee else {
					return
				}

				// Iterate through all the interfaces
				repeat {
					// Change at the end the current interface with the pointer of the next one if exists
					defer {
						interfaceAddress = interfaceAddress.ifa_next.pointee
					}

					guard let interfaceName = interfaceAddress.ifa_name else {
						continue
					}

					let interface = String(cString: interfaceName)

					if interface.contains(Constant.Interface.hotspot) || interface == Constant.Interface.wlan {
						guard
							let destinationAddress = UnsafeRawPointer(interfaceAddress.ifa_dstaddr)?.bindMemory(to: sockaddr_in.self, capacity: 1),
							let myAddress = UnsafeRawPointer(interfaceAddress.ifa_addr)?.bindMemory(to: sockaddr_in.self, capacity: 1)
						else {
							continue
						}
						let broadcastIPString = String(cString: inet_ntoa(destinationAddress.pointee.sin_addr))
						let currentDeviceIPString = String(cString: inet_ntoa(myAddress.pointee.sin_addr))

						let newInterface = Interface(name: interface, ip: currentDeviceIPString, broadcastIP: broadcastIPString)
						availableInterfaces.append(newInterface)
					}
				} while interfaceAddress.ifa_next != nil
			}
		}
		return availableInterfaces
	}
}
