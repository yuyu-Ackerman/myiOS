//
//  ViewController.swift
//  try
//
//  Created by 小余 on 2025/12/2.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

    private let button: UIButton =  {
        let btn = UIButton()
        btn.setTitle("button", for: .normal)
        btn.backgroundColor = .blue
        btn.layer.cornerRadius = 20
        //btn.frame = CGRect(x: 200, y: 300, width: 100, height: 50)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addView()
        setConstraints()
    }
    
    private func addView() {
        view.addSubview(button)
    }
    
    private func setConstraints() {
        button.snp.makeConstraints { make in
            make.width.equalTo(100)
            make.height.equalTo(50)
            make.center.equalTo(view)
        }
    }
}

