//
//  Connector.swift
//  SendiOS
//
//  Created by Annino De Petra on 23/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

protocol ConnectorInterface {
	static func connect() -> Interface?
}

final class Connector: ConnectorInterface {
	static func connect() -> Interface? {
		let availableInterfaces = retrieveNetworkInformation()
		return connectToInterface(availableInterfaces)
	}

	private static func retrieveNetworkInformation() ->  [Interface] {
		return InterfaceFinder.getAvailableInterfaces()
	}

	private static func connectToInterface(_ availableInterfaces: [Interface]) -> Interface? {
		let hotspotCondition: (Interface) -> Bool = { interface in
			return interface.name.contains(Constant.Interface.hotspot)
		}

		let wlanCondition: (Interface) -> Bool = { interface in
			return interface.name == Constant.Interface.wlan
		}

		// First check if the hotstop is available then wlan
		if let hotspotInterface = availableInterfaces.first (where: hotspotCondition) {
			return hotspotInterface
		} else if let wlanInterface = availableInterfaces.first (where: wlanCondition) {
			return wlanInterface
		} else {
			return nil
		}
	}
}
