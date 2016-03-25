//
//  ViewController.swift
//  dueltime
//
//  Created by Florent Taine on 15/01/2016.
//  Copyright © 2016 Florent Taine. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift
import SwiftyJSON
import Hue
import Mortar

class HomeViewController: UIViewController {
    
    var master : Bool?
    var findPlayerOutlet = UIButton()
    var readyLabel = UILabel()

    func findPlayer(sender: UIButton!) {
        //Supprime le bouton pour chercher des joueurs
        findPlayerOutlet.removeFromSuperview()
        
        
        //Affiche icone de chargement
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        let roomEmpty = Firebase(url: "https://duel-time.firebaseio.com/Room/Empty")
        roomEmpty.observeSingleEventOfType(.Value, withBlock: {snap in
            //Pas de room vide
            if !snap.exists() {
                //Créé unique ID pour la room
                let room = roomEmpty.childByAutoId()
                //Ajoute joueur à la room
                let joueur = ["ID":UIDevice.currentDevice().identifierForVendor!.UUIDString]
                room.setValue(joueur)
                self.waitForPlayer(room.key)
                
            }
            else {
                //Référence vers la premiere room vide
                let oldRoom : Firebase! = snap.children.nextObject()?.ref
                //Référence vers joueur1.phoneNumber
                let phone1Ref = oldRoom.childByAppendingPath("ID")
                phone1Ref.observeSingleEventOfType(.Value, withBlock: {snap in
                    //New data
                    let joueur = ["J1" : snap.value,"J2" : UIDevice.currentDevice().identifierForVendor!.UUIDString,"Tour": ["nbTour" : -1]]
                    //New Room
                    let roomFilled = oldRoom.root.childByAppendingPath("Room").childByAppendingPath("Full").childByAppendingPath(oldRoom.key)
                    //Créé room pleine
                    roomFilled.setValue(joueur)
                    //Supprime room vide
                    oldRoom.removeValue()
                    self.master = true
                    self.performSegueWithIdentifier("homeToGame", sender: roomFilled)
                    
                    
                })
                
            }
        })
        

    }
    
    func waitForPlayer(id : String) {
    
        //Observe si la salle vide est supprimé
        let ref = Firebase(url: "https://duel-time.firebaseio.com/Room/Empty").childByAppendingPath(id)
        ref.observeSingleEventOfType(.ChildRemoved, withBlock: {snap in

            self.performSegueWithIdentifier("homeToGame", sender: Firebase(url: "https://duel-time.firebaseio.com/Room/Full").childByAppendingPath(id))
        })
    
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let transferViewController  = segue.destinationViewController as! GameViewController
        transferViewController.ref = sender as! Firebase!
        if let m = master {
            transferViewController.master = m
        }
        

    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        findPlayerOutlet  = UIButton(type: UIButtonType.RoundedRect) as UIButton
        findPlayerOutlet.frame = CGRectMake(0, 0, 0, 0)
        findPlayerOutlet.addTarget(self, action: #selector(HomeViewController.findPlayer(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        readyLabel.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        
        self.view.addSubview(self.findPlayerOutlet)
        self.view.addSubview(self.readyLabel)

        
        findPlayerOutlet.backgroundColor = UIColor.hex("1D6C5D")
        findPlayerOutlet.setTitleColor(UIColor.hex("F0F5F7"), forState: .Normal)
        findPlayerOutlet.setTitle("Time it !", forState: .Normal)
        findPlayerOutlet.layer.cornerRadius = 33
        findPlayerOutlet.layer.borderWidth = 1
        findPlayerOutlet.layer.borderColor = UIColor.hex("3C3F3F").CGColor
        findPlayerOutlet.titleLabel?.font = UIFont (name: "Roboto-Light", size: 50)


        findPlayerOutlet.m_width |=| self.view.m_width * 71 / 100
        findPlayerOutlet.m_height |=| self.view.m_height * 13 / 100
        findPlayerOutlet.m_centerX |=| self.view
        findPlayerOutlet.m_centerY |=| self.view.m_centerY - 50
        
        
        let readyString = "Ready to time it ?"
        let attributedString = NSMutableAttributedString(string: readyString)
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(0.6), range: NSRange(location: 0, length: readyString.characters.count))
        
        readyLabel.attributedText = attributedString
        
        readyLabel.textColor = UIColor.hex("3C3F3F")
        readyLabel.textAlignment = .Center
        readyLabel.font = UIFont(name: "Roboto-Light", size: 23)

        
        let _ = [
            readyLabel.m_width |=| self.view,
            readyLabel.m_height |=| 30,
            readyLabel.m_centerX |=| self.view,
            readyLabel.m_top |=| self.view.m_bottom * 21 / 100
        ] ~~ .Activated
        
        





    }

    override func shouldAutorotate() -> Bool {
        if (UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeLeft ||
            UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeRight ||
            UIDevice.currentDevice().orientation == UIDeviceOrientation.Unknown) {
                return false
        }
        else {
            return true
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [UIInterfaceOrientationMask.Portrait ,UIInterfaceOrientationMask.PortraitUpsideDown]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        self.view.addBackground("fondAccueuil")

            
            var i = 0
            if let path = NSBundle.mainBundle().pathForResource("data", ofType: "json") {
                if let jsonData = NSData(contentsOfFile: path) {
                    let json = JSON(data: jsonData)
                    let realm = try! Realm()
                    try! realm.write{
                        realm.deleteAll()
                    }
                    var orderedJson = [Item]()
                    
                    
                    for (index,subJson):(String, JSON) in json {
                        
                        for (key, subJsonBis):(String, JSON) in subJson {
                            let item = Item()
                            item.id = i++
                            item.answer = index
                            item.question = subJsonBis[key].string
                            orderedJson.append(item)
                            // realm.add(item)
                            
                        }
                    }
                    
                    orderedJson.sortInPlace({ (A, B) -> Bool in
                        if A.answer == B.answer {
                            return A.id < B.id
                        }else {
                            return Int(A.answer!)! < Int(B.answer!)!
                            
                        }
                    })
                    i=0
                    for item in orderedJson {
                        item.id = i++
                        try! realm.write{
                            realm.add(item)
                        }
                    }
                    print(realm.objects(Item).count)
                    
                    
                }
                
            }

        }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}

