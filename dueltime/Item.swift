//
//  Item.swift
//  dueltime
//
//  Created by Florent Taine on 18/01/2016.
//  Copyright © 2016 Florent Taine. All rights reserved.
//

import Foundation
import RealmSwift



class Item: Object {
    dynamic var id : Int = 0
    dynamic var question : String?
    dynamic var answer : String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

