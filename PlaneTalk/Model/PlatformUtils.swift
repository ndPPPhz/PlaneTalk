//
//  PlatformUtils.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 12/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

public protocol PlatformUtilsProtocol {
	var isiPhone: Bool { get }
	var isiPad: Bool { get }
	static var hasHomeIndicator: Bool { get }
}

public class PlatformUtils: PlatformUtilsProtocol {
	public init() {}

	enum Constant {
		/// The height of the iPhone X and iPhone XS and iPhone 11 Pro in pixels.
		private static let iPhoneXHeight = 2436
		/// The height of the iPhone XS Max and iPhone 11 Pro Max in pixels.
		private static let iPhoneXSMaxHeight = 2688
		/// The height of the iPhone XR and iPhone 11 in pixels.
		private static let iPhoneXRHeight = 1792
		/// The height of the 11-inch iPad Pro (2018) in pixels.
		private static let iPadPro11InchHeight = 2388
		/// The width of the 11-inch iPad Pro (2018) in pixels.
		private static let iPadPro11InchWidth = 1668
		/// The height of the 12.9-inch iPad Pro (2018) in pixels.
		private static let iPadPro12_9InchHeight = 2732
		/// The width of the 12.9-inch iPad Pro (2018) in pixels.
		private static let iPadPro12_9InchWidth = 2048

		static let heightsOfiPhonesWithHomeIndicators = [
			Constant.iPhoneXHeight,
			Constant.iPhoneXSMaxHeight,
			Constant.iPhoneXRHeight,
		]
		static let heightsAndWidthsOfiPadsWithHomeIndicators = [
			Constant.iPadPro11InchHeight,
			Constant.iPadPro11InchWidth,
			Constant.iPadPro12_9InchHeight,
			Constant.iPadPro12_9InchWidth,
		]
	}

	public var isiPhone: Bool {
		return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone
	}

	public var isiPad: Bool {
		return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
	}

	public static var hasHomeIndicator: Bool = {
		return isiPhoneX || isiPadWithHomeIndicator
	}()

	public static var isiPadWithHomeIndicator: Bool = {
		return isCurrentHeight(containedIn: Constant.heightsAndWidthsOfiPadsWithHomeIndicators)
	}()

	public static var isiPhoneX: Bool = {
		return isCurrentHeight(containedIn: Constant.heightsOfiPhonesWithHomeIndicators)
	}()

	private static func isCurrentHeight(containedIn heights: [Int]) -> Bool {
		guard let preferredModeHeight = UIScreen.main.preferredMode?.size.height else {
			return false
		}
		return heights.contains(Int(preferredModeHeight))
	}

	public var platform: String {
		if isiPhone {
			return "iPhone"
		} else if isiPad {
			return "iPad"
		} else {
			return "unknown"
		}
	}
}

