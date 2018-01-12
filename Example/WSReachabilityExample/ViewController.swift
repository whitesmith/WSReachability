//
//  ViewController.swift
//  WSReachabilityExample
//
//  Created by Ricardo Pereira on 20/10/2016.
//  Copyright © 2016 Whitesmith. All rights reserved.
//

import UIKit
import WSReachability

class ViewController: UIViewController {

    let reachability = WSReachability(use: "www.google.pt")

    override func viewDidLoad() {
        super.viewDidLoad()
        reachability?.listen { reachable in
            print("Google is reachable:", reachable)
        }
        reachability?.log.subscribe { message in
            print("Reachability:", message)
        }
    }

}
