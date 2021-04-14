//
//  NetworkInterfaceConnector.swift
//  SendiOS
//
//  Created by Annino De Petra on 23/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

protocol InterfaceConnector {
	func connect() throws -> NetworkInterface
}

final class NetworkInterfaceConnector: InterfaceConnector {
	enum ConnectorError: Error {
		case noInterfaceAvailableFound
	}

	private let networkInterfaceProvider: NetworkInterfacesProviderInterface.Type
	private let priorityInterface: NetworkInterfaceType

	init(
		networkInterfaceProvider: NetworkInterfacesProviderInterface.Type = NetworkInterfacesProvider.self,
		priorityInterface: NetworkInterfaceType = .bridge
	) {
		self.networkInterfaceProvider = networkInterfaceProvider
		self.priorityInterface = priorityInterface
	}

	func connect() throws -> NetworkInterface {
		let availableInterfaces = networkInterfaceProvider.getAvailableInterfaces()

		let hotspotCondition: (NetworkInterface) -> Bool = { interface in
			return interface.name.contains(NetworkInterfaceType.bridge.rawValue)
		}

		let wlanCondition: (NetworkInterface) -> Bool = { interface in
			return interface.name == NetworkInterfaceType.wlan.rawValue
		}

		let priorityInterfaceCheck = priorityInterface == .bridge ? hotspotCondition : wlanCondition
		let secondaryInterfaceCheck = priorityInterface == .bridge ? wlanCondition : hotspotCondition

		if let mainInterface = availableInterfaces.first (where: priorityInterfaceCheck) {
			return mainInterface
		} else if let secondaryInterface = availableInterfaces.first (where: secondaryInterfaceCheck) {
			return secondaryInterface
		} else {
			throw ConnectorError.noInterfaceAvailableFound
		}
	}
}
