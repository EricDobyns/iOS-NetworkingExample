//
//  ViewController.swift
//  

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel! { didSet { self.nameLabel.text = nil } }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        API.Users.getUser { (result) in
            switch result {
            case .success(let response):
                guard let user = response.results.first,
                    let userPhoto = URL(string: user.picture.large) else { return }
                
                DispatchQueue.main.async {
                    self.imageView.load(url: userPhoto)
                    self.nameLabel.text = "\(user.name.first) \(user.name.last)"
                }
            case .error(let error):
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Warning", message: error.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
}

