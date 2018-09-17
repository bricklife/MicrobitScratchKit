//
//  ViewController.swift
//  iOS Demo
//
//  Created by Shinichiro Oba on 17/09/2018.
//  Copyright © 2018 bricklife.com. All rights reserved.
//

import UIKit
import MicrobitScratchKit

class ViewController: UITableViewController {
    
    private let microbit = Microbit()
    
    @IBOutlet weak var displayLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayLabel.text = ""
        microbit.delegate = self
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        let button: Button = sender.tag == 0 ? .A : .B
        microbit.set(button: button, pressing: true)
    }
    
    @IBAction func buttonReleased(_ sender: UIButton) {
        let button: Button = sender.tag == 0 ? .A : .B
        microbit.set(button: button, pressing: false)
    }
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        microbit.set(pin: sender.tag, connecting: sender.isOn)
    }
}

extension ViewController: MicrobitDelegate {
    
    func microbit(_ microbit: Microbit, didReceiveDisplayCommand displayCommand: DisplayCommand) {
        switch displayCommand {
        case .string(let string):
            displayLabel.text = string
            
        case .matrix(let matrix):
            var string = ""
            for (i, b) in matrix.enumerated() {
                if i > 0, i % 5 == 0 {
                    string += "\n"
                }
                string += b ? "⬛️" : "⬜️"
            }
            displayLabel.text = string
            
        case .clear:
            displayLabel.text = ""
        }
    }
}
