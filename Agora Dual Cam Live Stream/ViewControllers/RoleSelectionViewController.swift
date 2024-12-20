//
//  RoleSelectionViewController.swift
//  Agora Dual Cam Live Stream
//
//  Created by Shwait Kumar on 04/12/24.
//

import UIKit

class RoleSelectionViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
        
        let hostButton = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Host"
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.buttonSize = .large
        config.cornerStyle = .medium
        hostButton.configuration = config
        hostButton.translatesAutoresizingMaskIntoConstraints = false
        hostButton.addTarget(self, action: #selector(startHostMode), for: .touchUpInside)
        
        let audienceButton = UIButton(type: .system)
        config.title = "Audience"
        config.baseBackgroundColor = .systemGreen
        audienceButton.configuration = config
        audienceButton.translatesAutoresizingMaskIntoConstraints = false
        audienceButton.addTarget(self, action: #selector(startAudienceMode), for: .touchUpInside)
        
        self.view.addSubview(hostButton)
        self.view.addSubview(audienceButton)
        
        NSLayoutConstraint.activate([
            hostButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            hostButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            audienceButton.topAnchor.constraint(equalTo: hostButton.bottomAnchor, constant: 24),
            audienceButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // MARK: - Selector Methods
    
    @objc func startHostMode() {
        let hostVC = DualCamViewController()
        self.navigationController?.pushViewController(hostVC, animated: true)
    }
    
    @objc func startAudienceMode() {
        let audienceVC = AudienceViewController()
        self.navigationController?.pushViewController(audienceVC, animated: true)
    }
    
}
