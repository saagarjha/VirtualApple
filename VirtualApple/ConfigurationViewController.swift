//
//  ConfigurationViewController.swift
//  VirtualApple
//
//  Created by Saagar Jha on 11/20/21.
//

import Cocoa

@MainActor
class ConfigurationViewController: NSViewController, NSTextFieldDelegate {
	var virtualMachine: VirtualMachine!
	var cpuCountSlider: LabeledSlider!
	var memorySlider: LabeledSlider!
	var screenWidthTextField: NSTextField!
	var screenHeightTextField: NSTextField!
	var screenScaleCheckbox: NSButton!
	var bootIntoMacOSRecoveryCheckbox: NSButton!
	var bootIntoDFUCheckbox: NSButton!
	var haltOnPanicCheckbox: NSButton!
	var haltInIBoot1Checkbox: NSButton!
	var haltInIBoot2Checkbox: NSButton!
	var debugCheckbox: NSButton!
	var debugPortTextField: NSTextField!
	var saveButton: NSButton!
	var cpuCounts: [Int]!
	var memories: [UInt64]!

	convenience init(virtualMachine: VirtualMachine) {
		self.init()
		self.virtualMachine = virtualMachine
		cpuCounts = Array(1...ProcessInfo.processInfo.activeProcessorCount)
		memories = (1...(ProcessInfo.processInfo.physicalMemory >> 30)).map {
			$0 << 30
		}
	}

	override func loadView() {
		let view = NSView()

		let cpuCountLabel = NSTextField(labelWithString: "CPU count:")
		cpuCountSlider = LabeledSlider(labels: cpuCounts.map(String.init))
		if let cpuCount = virtualMachine.metadata.configuration?.cpuCount {
			cpuCountSlider.tickValue = cpuCount - 1
		}
		let cpuCountStackView = NSStackView(fixedSizeViews: [cpuCountLabel, cpuCountSlider])
		cpuCountStackView.alignment = .firstBaseline

		let memoryLabel = NSTextField(labelWithString: "Memory:")
		let formatter = ByteCountFormatter()
		formatter.countStyle = .memory
		memorySlider = LabeledSlider(
			labels: memories.map {
				formatter.string(fromByteCount: Int64($0))
			})
		if let memory = virtualMachine.metadata.configuration?.memorySize {
			memorySlider.tickValue = Int(memory >> 30) - 1
		}
		let memoryStackView = NSStackView(fixedSizeViews: [memoryLabel, memorySlider])
		memoryStackView.alignment = .firstBaseline

		let screenLabel = NSTextField(labelWithString: "Screen:")
		screenWidthTextField = NSTextField()
		screenWidthTextField.delegate = self
		screenWidthTextField.placeholderString = "Width"
		if let width = virtualMachine.metadata.configuration?.screenWidth {
			screenWidthTextField.stringValue = "\(width)"
		}
		let screenMutiplicationLabel = NSTextField(labelWithString: "×")
		screenHeightTextField = NSTextField()
		screenHeightTextField.delegate = self
		screenHeightTextField.placeholderString = "Height"
		if let height = virtualMachine.metadata.configuration?.screenHeight {
			screenHeightTextField.stringValue = "\(height)"
		}
		screenScaleCheckbox = NSButton(checkboxWithTitle: "Retina", target: nil, action: nil)
		if let scale = virtualMachine.metadata.configuration?.screenScale {
			screenScaleCheckbox.state = scale > 1 ? .on : .off
		}
		let screenStackView = NSStackView(fixedSizeViews: [screenLabel, screenWidthTextField, screenMutiplicationLabel, screenHeightTextField, screenScaleCheckbox])
		screenStackView.alignment = .firstBaseline

		let bootLabel = NSTextField(labelWithString: "Boot:")
		bootIntoMacOSRecoveryCheckbox = NSButton(checkboxWithTitle: "Into macOS Recovery", target: nil, action: nil)
		if let bootIntoMacOSRecovery = virtualMachine.metadata.configuration?.bootIntoMacOSRecovery {
			bootIntoMacOSRecoveryCheckbox.state = bootIntoMacOSRecovery ? .on : .off
		}
		bootIntoDFUCheckbox = NSButton(checkboxWithTitle: "Into DFU", target: nil, action: nil)
		if let bootIntoDFU = virtualMachine.metadata.configuration?.bootIntoDFU {
			bootIntoDFUCheckbox.state = bootIntoDFU ? .on : .off
		}
		let bootItemsStackView = NSStackView(fixedSizeViews: [bootIntoMacOSRecoveryCheckbox, bootIntoDFUCheckbox])
		bootItemsStackView.orientation = .vertical
		bootItemsStackView.alignment = .leading
		let bootStackView = NSStackView(fixedSizeViews: [bootLabel, bootItemsStackView])
		bootStackView.alignment = .firstBaseline

		let haltLabel = NSTextField(labelWithString: "Halt:")
		haltOnPanicCheckbox = NSButton(checkboxWithTitle: "On Panic", target: nil, action: nil)
		haltOnPanicCheckbox.disableResizing()
		if let haltOnPanic = virtualMachine.metadata.configuration?.haltOnPanic {
			haltOnPanicCheckbox.state = haltOnPanic ? .on : .off
		}
		haltInIBoot1Checkbox = NSButton(checkboxWithTitle: "In iBoot Stage 1", target: nil, action: nil)
		haltInIBoot1Checkbox.disableResizing()
		if let haltInIBoot1 = virtualMachine.metadata.configuration?.haltInIBoot1 {
			haltInIBoot1Checkbox.state = haltInIBoot1 ? .on : .off
		}
		haltInIBoot2Checkbox = NSButton(checkboxWithTitle: "In iBoot Stage 2", target: nil, action: nil)
		haltInIBoot2Checkbox.disableResizing()
		if let haltInIBoot2 = virtualMachine.metadata.configuration?.haltInIBoot2 {
			haltInIBoot2Checkbox.state = haltInIBoot2 ? .on : .off
		}
		let haltItemsStackView = NSStackView(fixedSizeViews: [haltOnPanicCheckbox, haltInIBoot1Checkbox, haltInIBoot2Checkbox])
		haltItemsStackView.orientation = .vertical
		haltItemsStackView.alignment = .leading
		let haltStackView = NSStackView(fixedSizeViews: [haltLabel, haltItemsStackView])

		let debugLabel = NSTextField(labelWithString: "Debug:")
		debugCheckbox = NSButton(checkboxWithTitle: "Run GDB stub on port", target: self, action: #selector(debugChanged(_:)))
		debugPortTextField = NSTextField()
		debugPortTextField.delegate = self
		debugPortTextField.placeholderString = "5555"
		if let debugPort = virtualMachine.metadata.configuration?.debugPort {
			debugCheckbox.state = .on
			debugPortTextField.stringValue = "\(debugPort)"
		}
		let innerDebugStackView = NSStackView(fixedSizeViews: [debugCheckbox, debugPortTextField])
		innerDebugStackView.alignment = .firstBaseline
		let debugInformationalLabel = NSTextField(
			wrappingLabelWithString:
				"Starting a virtual machine with the GDB stub requires passing a check (run by the VirtualMachine XPC service) against this process for the com.apple.private.virtualization entitlement.")
		debugInformationalLabel.textColor = .secondaryLabelColor
		debugInformationalLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .small))
		let debugItemsStackView = NSStackView(fixedSizeViews: [innerDebugStackView, debugInformationalLabel])
		debugItemsStackView.orientation = .vertical
		debugItemsStackView.alignment = .leading
		let debugStackView = NSStackView(fixedSizeViews: [debugLabel, debugItemsStackView])

		@MainActor
		func separator() -> NSBox {
			let box = NSBox()
			box.boxType = .separator
			return box
		}

		let optionsStackView = NSStackView(views: [
			cpuCountStackView,
			memoryStackView,
			separator(),
			screenStackView,
			separator(),
			bootStackView,
			haltStackView,
			separator(),
			debugStackView,
		])
		optionsStackView.orientation = .vertical
		optionsStackView.spacing *= 2
		view.addSubview(optionsStackView)

		saveButton = NSButton(title: "Save", target: self, action: #selector(save(_:)))
		saveButton.translatesAutoresizingMaskIntoConstraints = false
		saveButton.keyEquivalent = "\r"
		view.addSubview(saveButton)

		NSLayoutConstraint.activate([
			optionsStackView.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
			view.trailingAnchor.constraint(equalToSystemSpacingAfter: optionsStackView.trailingAnchor, multiplier: 1),
			optionsStackView.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 1),
			cpuCountLabel.trailingAnchor.constraint(equalTo: memoryLabel.trailingAnchor),
			memoryLabel.trailingAnchor.constraint(equalTo: screenLabel.trailingAnchor),
			screenLabel.trailingAnchor.constraint(equalTo: bootLabel.trailingAnchor),
			bootLabel.trailingAnchor.constraint(equalTo: haltLabel.trailingAnchor),
			haltLabel.trailingAnchor.constraint(equalTo: debugLabel.trailingAnchor),
			cpuCountSlider.widthAnchor.constraint(equalToConstant: 400),
			cpuCountSlider.widthAnchor.constraint(equalTo: memorySlider.widthAnchor),
			screenWidthTextField.widthAnchor.constraint(equalToConstant: 64),
			screenHeightTextField.widthAnchor.constraint(equalToConstant: 64),
			haltLabel.firstBaselineAnchor.constraint(equalTo: haltOnPanicCheckbox.firstBaselineAnchor),
			debugPortTextField.widthAnchor.constraint(equalToConstant: 64),
			debugLabel.firstBaselineAnchor.constraint(equalTo: debugCheckbox.firstBaselineAnchor),
			debugInformationalLabel.widthAnchor.constraint(lessThanOrEqualTo: cpuCountSlider.widthAnchor),
			saveButton.widthAnchor.constraint(equalToConstant: 64),
			saveButton.topAnchor.constraint(equalToSystemSpacingBelow: optionsStackView.bottomAnchor, multiplier: 1),
			view.trailingAnchor.constraint(equalToSystemSpacingAfter: saveButton.trailingAnchor, multiplier: 1),
			view.bottomAnchor.constraint(equalToSystemSpacingBelow: saveButton.bottomAnchor, multiplier: 1),
		])

		optionsStackView.fitContents()

		validateUI()

		self.view = view
	}

	func validateUI() {
		debugPortTextField.isEnabled = debugCheckbox.state == .on
		saveButton.isEnabled =
			Int(screenWidthTextField.stringValue) != nil && Int(screenHeightTextField.stringValue) != nil && (!debugPortTextField.isEnabled || Int(debugPortTextField.stringValue) != nil)
	}

	@IBAction func debugChanged(_ sender: NSButton) {
		validateUI()
	}

	func controlTextDidChange(_ obj: Notification) {
		validateUI()
	}

	@IBAction func save(_ sender: NSButton) throws {
		virtualMachine.metadata.configuration = Configuration(
			cpuCount: cpuCounts[cpuCountSlider.tickValue],
			memorySize: memories[memorySlider.tickValue],
			screenWidth: Int(screenWidthTextField.stringValue)!,
			screenHeight: Int(screenHeightTextField.stringValue)!,
			screenScale: screenScaleCheckbox.state == .on ? 2 : 1,
			bootIntoMacOSRecovery: bootIntoMacOSRecoveryCheckbox.state == .on,
			bootIntoDFU: bootIntoDFUCheckbox.state == .on,
			haltOnPanic: haltOnPanicCheckbox.state == .on,
			haltInIBoot1: haltInIBoot1Checkbox.state == .on,
			haltInIBoot2: haltInIBoot2Checkbox.state == .on,
			debugPort: debugPortTextField.isEnabled ? Int(debugPortTextField.stringValue) : nil
		)
		try virtualMachine.saveMetadata()
		(view.window!.sheetParent!.windowController as! WindowController).dismiss(self)
	}
}
