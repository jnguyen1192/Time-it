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
    var nbTour = 0
    var xFromCenter: CGFloat = 0
    var tap : UIPanGestureRecognizer?
    let origin = CGPoint(x: 0, y: 0)
    var isIn = false
    var lastIndex = 0
    var lastArea = CGRect()
    var nbQuestion : Int {
        get {
            return tabQuestion.count
        }
    }
    
    var dragArea = [CGRect]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        tap = UIPanGestureRecognizer(target: self, action: Selector("handlePan"))
        ///Met à jour compteur nbTour pour chaque client
        ///nbTour détermine qui fait pickCarte

        ref.childByAppendingPath("Tour").observeEventType(.ChildChanged, withBlock: {snap in
            self.nbTour++
            if self.isMaster() {
                self.pickCarte()
            }
        })
        

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        /**
        Pour chaque client :
        Ajoute question au tableau des questions

        Place les questions dans la vue
        Place les dropZone
        **/
        ref.childByAppendingPath("Question").observeEventType(.ChildAdded, withBlock: {snap in
            self.currentQuestion = self.realm.objects(Item).filter("id = \(snap.value)").first
            if let question = self.currentQuestion {
                self.tabQuestion.append(question)
                self.tabQuestion.sortInPlace({ (A, B) -> Bool in
                    Int(A.answer!) < Int(B.answer!)
                    
                })
                self.addQuestion()
                self.placeQuestion()
                self.placeDropArea()
                if self.nbQuestion == 1 {
                    if self.isMaster() {
                        self.updateTour()
                        
                    }
                }
               
            }
            
        })
        
        //Init game
        if isMaster() {
            self.pickCarte()
        }

    }
    
    
   
    func placeQuestion() {
        print(nbQuestion)
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

    }
    
    func placeDropArea() {

        if nbQuestion == 1 {
            if let question = self.currentQuestion {
                let label = self.view.viewWithTag(question.id) as! UILabel
                label.text = "\(label.text!)\n\(question.answer!)"
                label.center = self.view.center
                let dragAreaOne = CGRect(x: label.frame.origin.x - label.frame.width - 15, y: label.frame.origin.y, width: label.frame.width, height: label.frame.height)
                let dragAreaTwo = CGRect(x: label.frame.origin.x + label.frame.width + 15, y: label.frame.origin.y, width: label.frame.width, height: label.frame.height)
                self.dragArea.append(dragAreaOne)
                self.dragArea.append(dragAreaTwo)
                label.userInteractionEnabled = false
            }
            
        }
        else if nbQuestion == 3 {
            //Drag Area Config
            self.dragArea.removeAll()
            let dragAreaOne = CGRect(x: self.view.center.x - 40, y: (self.view.viewWithTag(self.tabQuestion.first!.id)?.frame.origin.y)!, width: (self.view.viewWithTag(self.tabQuestion.last!.id)?.frame.width)!, height: (self.view.viewWithTag(self.tabQuestion.last!.id)?.frame.height)!)
            let dragAreaTwo = CGRect(x: (self.view.viewWithTag(self.tabQuestion.first!.id)?.frame.origin.x)! - 60, y: (self.view.viewWithTag(self.tabQuestion.first!.id)?.frame.origin.y)!, width: (self.view.viewWithTag(self.tabQuestion.last!.id)?.frame.width)!, height: (self.view.viewWithTag(self.tabQuestion.last!.id)?.frame.height)!)
            let dragAreaThree = CGRect(x: (self.view.viewWithTag(self.tabQuestion.last!.id)?.frame.origin.x)! + 60, y: (self.view.viewWithTag(self.tabQuestion.last!.id)?.frame.origin.y)!, width: (self.view.viewWithTag(self.tabQuestion.last!.id)?.frame.width)!, height: (self.view.viewWithTag(self.tabQuestion.last!.id)?.frame.height)!)
            self.dragArea.append(dragAreaOne)
            self.dragArea.append(dragAreaTwo)
            self.dragArea.append(dragAreaThree)
            self.dragArea.sortInPlace({ (A, B) -> Bool in
                A.origin.x < B.origin.x
            })
            
        }
        else if nbQuestion == 2 {
            
            
            if let question = self.currentQuestion {
                let label = self.view.viewWithTag(question.id) as! UILabel
                label.text = "\(label.text!)"
                
                
                
            }
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    
    /**
        Doit être apellé par un seul client
     **/
    func updateTour() {

        ref.childByAppendingPath("Tour").observeSingleEventOfType(.Value, withBlock: {snap in

            let newTurn = snap.value.objectForKey("nbTour") as! Int + 1
            self.ref.childByAppendingPath("Tour").updateChildValues(["nbTour" : newTurn])

        })
    }
    /**
     Doit être apellé par un seul client
     **/
     
    
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
        
        ref.childByAppendingPath("Question").updateChildValues(["\(randomQuestionNumber)":"\(randomQuestionNumber)"])
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
        
        label.userInteractionEnabled = true
        label.addGestureRecognizer(tap!)
        
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
            if let area = goalReached() {
                if !isIn {
                    isIn = true

                    lastArea = area
                    var i = 0

                    for areaD in dragArea {
                        if area == areaD {
                            lastIndex = i
                        }
                        i++
                    }


                    if lastIndex == 0 {
                        for question in tabQuestion {
                            self.view.viewWithTag(question.id)?.frame.origin.x += 50
                        }
                    } else if lastIndex == 1 {
                        self.view.viewWithTag(tabQuestion.first!.id)?.frame.origin.x -= 50
                        for question in tabQuestion.dropFirst() {
                            self.view.viewWithTag(question.id)?.frame.origin.x += 50
                        }
                    } else if lastIndex == 2{
                        if nbQuestion == 3 {
                            for question in tabQuestion.dropLast() {
                                self.view.viewWithTag(question.id)?.frame.origin.x -= 50
                            }
                            self.view.viewWithTag(tabQuestion.last!.id)?.frame.origin.x += 50
                        } else {
                            for question in tabQuestion {
                                self.view.viewWithTag(question.id)?.frame.origin.x -= 50
                            }

                        }
                       
                    } else {
                        for question in tabQuestion {
                            self.view.viewWithTag(question.id)?.frame.origin.x -= 50
                        }
                    }
                    
                }
            } else {
                
                if isIn  {
                    isIn = false

                    goToInitPosition()
                }
            }
            
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

                if isCorrect() {
                    updateTour()
                }
                
            } else {
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    self.tap!.view!.frame.origin = self.origin

                })
            }
        
        }
        
        
    }
    
    func goToInitPosition() {
        if nbQuestion == 1 {
            self.view.viewWithTag((tabQuestion.first?.id)!)?.center = self.view.center
        } else if nbQuestion == 2 {
            let view1  = self.view.viewWithTag((tabQuestion.first?.id)!)
            let view2 = self.view.viewWithTag((tabQuestion.last?.id)!)

            self.view.viewWithTag((tabQuestion.first?.id)!)?.center = self.view.center
            self.view.viewWithTag((tabQuestion.last?.id)!)?.center = self.view.center

            self.view.viewWithTag((tabQuestion.first?.id)!)?.center.x = self.view.center.x - 15 - (view1?.frame.width)!/2
            self.view.viewWithTag((tabQuestion.last?.id)!)?.center.x = self.view.center.x + 15 + (view1?.frame.width)!/2

        } else {
            
        }
        
     
    }
    
    func isCorrect() -> Bool{
        
        var sortedArray = tabQuestion
        sortedArray.sortInPlace { (A, B) -> Bool in
            return Int(A.answer!)! < Int(B.answer!)!
        }

        if sortedArray == tabQuestion {
            return true
            
        } else {
            let perdu = UILabel(frame: CGRect(x: 0, y:0 , width: 100, height: 100))
            perdu.backgroundColor = UIColor.blueColor()
            self.view.addSubview(perdu)
            return false
        }
    }

    
    func goalReached() -> CGRect?{
 
        for area in dragArea {
            let areaCenterX = area.origin.x + area.width/2
            let areaCenterY = area.origin.y + area.height/2

            let distanceFromGoal: CGFloat = sqrt(pow(self.tap!.view!.center.x - areaCenterX, 2) + pow(self.tap!.view!.center.y - areaCenterY, 2))
            if distanceFromGoal < self.tap!.view!.bounds.size.width / 2 {
                
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
