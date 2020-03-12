//
//  UIView+Ext.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 12/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

extension UIView {
	/// Initializes a UIView with a given background color.
	///
	/// - Parameter backgroundColor: The background color of the view.
	public convenience init(backgroundColor: UIColor) {
		self.init()
		self.backgroundColor = backgroundColor
	}
}

extension UIView {
	public func setHidden(_ isHidden: Bool, ifNeeded: Bool = false) {
		guard !ifNeeded || isHidden != self.isHidden else { return }
		self.isHidden = isHidden
	}

	public var firstResponder: UIResponder? {
		if isFirstResponder {
			return self
		} else {
			// NOTE: Do not use lazy higher order functions for this until SR-5754 is
			// resolved. https://bugs.swift.org/browse/SR-5754
			// See also: https://repl.it/repls/DecimalFailingEngineers (reproducible case)
			for subview in subviews {
				if let firstResponder = subview.firstResponder {
					return firstResponder
				}
			}
			return nil
		}
	}

	public func applyClippingCornerRadius(
		ofSize size: CGFloat,
		rasterizationScale: CGFloat? = UIScreen.main.scale
	) {
		layer.masksToBounds = true
		layer.shouldRasterize = rasterizationScale != nil
		layer.rasterizationScale = rasterizationScale ?? 1
		layer.cornerRadius = size
		clipsToBounds = true
	}

	public func applyClippingCornerRadius(
		ofSize size: CGFloat,
		corners: CACornerMask,
		shouldRasterize: Bool = true,
		rasterizationScale: CGFloat? = UIScreen.main.scale
	) {
		layer.cornerRadius = size
		layer.maskedCorners = corners
		layer.masksToBounds = true
		layer.shouldRasterize = rasterizationScale != nil
		layer.rasterizationScale = rasterizationScale ?? 1
		clipsToBounds = true
	}
}

// MARK: -

extension UIView {
	typealias LayoutExtendedAttribute = (attribute: NSLayoutConstraint.Attribute, inset: CGFloat)

	public func embed(into superview: UIView, withInsets insets: UIEdgeInsets = .zero, shouldConstrainToSafeArea: Bool = false) {
		removeFromSuperview()
		superview.addSubview(self)
		embedAddedSubview(into: superview, withInsets: insets, shouldConstrainToSafeArea: shouldConstrainToSafeArea)
	}

	public func embedToMargins(into superview: UIView, withInsets insets: UIEdgeInsets, shouldConstrainToSafeArea: Bool = false) {
		removeFromSuperview()
		superview.addSubview(self)
		embedAddedSubviewToMargins(into: superview, withInsets: insets, shouldConstrainToSafeArea: shouldConstrainToSafeArea)
	}

	public func embed(
		into superview: UIView,
		position: Int,
		withInsets insets: UIEdgeInsets = .zero,
		shouldConstrainToSafeArea: Bool = false
	) {
		removeFromSuperview()
		superview.insertSubview(self, at: position)
		embedAddedSubview(into: superview, withInsets: insets, shouldConstrainToSafeArea: shouldConstrainToSafeArea)
	}

	public func embed(
		into superview: UIView,
		above: UIView,
		withInsets insets: UIEdgeInsets = .zero,
		shouldConstrainToSafeArea: Bool = false
	) {
		removeFromSuperview()
		superview.insertSubview(self, aboveSubview: above)
		embedAddedSubview(into: superview, withInsets: insets, shouldConstrainToSafeArea: shouldConstrainToSafeArea)
	}

	public func embed(
		into superview: UIView,
		below: UIView,
		withInsets insets: UIEdgeInsets = .zero,
		shouldConstrainToSafeArea: Bool = false
	) {
		removeFromSuperview()
		superview.insertSubview(self, belowSubview: below)
		embedAddedSubview(into: superview, withInsets: insets, shouldConstrainToSafeArea: shouldConstrainToSafeArea)
	}

	public func embedXCentered(
		into superview: UIView,
		topInset: CGFloat = 0,
		bottomInset: CGFloat = 0,
		offsetX: CGFloat = 0,
		offsetY: CGFloat = 0
	) {
		removeFromSuperview()
		superview.addSubview(self)
		let attributes: [LayoutExtendedAttribute] = [
			(.centerX, offsetX),
			(.centerY, offsetY),
			(.top, topInset),
			(.bottom, -bottomInset)
		]
		embedAddedSubview(into: superview, attributes: attributes)
	}

	public func embedYCentered(
		into superview: UIView,
		rightInset: CGFloat = 0,
		leftInset: CGFloat = 0,
		offsetY: CGFloat = 0
	) {
		removeFromSuperview()
		superview.addSubview(self)
		let attributes: [LayoutExtendedAttribute] = [
			(.left, leftInset),
			(.right, -rightInset),
			(.centerY, offsetY)
		]
		embedAddedSubview(into: superview, attributes: attributes)
	}

	public func embedXYCentered(
		into superview: UIView,
		offsetX: CGFloat = 0,
		offsetY: CGFloat = 0
	) {
		removeFromSuperview()
		superview.addSubview(self)
		let attributes: [LayoutExtendedAttribute] = [
			(.centerX, offsetX),
			(.centerY, offsetY)
		]
		embedAddedSubview(into: superview, attributes: attributes)
	}

	/// Embeds the current view in a container view, with the specified insets.
	///
	/// - Parameter insets: The insets between the current view and the
	///						container.
	/// - Returns: A container view, which contains `self` as an embedded view.
	public func embeddedInContainerView(withInsets insets: UIEdgeInsets) -> UIView {
		let containerView = UIView()
		embed(into: containerView, withInsets: insets)
		return containerView
	}

	// MARK: - Private

	private func embedAddedSubview(
		into superview: UIView,
		withInsets insets: UIEdgeInsets,
		shouldConstrainToSafeArea: Bool = false
	) {
		let attributes: [LayoutExtendedAttribute] = [
			(.top, insets.top),
			(.bottom, -insets.bottom),
			(.left, insets.left),
			(.right, -insets.right)
		]
		embedAddedSubview(into: superview, attributes: attributes, shouldConstrainToSafeArea: shouldConstrainToSafeArea)
	}

	private func embedAddedSubviewToMargins(
		into superview: UIView,
		withInsets insets: UIEdgeInsets,
		shouldConstrainToSafeArea: Bool = false
	) {
		let attributes: [LayoutExtendedAttribute] = [
			(.topMargin, insets.top),
			(.bottomMargin, -insets.bottom),
			(.leftMargin, insets.left),
			(.rightMargin, -insets.right)
		]
		embedAddedSubview(into: superview, attributes: attributes, shouldConstrainToSafeArea: shouldConstrainToSafeArea)
	}

	private func embedAddedSubview(
		into superview: UIView,
		attributes: [LayoutExtendedAttribute],
		shouldConstrainToSafeArea: Bool = false
	) {
		translatesAutoresizingMaskIntoConstraints = false
		let toItem: Any?
		if shouldConstrainToSafeArea {
			toItem = superview.safeAreaLayoutGuide
		} else {
			toItem = superview
		}
		let embedConstraints = attributes.map({ attribute, inset in
			NSLayoutConstraint(
				item: self,
				attribute: attribute,
				relatedBy: .equal,
				toItem: toItem,
				attribute: attribute,
				multiplier: 1,
				constant: inset
			)
		})
		superview.addConstraints(embedConstraints)
	}
}

// MARK: -

extension UIView {
	public typealias PrioritizedConstraintAttribute = (attribute: NSLayoutConstraint.Attribute, constant: CGFloat, priority: UILayoutPriority)

	public func embed(into superview: UIView, with constraintAttributes: [PrioritizedConstraintAttribute]) {
		removeFromSuperview()
		superview.addSubview(self)
		add(constraintAttributes: constraintAttributes, inRespectTo: superview)
	}

	public func add(constraintAttributes: [PrioritizedConstraintAttribute], inRespectTo toItem: UIView) {
		translatesAutoresizingMaskIntoConstraints = false
		let embedConstraints = constraintAttributes.map({ (attribute, constant, priority) -> NSLayoutConstraint in
			let constraint = NSLayoutConstraint(
				item: self,
				attribute: attribute,
				relatedBy: .equal,
				toItem: toItem,
				attribute: attribute,
				multiplier: 1,
				constant: constant
			)
			constraint.priority = priority
			return constraint
		})
		toItem.addConstraints(embedConstraints)
	}
}
