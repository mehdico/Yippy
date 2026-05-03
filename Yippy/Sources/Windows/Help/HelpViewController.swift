//
//  HelpViewController.swift
//  Yippy
//
//  Created by Matthew Davidson on 11/9/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa

class HelpViewController: NSViewController {
    
    var timer: Timer?

    @IBOutlet var waitingView: NSView!
    @IBOutlet var instructionsView: NSView!

    var hasControl = false

    override func viewDidLoad() {
        super.viewDidLoad()

        hasControl = Helper.isControlGranted(showPopup: false)
        waitingView.isHidden = hasControl
        instructionsView.isHidden = !hasControl

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let new = Helper.isControlGranted(showPopup: false)
            if new != self.hasControl {
                self.hasControl = new
                self.waitingView.isHidden = self.hasControl
                self.instructionsView.isHidden = !self.hasControl

                self.updateSize()
            }
        }
    }

    deinit {
        timer?.invalidate()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        updateSize()
    }
    
    func updateSize() {
        self.view.window?.setContentSize(self.hasControl ? instructionsView.fittingSize : waitingView.fittingSize)
        self.view.window?.center()
    }
}
