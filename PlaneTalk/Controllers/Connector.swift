//
//  Connector.swift
//  SendiOS
//
//  Created by Annino De Petra on 23/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

final class Connector {
	private let availableInterfaces: [Interface]

	init(availableInterfaces: [Interface]) {
		self.availableInterfaces = availableInterfaces
	}

	func connect() -> Interface? {
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
