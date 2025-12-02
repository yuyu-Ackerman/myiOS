//
//  ViewController.swift
//  try
//
//  Created by 小余 on 2025/12/2.
//

import UIKit

class ViewController: UIViewController {

    private let button: UIButton =  {
        let btn = UIButton()
        btn.setTitle("button", for: .normal)
        btn.backgroundColor = .blue
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button.frame = CGRect(x: 200, y: 300, width: 100, height: 50)
    }


}

