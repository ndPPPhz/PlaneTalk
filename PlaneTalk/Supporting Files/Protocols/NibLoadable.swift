//
//  NibLoadable.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 12/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

// MARK: - NibLoadable
/// A protocol for objects that have a default Nib file from which they can be
/// unarchived. By default the Nib file should have the same name as the type.
public protocol NibLoadable: AnyObject {
	static var nibName: String { get }
	static var nibBundle: Bundle { get }
}

extension NibLoadable {
	public static var nibName: String {
		return String(describing: self)
	}

	public static var nibBundle: Bundle {
		return Bundle.main
	}

	public static var nib: UINib {
		return UINib(nibName: nibName, bundle: nibBundle)
	}

	public static func instantiateFromNib() -> Self {
		let decodedObjects = nib.instantiate(withOwner: nil, options: nil)
		return decodedObjects.first(elementOfType: Self.self)!
	}
}

extension NibLoadable where Self: UIView {
	public static func instantiateFromNib(
		embeddedInto containerView: UIView,
		withInsets insets: UIEdgeInsets = .zero,
		shouldConstrainToSafeArea: Bool = false
	) -> Self {
		let view = Self.instantiateFromNib()
		view.embed(into: containerView, withInsets: insets, shouldConstrainToSafeArea: shouldConstrainToSafeArea)
		return view
	}
}
