//
//  main.swift
//  VirtualApple
//
//  Created by Saagar Jha on 11/20/21.
//

import AppKit

let delegate = unsafelyRunOnMainActor {
	AppDelegate()
}
NSApplication.shared.delegate = delegate
NSApp.run()
