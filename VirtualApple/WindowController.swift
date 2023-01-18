//
//  WindowController.swift
//  VirtualApple
//
//  Created by Saagar Jha on 11/20/21.
//

import Cocoa

class WindowController: NSWindowController, NSWindowDelegate {
	var retainedSelf: WindowController!
	var virtualMachine: VirtualMachine! = nil
	var viewController: ViewController!

	static var cascadePoint = NSPoint.zero

	convenience init(virtualMachine: VirtualMachine) {
		let virtualMachineViewController = ViewController(virtualMachine: virtualMachine)

		let window = NSWindow(contentViewController: virtualMachineViewController)
		window.representedURL = virtualMachine.url
		window.title = virtualMachine.url.lastPathComponent
		Self.cascadePoint = window.cascadeTopLeft(from: Self.cascadePoint)

		self.init(window: window)

		self.virtualMachine = virtualMachine
		self.viewController = virtualMachineViewController

		retainedSelf = self
		window.delegate = self

		let toolbar = NSToolbar(identifier: "MainToolbar")
		toolbar.delegate = self
		toolbar.displayMode = .iconOnly
		toolbar.allowsUserCustomization = true
		window.toolbar = toolbar

		runSetupWorkflow()
	}
	
	func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions) -> NSApplication.PresentationOptions {
		return [proposedOptions, .autoHideToolbar]
	}

	func windowWillClose(_ notification: Notification) {
		retainedSelf = nil
	}

	func dismiss(_ sender: NSViewController) {
		sender.presentingViewController!.dismiss(sender)
		runSetupWorkflow()
	}

	func runSetupWorkflow() {
		if virtualMachine.metadata.configuration == nil {
			viewController.presentAsSheet(ConfigurationViewController(virtualMachine: virtualMachine))
		} else if !virtualMachine.metadata.installed {
			viewController.presentAsSheet(InstallViewController(virtualMachine: virtualMachine))
		}
	}
}
