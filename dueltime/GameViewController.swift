//
//  GameViewController.swift
//  dueltime
//
//  Created by Florent Taine on 15/01/2016.
//  Copyright © 2016 Florent Taine. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift



class GameViewController: UIViewController {
    
    var ref : Firebase!    //Ref vers l'id de la room
    var master : Bool?     //Contient true or nil selon le client
    var currentQuestion : Item?  //Contient la derniere question jouée
    var tabQuestion = [Item]()
    let realm = try! Realm()
    var nbCardInGame = 0
    var nbTour = 0
    var xFromCenter: CGFloat = 0
    var tap : UIPanGestureRecognizer?
    let origin = CGPoint(x: 0, y: 0)
    
    var dragArea = [CGRect]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tap = UIPanGestureRecognizer(target: self, action: Selector("handlePan"))

        let newQuestion = ["currentQuestion" : "0"]

        ref.childByAppendingPath("Question").updateChildValues(newQuestion) //Init la question
       
        //Add observer Carte
        ref.childByAppendingPath("Question").observeEventType(.ChildChanged , withBlock: {snap in
            self.currentQuestion = self.realm.objects(Item).filter("id = \(snap.value)").first //currentQuestion contient la nouvelle question
            self.addQuestion() //Ajoute la question à la vue
            if self.nbCardInGame == 0 {
                self.nbCardInGame++
                if let question = self.currentQuestion {
                    let label = self.view.viewWithTag(question.id) as! UILabel
                    label.text = "\(label.text!)\n\(question.answer!)"
                    label.center = self.view.center
                    let dragAreaOne = CGRect(x: label.frame.origin.x - label.frame.width - 15, y: label.frame.origin.y, width: label.frame.width, height: label.frame.height)
                    let dragAreaTwo = CGRect(x: label.frame.origin.x + label.frame.width + 15, y: label.frame.origin.y, width: label.frame.width, height: label.frame.height)
                    self.dragArea.append(dragAreaOne)
                    self.dragArea.append(dragAreaTwo)
                    label.userInteractionEnabled = false
                    self.tabQuestion.append(question)

                    self.updateTour()
                    
                }

            }
            else if self.nbCardInGame == 3 {
                
            }
            else {

                if let question = self.currentQuestion {
                    let label = self.view.viewWithTag(question.id) as! UILabel
                    label.text = "\(label.text!)\n\(question.answer!)"
                }
                
            }
        })
        
        //Add observer Tour
        ref.childByAppendingPath("Tour").observeEventType(.ChildChanged, withBlock: {snap in
            self.nbTour++
            if self.nbTour > 1 {
                if self.isMaster() && self.nbTour%2 == 0 {
                    self.tabQuestion.append(self.currentQuestion!)
                    self.tabQuestion.sortInPlace({ (A, B) -> Bool in
                        return A.answer > B.answer
                    })
                    
                }
                else if !self.isMaster() && self.nbTour%2 == 1 {
                    self.tabQuestion.append(self.currentQuestion!)
                    self.tabQuestion.sortInPlace({ (A, B) -> Bool in
                        return A.answer > B.answer
                    })
                }
                
            }

            print("nbTour :\(self.nbTour) \(self.tabQuestion)")
            let nbQuestion = self.tabQuestion.count
            var i = 0
            for question in self.tabQuestion {
                if nbQuestion == 1 {
                    self.view.viewWithTag(question.id)?.center = self.view.center
                }
                else if nbQuestion == 2 {
                    if i == 0 {
                        self.view.viewWithTag(question.id)?.center = self.view.center
                        self.view.viewWithTag(question.id)?.frame.origin.x = self.view.center.x - (self.view.viewWithTag(question.id)?.frame.width)! - 15
                    } else {
                        self.view.viewWithTag(question.id)?.center = self.view.center
                        self.view.viewWithTag(question.id)?.frame.origin.x = self.view.center.x + 15
                    }
                }
                i++
            }
            
            if self.isMaster() {
                self.pickCarte()
            }
        })
        

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if isMaster() {
            pickCarte()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    
    func updateTour() {
        ref.childByAppendingPath("Tour").observeSingleEventOfType(.Value, withBlock: {snap in

            let newTurn = snap.value.objectForKey("nbTour") as! Int + 1
            self.ref.childByAppendingPath("Tour").updateChildValues(["nbTour" : newTurn])

        })
    }
   
    
    
    //Return an Int
    func pickCarte() {

        let question = realm.objects(Item) //Contient toutes les questions

        
        var unique : Bool
        var randomQuestionNumber : UInt32
        
        repeat {
            unique = true
            randomQuestionNumber = arc4random_uniform(UInt32(question.count)) + 1

            for q in tabQuestion {
                if q.id == Int(randomQuestionNumber) {
                    unique = false
                }
            }
        } while !unique
        
        let newQuestion = ["currentQuestion" : "\(randomQuestionNumber)"]
        ref.childByAppendingPath("Question").updateChildValues(newQuestion) //Update le serveur


    }
    

    
    func addQuestion() {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 75, height: 75))
        label.numberOfLines = 2
        
        if let question = currentQuestion?.question {
            if let id = currentQuestion?.id {
                label.text = "\(question)"
                label.tag = id
            }
        }

        label.textAlignment = .Center
        label.backgroundColor = UIColor.redColor()
        label.frame.origin.y = self.view.frame.height - 75
        label.frame.origin.x = 0

        
        self.view.addSubview(label)
        
        
        if isMaster() && nbTour%2 == 0 {
            label.userInteractionEnabled = true
            label.addGestureRecognizer(tap!)
            
        }
        else if !isMaster() && nbTour%2 == 1 {
            label.userInteractionEnabled = true
            label.addGestureRecognizer(tap!)
        }


    }
    
    func isMaster() -> Bool {
        if let _ = master {
            return true
        }
        return false
    }
 
    // Drag / Drop
    func handlePan() {
        

       
        if self.tap!.state == .Began {
            self.view.bringSubviewToFront(self.tap!.view!)
        }
        
        if self.tap!.state == .Changed {
            let translation = self.tap!.translationInView(self.view)
            self.tap!.view!.center = CGPoint(x: self.tap!.view!.center.x + translation.x, y: self.tap!.view!.center.y + translation.y)
            self.tap!.setTranslation(CGPointZero, inView: self.view)
            
        }
        else if self.tap!.state == .Ended {
            var areaIndex : Int?
            var i = 0
            
            if let area = goalReached() {
                let areaCenterX = area.origin.x + area.width/2
                let areaCenterY = area.origin.y + area.height/2

                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.tap!.view!.center = CGPoint(x: areaCenterX, y: areaCenterY)
                })
                
                self.tap!.view!.userInteractionEnabled = false
                for areaD in dragArea {
                    if area == areaD {
                        areaIndex = i
                    }
                    i++
                }
                

                self.tabQuestion.insert(currentQuestion!, atIndex: areaIndex!)

                isCorrect()
                
            } else {
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    self.tap!.view!.frame.origin = self.origin

                })
            }
        
        }
        
        
    }
    
    func isCorrect() {
        
        var sortedArray = tabQuestion
        sortedArray.sortInPlace { (A, B) -> Bool in
            return A.answer > B.answer
        }

        if sortedArray == tabQuestion {

            updateTour()
        } else {
            print("perdu")
            let perdu = UILabel(frame: CGRect(x: 0, y:0 , width: 100, height: 100))
            perdu.backgroundColor = UIColor.blueColor()
            self.view.addSubview(perdu)
        }
    }

    
    func goalReached() -> CGRect?{
 
        for area in dragArea {
            let areaCenterX = area.origin.x + area.width/2
            let areaCenterY = area.origin.y + area.height/2

            let distanceFromGoal: CGFloat = sqrt(pow(self.tap!.view!.center.x - areaCenterX, 2) + pow(self.tap!.view!.center.y - areaCenterY, 2))
            if distanceFromGoal < self.tap!.view!.bounds.size.width / 1.5 {
                
                return area
            }
            
        }
        return nil
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
