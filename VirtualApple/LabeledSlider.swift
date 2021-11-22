//
//  LabeledSlider.swift
//  VirtualApple
//
//  Created by Saagar Jha on 11/22/21.
//

import Cocoa


class NoClipLayer: CALayer {
	override var masksToBounds: Bool {
		get {
			false
		}
		set {
		}
	}
}

class LabeledSlider: NSView {
	var slider: NSSlider!
	var labels: [NSTextField]!
	
	override var firstBaselineOffsetFromTop: CGFloat {
		slider.firstBaselineOffsetFromTop
	}
	
	override var wantsDefaultClipping: Bool {
		false
	}
	
	var tickValue: Int {
		get {
			lround(slider.doubleValue * Double(labels.count))
		}
		set {
			slider.doubleValue = Double(newValue) / Double(labels.count)
		}
	}
	
	convenience init(labels: [String]) {
		self.init()
		wantsLayer = true
		layer = NoClipLayer()
		slider = NSSlider()
		slider.translatesAutoresizingMaskIntoConstraints = false
		slider.setContentCompressionResistancePriority(.required, for: .vertical)
		slider.numberOfTickMarks = labels.count
		slider.allowsTickMarkValuesOnly = true
		self.labels = labels.map(NSTextField.init(labelWithString:))
		var constraints = [NSLayoutConstraint]()
		for label in self.labels {
			label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .small))
			label.translatesAutoresizingMaskIntoConstraints = false
			constraints.append(contentsOf: [
				label.bottomAnchor.constraint(equalTo: bottomAnchor),
				label.topAnchor.constraint(equalTo: slider.bottomAnchor),
			])
			label.setContentCompressionResistancePriority(.required, for: .vertical)
			addSubview(label)
		}
		let offset = CGFloat(self.labels.count) / 256
		for (i, label) in self.labels.enumerated() {
			constraints.append(NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: slider, attribute: .centerX, multiplier: 2 * (CGFloat(i) + offset) / (CGFloat(self.labels.count - 1) + 2 * offset) + 0.0001, constant: 0))
			
		}
		addSubview(slider)
		NSLayoutConstraint.activate(constraints + [
			topAnchor.constraint(equalTo: slider.topAnchor),
			leadingAnchor.constraint(equalTo: slider.leadingAnchor),
			slider.trailingAnchor.constraint(equalTo: trailingAnchor),
		])
	}
	
	override func layout() {
		super.layout()
		for label in labels {
			label.isHidden = true
		}
		var stride = 0
		var indices: StrideTo<Int>
		repeat {
			stride += 1
			indices = Swift.stride(from: 0, to: labels.count, by: stride)
		} while !zip(indices, indices.dropFirst()).allSatisfy {
			!labels[$0].frame.insetBy(dx: -8, dy: 0).intersects(labels![$1].frame)
		}
		for i in indices {
			labels[i].isHidden = false
		}
	}
}
