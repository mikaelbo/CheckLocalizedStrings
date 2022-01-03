//
//  ViewController.swift
//  SampleApp
//
//  Created by Mikael on 2018-04-30.
//  Copyright © 2018 Mikael. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var helloLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        helloLabel.text = NSLocalizedString("HELLO", comment: "")
    }

}

