//
//  GameViewController.swift
//  dueltime
//
//  Created by Florent Taine on 15/01/2016.
//  Copyright © 2016 Florent Taine. All rights reserved.
//

/// Mettre le fond d'accueil
/// Mettre le timer
import UIKit
import Firebase
import RealmSwift
import Hue
import Mortar
import GCDKit

enum LabelIdentfier : Int {
    case YourTurn = 88801
    case Drag = 88802
    case Wait = 88803
    
}

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
    let bottomView = UIView()
    var constraints : [MortarConstraint] = []
    var life = 3
    var timerToPlay = NSTimer()
    var timerPerSecond = NSTimer()
    var timeLeft = 8
    var timerLeftLabel = UILabel()


    var gameViewCenter : CGPoint {
        get {
            let gameViewHeight = UIScreen.mainScreen().bounds.height - bottomView.frame.height
            
            return CGPoint(x: self.view.center.x ,y: gameViewHeight / 2)
        }
    }

    
    var nbQuestion : Int {
        get {
            return tabQuestion.count
        }
    }
    
    var dragArea = [CGRect]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
      
        tap = UIPanGestureRecognizer(target: self, action: Selector("handlePan"))
    }
    
    override func viewDidLayoutSubviews() {
        
        let topBorder = CALayer()
        topBorder.frame = CGRectMake(0, 0, bottomView.bounds.size.width, 1)
        topBorder.backgroundColor = UIColor.hex("000").CGColor
        bottomView.layer.addSublayer(topBorder)

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.backgroundColor = UIColor.hex("D2DADF")
        self.view.addSubview(bottomView)
        
        //Bottom view setup
        bottomView.backgroundColor = UIColor.hex("1D6C5D")
        [bottomView.m_bottom, bottomView.m_left, bottomView.m_right] |=| self.view
        bottomView.m_height |=| self.view.m_height * 30 / 100
        
        
        ref.childByAppendingPath("lastIndex").setValue(["lastIndex":-1])
        ref.childByAppendingPath("ended").setValue(["end":"false"])
        ref.childByAppendingPath("isCorrect").setValue(["correct":-1])
        
        ref.childByAppendingPath("isCorrect").observeEventType(.ChildChanged, withBlock: {snap in
            let correct = snap.value as! Int
            if correct == 1 {

                let question = self.view.viewWithTag(Int("999\(self.currentQuestion!.id)")!)
                question?.backgroundColor = UIColor.hex("1D6C5D")
            } else if correct == 2 {
                let question = self.view.viewWithTag(Int("999\(self.currentQuestion!.id)")!)
                question?.backgroundColor = UIColor.hex("DA3227")

            }
        })
        
        ref.childByAppendingPath("lastIndex").observeEventType(.ChildChanged, withBlock: {snap in
            
            
            self.lastIndex = snap.value as! Int
            if self.lastIndex >= 0 {
                self.tabQuestion.sortInPlace({ (A, B) -> Bool in
                    return Int(A.answer!)! < Int(B.answer!)!
                })
                if self.nbTour > 2 {
                    
                    if  self.lastIndex == 2  {
                        let tag = Int("999\(self.tabQuestion.last!.id)")!
                        
                        self.view.viewWithTag(tag)!.removeFromSuperview()
                        self.tabQuestion.removeLast()
                    } else if  self.lastIndex == 1{
                        let tag = Int("999\(self.tabQuestion.first!.id)")!
                        self.view.viewWithTag(tag)!.removeFromSuperview()
                        self.tabQuestion.removeFirst()
                        
                    }
                    
                }
                self.nbTour++

                
                if self.isMaster() {
                    self.pickCarte()
                }
            }
           
            
        })
        
        ref.childByAppendingPath("ended").observeEventType(.ChildChanged, withBlock: {snap in
            let perdu = UILabel(frame: CGRect(x: 0, y:0 , width: 100, height: 100))
            perdu.backgroundColor = UIColor.blueColor()
            self.view.addSubview(perdu)
        })

        

        ref.childByAppendingPath("Question").observeEventType(.ChildAdded, withBlock: {snap in
        
            
            let question = self.realm.objects(Item).filter("id = \(snap.value)").first
            self.tabQuestion.append(question!)
            self.addQuestion()
            if self.nbTour == 1  {
            let view = self.view.viewWithTag(Int("999\(self.tabQuestion[0].id)")!)! as UIView
                view.backgroundColor = UIColor.hex("1D6C5D")
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
        timerLeftLabel.text = String(timeLeft)
        timerLeftLabel.textAlignment = .Center
        self.view.addSubview(timerLeftLabel)
        let _ = [
            timerLeftLabel.m_width |=| UIScreen.mainScreen().bounds.width,
            timerLeftLabel.m_height |=| 10,
            timerLeftLabel.m_centerX |=| self.view,
            timerLeftLabel.m_top |=| self.view.m_top + 20
        ] ~~ .Activated
        
        if isMaster() {
            self.pickCarte()
        }

       
    }
    
    func startTimer() {
        timerPerSecond = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "timerPerSecondFires", userInfo: nil, repeats: true)
        timerToPlay = NSTimer.scheduledTimerWithTimeInterval(8, target: self, selector: "timerToPlayFires", userInfo: nil, repeats: false)
    }
    
    func timerToPlayFires() {
        resetTimer()
    }
    
    func resetTimer() {
        timerToPlay.invalidate()
        timerPerSecond.invalidate()
        timeLeft = 8
        timerLeftLabel.text = String(timeLeft)

    }
    
    func timerPerSecondFires() {
        timerLeftLabel.text = String(--timeLeft)
    }
    
   
    func placeQuestion() {

        
            var i = 0
            
            if self.nbTour > 0 {
                for question in self.tabQuestion.dropLast() {
                    if let label = self.view.viewWithTag(question.id) as? UILabel {
                        label.textColor = UIColor.hex("F0F5F7")
                        let view = self.view.viewWithTag(Int("999\(question.id)")!)! as UIView
                        let labelAnswer = UILabel()
                        labelAnswer.text = question.answer!
                        labelAnswer.textColor = UIColor.hex("F0F5F7")
                        labelAnswer.textAlignment = .Center
                        labelAnswer.frame.size = CGSize(width: 10,height: 10)
                        labelAnswer.font = UIFont(name: "Roboto-Regular", size: 16)
                        labelAnswer.sizeToFit()
                        
                        view.addSubview(labelAnswer)
                        
                        
                        let answerBorder = UIView(frame: CGRect(x: 0, y: 0, width: labelAnswer.frame.width, height: 20))
                        answerBorder.backgroundColor = UIColor.hex("F0F5F7")
                        view.addSubview(answerBorder)
                        
                        let _ = [
                            labelAnswer.m_top |=| view.m_top + 3,
                            labelAnswer.m_centerX |=| view,
                            
                            answerBorder.m_top |=| labelAnswer.m_bottom + 5,
                            answerBorder.m_height |=| 1,
                            answerBorder.m_width |=| labelAnswer,
                            answerBorder.m_left |=| labelAnswer,
                            answerBorder.m_right |=| labelAnswer,
                            
                            label.m_centerX |=| view,
                            label.m_centerY |=| view.m_centerY + 8 + (labelAnswer.frame.height - answerBorder.frame.height) / 2 ! .High,
                            label.m_height |=| view.m_height - label.frame.height - answerBorder.frame.height ! .High,
                            label.m_width |=| view
                            
                            
                            ] ~~ .Activated
                        
                        
                        
                    }
                }
                
            }
            
            if self.nbTour == 1 {
                UIView.animateWithDuration(0.5, animations: {
                    for question in self.tabQuestion.dropLast() {
                    
                        self.view.viewWithTag(Int("999\(question.id)")!)!.center = self.gameViewCenter
                        i++
                    
                    }
                })
            }
            else if self.nbTour == 2 {
                UIView.animateWithDuration(0.5, animations: {
                    for question in self.tabQuestion.dropLast() {
                    
                        if i == 0 {
                            self.view.viewWithTag(Int("999\(question.id)")!)!.center = self.gameViewCenter
                            self.view.viewWithTag(Int("999\(question.id)")!)!.frame.origin.x -= 50
                        } else {
                            self.view.viewWithTag(Int("999\(question.id)")!)!.center = self.gameViewCenter
                            self.view.viewWithTag(Int("999\(question.id)")!)!.frame.origin.x += 50
                        }
                        i++
                    }
                })
            } else if self.nbTour >= 3 {
                UIView.animateWithDuration(0.5, animations: {
                    for question in self.tabQuestion.dropLast() {
                        if i == 0 {
                            self.view.viewWithTag(Int("999\(question.id)")!)!.center = self.gameViewCenter
                            self.view.viewWithTag(Int("999\(question.id)")!)!.frame.origin.x -= 100
                        } else if i == 1  {
                            self.view.viewWithTag(Int("999\(question.id)")!)!.center = self.gameViewCenter
                        
                        } else {
                            self.view.viewWithTag(Int("999\(question.id)")!)!.center = self.gameViewCenter
                            self.view.viewWithTag(Int("999\(question.id)")!)!.frame.origin.x += 100
                        
                        }
                        i++
                    
        
                    }
                })
        }
        
    }
    
    func placeDropArea() {
        ref.childByAppendingPath("lastIndex").updateChildValues(["lastIndex":-1])
        ref.childByAppendingPath("isCorrect").updateChildValues(["correct":-1])
        ref.childByAppendingPath("remove").updateChildValues(["remove":-1])


        if nbTour == 1 {
            if let _ = tabQuestion.first {
                let label = UIView(frame: CGRect(x: 0, y: 0, width: 75, height: 75))
                label.center = gameViewCenter

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
            label.center = gameViewCenter
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
            label.center = gameViewCenter
            
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
        
        
        if let labelYourTurn = self.view.viewWithTag(LabelIdentfier.YourTurn.rawValue) as? UILabel {
            labelYourTurn.removeFromSuperview()
        }
        if let labelDrag = self.view.viewWithTag(LabelIdentfier.Drag.rawValue) as? UILabel {
            labelDrag.removeFromSuperview()
        }
        
        
        let labelHeight = bottomView.frame.height * 80 / 100
        let labelWidth = bottomView.frame.width * 23/100
        let view = UIView(frame: CGRect(x: 0, y: 0, width: labelWidth, height: labelHeight))
        let label = myLabel(frame: CGRect(x: 0, y: 0, width: labelWidth, height: labelHeight))
        
        if let question = tabQuestion.last?.question {
            if let id = tabQuestion.last?.id {
                label.text = "\(question)"
                label.tag = id
                label.font = UIFont(name: "Roboto-Regular", size: 15)
                view.tag = Int("999\(id)")!
         
            }
        }

        self.view.addSubview(view)
        view.addSubview(label)

        let _ = [
            label.m_centerY |=| view,
            label.m_centerX |=| view,
            label.m_size |=| view
        ] ~~ .Activated
        
      
        
        view.backgroundColor = UIColor.hex("F0F5F7")
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.hex("3C3F3F").CGColor
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.center = bottomView.center
        
        label.numberOfLines = 0
        label.textAlignment = .Center
        label.textColor = UIColor.hex("3C3F3F")
        label.preferredMaxLayoutWidth = labelWidth

        
        
        
        if self.nbTour > 0 {

            view.userInteractionEnabled = true
            if isMaster() && nbTour%2 == 0 {
                view.addGestureRecognizer(tap!)
                if let labelWait = self.view.viewWithTag(LabelIdentfier.Wait.rawValue) {
                    labelWait.removeFromSuperview()
                }
                
                let firstLine = UILabel()
                firstLine.text = "Your turn !"
                firstLine.font = UIFont(name: "Roboto-Regular", size: 18)
                firstLine.textAlignment = .Center
                firstLine.textColor = UIColor.hex("1D6C5D")
                firstLine.tag = LabelIdentfier.YourTurn.rawValue
                
                
                let secondLine = UILabel()
                secondLine.text = "Drag and drop the event in his historical place"
                secondLine.font = UIFont(name: "Roboto-Light", size: 16)
                secondLine.textAlignment = .Center
                secondLine.textColor = UIColor.hex("3C3F3F")
                secondLine.tag = LabelIdentfier.Drag.rawValue
                
                
                self.view.addSubview(firstLine)
                self.view.addSubview(secondLine)
                
                let _ = [
                    secondLine.m_bottom |=| bottomView.m_top - 10,
                    secondLine.m_height |=| 10,
                    secondLine.m_width |=| bottomView,
                    
                    firstLine.m_bottom |=| secondLine.m_top,
                    firstLine.m_height |=| 10,
                    firstLine.m_width |=| bottomView,
                    ] ~~ .Activated
                
                startTimer()
                
            } else if !isMaster() && nbTour%2 == 1 {


                view.addGestureRecognizer(tap!)
                
                if let labelWait = self.view.viewWithTag(LabelIdentfier.Wait.rawValue) {
                    labelWait.removeFromSuperview()
                }
                
                let firstLine = UILabel()
                firstLine.text = "Your turn !"
                firstLine.font = UIFont(name: "Roboto-Regular", size: 18)
                firstLine.textAlignment = .Center
                firstLine.textColor = UIColor.hex("1D6C5D")
                firstLine.tag = LabelIdentfier.YourTurn.rawValue

                
                let secondLine = UILabel()
                secondLine.text = "Drag and drop the event in his historical place"
                secondLine.font = UIFont(name: "Roboto-Light", size: 16)
                secondLine.textAlignment = .Center
                secondLine.textColor = UIColor.hex("3C3F3F")
                secondLine.tag = LabelIdentfier.Drag.rawValue

                
                self.view.addSubview(firstLine)
                self.view.addSubview(secondLine)
                
                let _ = [
                    secondLine.m_bottom |=| bottomView.m_top - 10,
                    secondLine.m_height |=| 10,
                    secondLine.m_width |=| bottomView,
                    
                    firstLine.m_bottom |=| secondLine.m_top,
                    firstLine.m_height |=| 10,
                    firstLine.m_width |=| bottomView,
                    ] ~~ .Activated

                startTimer()
            }
            else {
                let labelWait = UILabel()
                labelWait.text = "Wait for Your Turn !"
                labelWait.tag = LabelIdentfier.Wait.rawValue
                labelWait.textAlignment = .Center
                labelWait.font = UIFont(name: "Roboto-Regular", size: 16)
                labelWait.textColor = UIColor.hex("DA3227")
                self.view.addSubview(labelWait)
                
                let _ = [
                    labelWait.m_bottom |=| bottomView.m_top - 10,
                    labelWait.m_height |=| 10,
                    labelWait.m_width |=| bottomView
                    
                    ] ~~ .Activated
                

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
                            UIView.animateWithDuration(0.5, animations: {
                                self.view.viewWithTag(Int("999\(question.id)")!)?.frame.origin.x += 50
                            })
                        }
                    }
                    else if lastIndex == 1 {
                        UIView.animateWithDuration(0.5, animations: {self.view.viewWithTag(Int("999\(self.tabQuestion.first!.id)")!)?.frame.origin.x -= 50
                            for question in self.tabQuestion.dropLast().dropFirst() {
                                self.view.viewWithTag(Int("999\(question.id)")!)?.frame.origin.x += 50
                            }
                        })
                        
                    }
                    else if lastIndex == 2{
                        UIView.animateWithDuration(0.5, animations: {
                            if self.nbTour == 2 {
                                for question in self.tabQuestion.dropLast() {
                                    self.view.viewWithTag(Int("999\(question.id)")!)!.frame.origin.x -= 50
                                }
                                
                            } else {
                                
                                for question in self.tabQuestion.dropLast() {
                                    self.view.viewWithTag(Int("999\(question.id)")!)!.frame.origin.x -= 50
                                }
                                if let lastQuestion = self.tabQuestion.dropLast().last {
                                    
                                    self.view.viewWithTag(Int("999\(lastQuestion.id)")!)!.frame.origin.x = UIScreen.mainScreen().bounds.width - 75
                                }
                                
                            }

                        })
                    }
                       
                    
                    else {
                        UIView.animateWithDuration(0.5, animations: {
                            for question in self.tabQuestion.dropLast() {
                                self.view.viewWithTag(Int("999\(question.id)")!)?.frame.origin.x -= 50
                            }
                        })
                        
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
                resetTimer()
                let areaCenterX = area.origin.x + area.width/2
                let areaCenterY = area.origin.y + area.height/2

                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.tap!.view!.center = CGPoint(x: areaCenterX, y: areaCenterY)
                })
                
                self.tap!.view!.userInteractionEnabled = false
                
                if isCorrect() {
                    
                    GCDQueue.Default.async {
                        self.ref.childByAppendingPath("isCorrect").updateChildValues(["correct":1])

                        if self.lastIndex < 2 {
                            self.ref.childByAppendingPath("lastIndex").updateChildValues(["lastIndex":2])
                            
                        } else {
                            self.ref.childByAppendingPath("lastIndex").updateChildValues(["lastIndex":1])
                            
                        }


                    }
                    

                    let labelGood = UILabel()
                    labelGood.text = "Good !"
                    labelGood.textAlignment = .Center
                    labelGood.textColor = UIColor.hex("3ABED9")
                
                    self.view.addSubview(labelGood)
                    let viewDragged = self.view.viewWithTag(Int("999\(tabQuestion.last!.id)")!)! as UIView
                    let _ = [
                        labelGood.m_left |=| viewDragged,
                        labelGood.m_bottom |=| viewDragged.frame.origin.y - viewDragged.frame.height / 2,

                        labelGood.m_width |=| self.tap!.view!,
                        labelGood.m_height |=| 10
                    ] ~~ .Activated
                    UIView.animateWithDuration(1, animations: {
                        labelGood.frame.origin.y -= 50
                    })
                    delay(1) {
                        labelGood.removeFromSuperview()
                        
                    }
                    
                  
                }
                else {
                    GCDQueue.Default.async {
                        self.life--
                        self.ref.childByAppendingPath("isCorrect").updateChildValues(["correct":2])
                        self.lastIndex = self.checkCorrectIndex()
                        if self.life > 0 {
                            if self.lastIndex < 2 {
                                self.ref.childByAppendingPath("lastIndex").updateChildValues(["lastIndex":2])
                                
                            } else {
                                self.ref.childByAppendingPath("lastIndex").updateChildValues(["lastIndex":1])
                                
                            }

                        } else {
                            self.ref.childByAppendingPath("ended").updateChildValues(["end":"true"])

                        }
                       
                    }
                    
                    let labelWrong = UILabel()
                    labelWrong.text = "Wrong !"
                    labelWrong.textAlignment = .Center
                    labelWrong.textColor = UIColor.hex("DA3227")
                    
                    self.view.addSubview(labelWrong)
                    let viewDragged = self.view.viewWithTag(Int("999\(tabQuestion.last!.id)")!)! as UIView
                    let _ = [
                        labelWrong.m_left |=| viewDragged,
                        labelWrong.m_bottom |=| viewDragged.frame.origin.y - viewDragged.frame.height / 2,
                        
                        labelWrong.m_width |=| self.tap!.view!,
                        labelWrong.m_height |=| 10
                        ] ~~ .Activated
                    UIView.animateWithDuration(1, animations: {
                        labelWrong.frame.origin.y -= 50
                    })
                    
                    delay(1) {
                        labelWrong.removeFromSuperview()
                    }

                }
                
            } else {
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    self.tap!.view!.center = self.bottomView.center

                })
            }
        
        }
        
        
    }
    
    func checkCorrectIndex() -> Int {
        var i = 0

        GCDQueue.Main.sync {
            if !self.isCorrect() {
                
                let sortedTabQuestion = self.tabQuestion.sort({ (A, B) -> Bool in
                    return Int(A.answer!)! < Int(B.answer!)!
                })
                for question in sortedTabQuestion {
                    if question == self.currentQuestion {
                        break
                    }
                    i++
                }
            }

        }
        return i

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
