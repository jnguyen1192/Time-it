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
        
        
        self.view.addBackground("interface time it")
      
        tap = UIPanGestureRecognizer(target: self, action: Selector("handlePan"))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        ref.childByAppendingPath("lastIndex").setValue(["lastIndex":-1])
        ref.childByAppendingPath("ended").setValue(["end":"false"])


        ref.childByAppendingPath("lastIndex").observeEventType(.ChildChanged, withBlock: {snap in
            self.lastIndex = snap.value as! Int
            if self.lastIndex >= 0 {
                self.tabQuestion.insert(self.tabQuestion.last!, atIndex: self.lastIndex)
                self.tabQuestion.removeLast()
                
                if self.nbTour > 2 {
                    if self.lastIndex < 2  {
                        let tag = self.tabQuestion.last?.id
                        self.view.viewWithTag(tag!)?.removeFromSuperview()
                        self.tabQuestion.removeLast()
                    } else {
                        let tag = self.tabQuestion.first?.id
                        self.view.viewWithTag(tag!)?.removeFromSuperview()
                        self.tabQuestion.removeFirst()
                    }
                    
                }
                if self.isMaster() {
                    self.updateTour()
                }
            }
           
            
        })
        
        ref.childByAppendingPath("ended").observeEventType(.ChildChanged, withBlock: {snap in
            let perdu = UILabel(frame: CGRect(x: 0, y:0 , width: 100, height: 100))
            perdu.backgroundColor = UIColor.blueColor()
            self.view.addSubview(perdu)
        })

        
        ref.childByAppendingPath("Tour").observeEventType(.ChildChanged, withBlock: {snap in
            self.tabQuestion.sortInPlace({ (A, B) -> Bool in
                return Int(A.answer!)! < Int(B.answer!)!
            })
            self.nbTour = snap.value as! Int
            if self.isMaster() {
                self.pickCarte()
            }
        })
        
        ref.childByAppendingPath("Question").observeEventType(.ChildAdded, withBlock: {snap in
            let question = self.realm.objects(Item).filter("id = \(snap.value)").first
            self.tabQuestion.append(question!)
            self.addQuestion()
            if self.nbTour == 1  {
            let label = self.view.viewWithTag(self.tabQuestion[0].id) as! UILabel
                label.text = "\(self.tabQuestion.first!.question!)\n\(self.tabQuestion.first!.answer!)"
            }
            
            self.currentQuestion = self.tabQuestion.last
            self.placeQuestion()
            self.placeDropArea()
            if self.nbTour == 0 {
                self.nbTour++
                if self.isMaster() {
                    self.pickCarte()
                    
                }
            }
        })
       

        //Init game
        if isMaster() {
            self.pickCarte()
        }

       
    }
    
    
   
    func placeQuestion() {

        var i = 0

        
        if nbTour == 1 {
            for question in self.tabQuestion.dropLast() {
                self.view.viewWithTag(question.id)?.center = self.view.center
                i++

            }
        }
        else if nbTour == 2 {
            for question in self.tabQuestion.dropLast() {

                if i == 0 {
                    self.view.viewWithTag(question.id)?.center = self.view.center
                    self.view.viewWithTag(question.id)?.frame.origin.x -= 50
                } else {
                    self.view.viewWithTag(question.id)?.center = self.view.center
                    self.view.viewWithTag(question.id)?.frame.origin.x += 50
                }
                i++

            }

        } else if nbTour >= 3 {
            for question in self.tabQuestion.dropLast() {
                if i == 0 {
                    self.view.viewWithTag(question.id)?.center = self.view.center
                    self.view.viewWithTag(question.id)?.frame.origin.x -= 100
                } else if i == 1  {
                    self.view.viewWithTag(question.id)?.center = self.view.center
                        
                } else {
                    self.view.viewWithTag(question.id)?.center = self.view.center
                    self.view.viewWithTag(question.id)?.frame.origin.x += 100
                        
                }
                i++

            }
        }
    }
    
    func placeDropArea() {
        ref.childByAppendingPath("lastIndex").updateChildValues(["lastIndex":-1])

        if nbTour == 1 {
            if let _ = tabQuestion.first {
                let label = UIView(frame: CGRect(x: 0, y: 0, width: 75, height: 75))
                label.center = self.view.center

                let dragAreaOne = CGRect(x: label.frame.origin.x  - 75, y: label.frame.origin.y, width: 75, height: 75)
                let dragAreaTwo = CGRect(x: label.frame.origin.x + 75, y: label.frame.origin.y, width: 75, height: 75)
                self.dragArea.append(dragAreaOne)
                self.dragArea.append(dragAreaTwo)
              
                
            }
            
        }
        else if nbTour == 2 {
            //Drag Area Config
            self.dragArea.removeAll()

            let label = UIView(frame: CGRect(x: 0, y: 0, width: 75, height: 75))
            label.center = self.view.center
            let dragAreaOne = CGRect(x: label.frame.origin.x - 100, y: label.frame.origin.y, width: (label.frame.width), height: (label.frame.height))
            let dragAreaTwo = CGRect(x: label.frame.origin.x, y: label.frame.origin.y, width: (label.frame.width), height: (label.frame.height))
            let dragAreaThree = CGRect(x: label.frame.origin.x + 100, y: label.frame.origin.y, width: (label.frame.width), height: (label.frame.height))
            self.dragArea.append(dragAreaOne)
            self.dragArea.append(dragAreaTwo)
            self.dragArea.append(dragAreaThree)
            
        }
        else if nbTour >= 3 {
            self.dragArea.removeAll()
            let label = UIView(frame: CGRect(x: 0, y: 0, width: 75, height: 75))
            label.center = self.view.center
            
            let dragAreaOne = CGRect(x: 0, y: label.frame.origin.y, width: 75, height: 75)
            let dragAreaTwo = CGRect(x: label.frame.origin.x - 50, y: label.frame.origin.y, width: 75, height: 75)
            let dragAreaThree = CGRect(x: label.frame.origin.x + 50, y: label.frame.origin.y, width: 75, height: 75)
            let dragAreaFour = CGRect(x: UIScreen.mainScreen().bounds.width - 75, y: label.frame.origin.y, width: 75, height: 75)
            
            self.dragArea.append(dragAreaOne)
            self.dragArea.append(dragAreaTwo)
            self.dragArea.append(dragAreaThree)
            self.dragArea.append(dragAreaFour)
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    

    func updateTour() {
        nbTour++

        self.ref.childByAppendingPath("Tour").updateChildValues(["nbTour" : nbTour])
    }
    
    
    func pickCarte() {

        let question = realm.objects(Item) //Contient toutes les questions

        
        var unique : Bool
        var randomQuestionNumber : UInt32
        repeat {
            unique = true
            randomQuestionNumber = arc4random_uniform(UInt32(question.count))
            let questionPicked = self.realm.objects(Item).filter("id = \(randomQuestionNumber)").first

            for q in tabQuestion {

                if q.answer == questionPicked?.answer {
                    unique = false
                }
            }
        } while !unique
        
        ref.childByAppendingPath("Question").updateChildValues(["\(nbTour)":"\(randomQuestionNumber)"])
    }
    
    

    
    func addQuestion() {

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 75, height: 75))
        label.numberOfLines = 2
        
        if let question = tabQuestion.last?.question {
            if let id = tabQuestion.last?.id {
                label.text = "\(question)"
                label.tag = id
            }
        }

        label.textAlignment = .Center
        label.backgroundColor = UIColor.redColor()
        label.frame.origin.y = self.view.frame.height - 75
        label.frame.origin.x = 0
        self.view.addSubview(label)
        if self.nbTour > 0 {

            label.userInteractionEnabled = true
            if isMaster() && nbTour%2 == 0 {
                label.addGestureRecognizer(tap!)
                
            } else if !isMaster() && nbTour%2 == 1 {
                label.addGestureRecognizer(tap!)
                
            }

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
                        for question in tabQuestion.dropLast() {
                            self.view.viewWithTag(question.id)?.frame.origin.x += 50
                        }
                    }
                    else if lastIndex == 1 {
                        self.view.viewWithTag(tabQuestion.first!.id)?.frame.origin.x -= 50
                        for question in tabQuestion.dropLast().dropFirst() {
                            self.view.viewWithTag(question.id)?.frame.origin.x += 50
                        }
                    }
                    else if lastIndex == 2{
                        if nbTour == 2 {
                            for question in tabQuestion.dropLast() {
                                self.view.viewWithTag(question.id)!.frame.origin.x -= 50
                            }

                        } else {

                            for question in tabQuestion.dropLast() {
                                self.view.viewWithTag(question.id)!.frame.origin.x -= 50
                            }
                            if let lastQuestion = tabQuestion.dropLast().last {

                                self.view.viewWithTag(lastQuestion.id)!.frame.origin.x = UIScreen.mainScreen().bounds.width - 75
                            }

                        }
                    }
                       
                    
                    else {
                        for question in tabQuestion.dropLast() {
                            self.view.viewWithTag(question.id)?.frame.origin.x -= 50
                        }
                    }
                    
                }
            }
    
        else {
                
                if isIn  {
                    isIn = false

                    placeQuestion()
                }
            }
        }
        else if self.tap!.state == .Ended {
            if let area = goalReached() {
                let areaCenterX = area.origin.x + area.width/2
                let areaCenterY = area.origin.y + area.height/2

                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.tap!.view!.center = CGPoint(x: areaCenterX, y: areaCenterY)
                })
                
                self.tap!.view!.userInteractionEnabled = false
                
                if isCorrect() {
                    ref.childByAppendingPath("lastIndex").updateChildValues(["lastIndex":lastIndex])
                }
                else {
                    ref.childByAppendingPath("ended").updateChildValues(["end":"true"])
                }
                
            } else {
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    self.tap!.view!.frame.origin = self.origin

                })
            }
        
        }
        
        
    }
    
    
    func isCorrect() -> Bool{
        
        var notSortedArray = tabQuestion
        notSortedArray.insert(tabQuestion.last!, atIndex: lastIndex)
        notSortedArray.removeLast()

        let sortedArray = notSortedArray.sort { (A, B) -> Bool in
            return Int(A.answer!)! < Int(B.answer!)!
        }
        
        if sortedArray == notSortedArray {
            return true
        } else {
            return false
        }
    }

    
    func goalReached() -> CGRect?{
 
        for area in dragArea {
            let areaCenterX = area.origin.x + area.width/2
            let areaCenterY = area.origin.y + area.height/2

            let distanceFromGoal: CGFloat = sqrt(pow(self.tap!.view!.center.x - areaCenterX, 2) + pow(self.tap!.view!.center.y - areaCenterY, 2))
            if distanceFromGoal < self.tap!.view!.bounds.size.width / 3 {
                
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
