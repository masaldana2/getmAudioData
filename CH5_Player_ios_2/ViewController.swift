//
//  ViewController.swift
//  CH5_Player_ios_2
//
//  Created by Miguel  Saldana on 10/1/16.
//  Copyright © 2016 Miguel  Saldana. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  var principio = Principio()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
      print("Async2")
      self.principio.principio()
      
      // principio.principio()
//      print(arrayPlot.points)
      
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

