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


class HomeViewController: UIViewController {
    
    var master : Bool?
    @IBOutlet weak var findPlayerOutlet: UIButton!
    @IBAction func findPlayer(sender: AnyObject) {
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
        //Affiche icone de chargement
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        //Supprime le bouton pour chercher des joueurs
        findPlayerOutlet.removeFromSuperview()
        
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


    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.view.addBackground("accueil")
        
        
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
                

            }

        }
        /*
        let item1 = Item()
        item1.id = 1
        item1.question = "Toilette"
        item1.answer = "1239"
        */


        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

