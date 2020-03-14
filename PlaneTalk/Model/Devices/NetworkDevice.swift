//
//  NetworkDevice.swift
//  SendiOS
//
//  Created by Annino De Petra on 20/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

protocol NetworkDevice: AnyObject {
	var ip: String { get }
}
