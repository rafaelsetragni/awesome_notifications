//
//  CronExpression.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 01/09/20.
//

import Foundation

public class CronExpression {

    public let timeZone:TimeZone = TimeZone(abbreviation: "UTC")!
    public var isValid:Bool = false
    
    public enum CronError: Error {
        case invalidExpression(msg: String)
        case error(msg: String)
    }

    public enum CronComponent : Int, CaseIterable {
        case second = 0
        case minute = 1
        case hour = 2
        case weekday = 3
        case day = 4
        case month = 5
        case year = 6
        
        static var last:CronComponent {
            get { return .year }
        }
        
        public var respectiveCalendar:Calendar.Component {
            get {
                switch self {
                    case .second:
                        return Calendar.Component.second
                        
                    case .minute:
                        return Calendar.Component.minute
                        
                    case .hour:
                        return Calendar.Component.hour
                        
                    case .weekday:
                        return Calendar.Component.weekday
                        
                    case .day:
                        return Calendar.Component.day
                        
                    case .month:
                        return Calendar.Component.month
                        
                    case .year:
                        return Calendar.Component.year
                }
            }
        }
    }

    public enum CronNotationType : String, CaseIterable {
        case AnyOne   = #"\*"#  // anything
        case List     = #"^\d+(,\d+)*$"#  // 1,5,3,45
        case Range    = #"^\d+-\d+$"#  // 1-5
        case Interval = #"^(\*|\d+)\/\d+$"#  // */5
        case WildCard = #"^\?$"#  // ?
        case Unknow
    }
    
    struct ComponentRange {
        let min:Int, max:Int, initial:Int
        init(min:Int, max:Int, initial:Int){
            self.min = min
            self.max = max
            self.initial = initial
        }
    }
    
    internal var now:Date = Date()
    internal var calendar:Calendar = Calendar.current
    
    internal var filterSets:[CronComponent:TreeSet<Int>]
    var rangeSets:[CronComponent:ComponentRange]
    
    let translationSets:[CronComponent:[String:Int]] = [
        .month: [
            "JAN": 1,
            "FEB": 2,
            "MAR": 3,
            "APR": 4,
            "MAY": 5,
            "JUN": 6,
            "JUL": 7,
            "AUG": 8,
            "SEP": 9,
            "OCT": 10,
            "NOV": 11,
            "DEC": 12
        ],
        .weekday: [
            "SUN": 1,
            "MON": 2,
            "TUE": 3,
            "WED": 4,
            "THU": 5,
            "FRI": 6,
            "SAT": 7
        ]
    ]
    
    func getDateInterval(_ component:CronComponent, fromDate:Date) -> ComponentRange {
        switch component {
        case .second:
            return ComponentRange(min: 0, max: 59, initial: 0)
        case .minute:
            return ComponentRange(min: 0, max: 59, initial: 0)
        case .hour:
            return ComponentRange(min: 0, max: 23, initial: 0)
        case .weekday:
            return ComponentRange(min: 0, max: 6, initial: 0)
        case .day:
            switch calendar.component(.month, from: fromDate) {
                case 1:
                    return ComponentRange(min: 1, max: 31, initial: 1)
                case 2:
                    return ComponentRange(min: 1, max: isLeapYear(fromDate) ? 29 : 28, initial: 1)
                case 3:
                    return ComponentRange(min: 1, max: 31, initial: 1)
                case 4:
                    return ComponentRange(min: 1, max: 30, initial: 1)
                case 5:
                    return ComponentRange(min: 1, max: 31, initial: 1)
                case 6:
                    return ComponentRange(min: 1, max: 30, initial: 1)
                case 7:
                    return ComponentRange(min: 1, max: 31, initial: 1)
                case 8:
                    return ComponentRange(min: 1, max: 31, initial: 1)
                case 9:
                    return ComponentRange(min: 1, max: 30, initial: 1)
                case 10:
                    return ComponentRange(min: 1, max: 31, initial: 1)
                case 11:
                    return ComponentRange(min: 1, max: 30, initial: 1)
                case 12:
                    return ComponentRange(min: 1, max: 31, initial: 1)
                default:
                    return ComponentRange(min: -1, max: -1, initial: -1)
            }
        case .month:
            return ComponentRange(min: 0, max: 12, initial: 0)
        case .year:
            return ComponentRange(min: 0, max: 9999, initial: calendar.component(.year, from: fromDate))
        }
    }
    
    public convenience init(_ cronExpression: String) throws {
        try self.init(cronExpression, fixedDate:Date())
    }
    
    public init(_ cronExpression: String, fixedDate:Date) throws {
        
        self.isValid = false
        
        filterSets = [
            .second:   TreeSet<Int>(),
            .minute:   TreeSet<Int>(),
            .hour:     TreeSet<Int>(),
            .weekday:  TreeSet<Int>(),
            .day:      TreeSet<Int>(),
            .month:    TreeSet<Int>(),
            .year:     TreeSet<Int>()
        ]
        
        now = fixedDate
        calendar = Calendar.current
        calendar.timeZone = timeZone
        
        try parse(cronExpression)
    }
    
    public static func validate(cronExpression: String) -> Bool {
        do {
            let cronExpression = try CronExpression(cronExpression)
            return cronExpression.isValid
        } catch {
            return false
        }
    }

    func parse(_ cronExpression: String) throws {
        
        var cronElements = cronExpression.split(regex:"\\s+")
        
        if(cronElements.count != filterSets.count){
            throw CronError.invalidExpression(msg:"Unexpected amount of elements on cron expression (expected: \(filterSets.count), founded: \(cronElements.count))")
        }
        
        var pos:Int = 0
        for component in CronComponent.allCases {
            try fillRespectiveSet(component, cronElements[pos])
            pos += 1
        }
        
        if(!filterSets[CronComponent.day]!.isEmpty && !filterSets[CronComponent.weekday]!.isEmpty){
            throw CronError.invalidExpression(msg:"Cannot schedule based on day and weekday at same time")
        }
        
        self.isValid = true
    }

    func fillRespectiveSet(_ component:CronComponent, _ cronElement: String) throws {
        
        let translatedElement = translate(component, cronElement)
        
        switch detectCronNotation(cronElement) {
            
            case .AnyOne:
                if(!populateFromAnyOne(component, translatedElement))
                {throw CronError.invalidExpression(msg:"AnyOne paramater is invalid (\(cronElement))")}
                break
            
            case .List:
                if(!populateFromList(component, translatedElement))
                {throw CronError.invalidExpression(msg:"List paramater is invalid (\(cronElement))")}
                break
            
            case .Range:
                if(!populateFromRange(component, translatedElement))
                {throw CronError.invalidExpression(msg:"Range paramater is invalid (\(cronElement))")}
                break
            
            case .Interval:
                if(!populateFromInterval(component, translatedElement))
                {throw CronError.invalidExpression(msg:"Interval paramater is invalid (\(cronElement))")}
                break
            
            case .WildCard:
                if(!populateFromWildCard(component, translatedElement))
                {throw CronError.invalidExpression(msg:"WildCard paramater is invalid (\(cronElement))")}
                break
            
            case .Unknow:
                throw CronError.invalidExpression(msg:"Unknow paramater is invalid (\(cronElement))")
        }
        
    }
    
    func translate(_ component:CronComponent, _ cronElement: String) -> String{
        var translated = cronElement
        for (key, value) in translationSets[component] ?? [:] {
            translated = translated.replacingOccurrences(of: key, with: String(value))
        }
        return translated
    }
    
    public func detectCronNotation(_ cronElement:String) -> CronNotationType {
        
        for type in CronNotationType.allCases {
            let matches:Bool = cronElement.matches(type.rawValue)
            if(matches){
                return type
            }
        }
        
        return CronNotationType.Unknow
    }
    
    func populateFromAnyOne(_ component:CronComponent, _ rule:String) -> Bool {
        
        // Empty filter sets are the same than all values allowed
        return true
    }
    
    func populateFromList(_ component:CronComponent, _ rule:String) -> Bool {
        let range:ComponentRange = getDateInterval(component, fromDate: now)
        
        let values:[String] = rule.components(separatedBy: ",")
        for textValue in values {
            
            let value = Int(textValue)!
            
            if(range.min <= value && range.max >= value ){
                if(!(filterSets[component]?.insert(value) ?? false)){ return false }
            }
            else {
                return false
            }
        }
        
        return true
    }
    
    func populateFromRange(_ component:CronComponent, _ rule:String) -> Bool {
        let range:ComponentRange = getDateInterval(component, fromDate: now)
        
        let limits:[String] = rule.components(separatedBy: "-")
        let min:Int = Int(limits[0])!
        let max:Int = Int(limits[1])!
        
        if(min < range.min || max > range.max){
            return false
        }
        
        let array = [Int](min...max)
        for value in array {
            if(!(filterSets[component]?.insert(value) ?? false)){ return false }
        }
        
        return true
    }
    
    func populateFromInterval(_ component:CronComponent, _ rule:String) -> Bool {
        let range:ComponentRange = getDateInterval(component, fromDate: now)
        
        let elements:[String] = rule.components(separatedBy: "/")
        
        let fraction = Int(elements[1])!
        let initialValue = elements[0] == "*" ? fraction : Int(elements[0])!
        
        var nextValue = initialValue
        
        while(nextValue >= range.min && nextValue <= range.max){
            if(!(filterSets[component]?.insert(nextValue) ?? false)){ return false }
            nextValue += fraction
        }
        
        return !(filterSets[component]?.isEmpty ?? true)
    }
    
    func populateFromWildCard(_ component:CronComponent, _ rule:String) -> Bool {
        
        return filterSets[component]?.insert(calendar.component(component.respectiveCalendar, from: now)) ?? false
    }
    
    public func getNextValidDate(referenceDate:Date) -> Date? {
        if(!isValid){ return nil }
        var nextDate:Date = referenceDate
        
        let topRelevant:CronComponent = CronComponent.last
        
        do {
            var finalComponents:[CronComponent:Int] = [CronComponent:Int]()

            var jumped:Bool = false
            for position in 0...CronComponent.allCases.count {
                let component:CronComponent = CronComponent.allCases[position]
                
                if(jumped){
                    
                    // when it jumps, all components less relevant until here needs to be initial
                    for reverse in position-1...0 {
                        let pastComponent = CronComponent.allCases[reverse]
                        finalComponents[pastComponent] = try getInitialComponent(pastComponent, nextDate)
                    }
                    
                    nextDate = incrementDateComponent(component, nextDate)
                    
                    let dateComponents:DateComponents = DateComponents(
                                year:    try finalComponents[CronComponent.year]   ?? getReferenceComponent(CronComponent.year,   referenceDate),
                                month:   try finalComponents[CronComponent.month]  ?? getReferenceComponent(CronComponent.month,  referenceDate),
                                day:     try finalComponents[CronComponent.day]    ?? getReferenceComponent(CronComponent.day,    referenceDate),
                                hour:    try finalComponents[CronComponent.hour]   ?? getReferenceComponent(CronComponent.hour,   referenceDate),
                                minute:  try finalComponents[CronComponent.minute] ?? getReferenceComponent(CronComponent.minute, referenceDate),
                                second:  try finalComponents[CronComponent.second] ?? getReferenceComponent(CronComponent.second, referenceDate)
                            )
                    
                    // generates a new date from elements
                    nextDate = calendar.date(from: dateComponents)!
                }
                
                (jumped, finalComponents[component]) = try getNextValidComponent(component, referenceDate)
                
                // if there is a final date
                if(component == topRelevant && !filterSets[topRelevant]!.isEmpty){
                    let mostRelevantComponent = try getReferenceComponent(topRelevant, referenceDate)
                    if(mostRelevantComponent < filterSets[topRelevant]!.last!) { return nil }
                }
                
            }
            
        } catch {
            return nil
        }
        
        return nextDate
    }
    
    func isLeapYear(_ fromDate:Date) -> Bool {
        let year:Int = getYear(fromDate)
        return ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0))
    }
    
    func getYear(_ fromDate:Date) -> Int {
        return calendar.component(.year, from: fromDate)
    }
    
    func getReferenceComponent(_ component:CronComponent, _ referenceDate:Date) throws -> Int {
        
        return calendar.component(component.respectiveCalendar, from: referenceDate)
    }
    
    func incrementDateComponent(_ component:CronComponent, _ referenceDate:Date) -> Date {
        
        return calendar.date(byAdding: component.respectiveCalendar, value: 1, to: referenceDate)!
    }
    
    func getInitialComponent(_ component:CronComponent, _ referenceDate:Date) throws -> Int {

        return filterSets[component]!.first ?? getDateInterval(component, fromDate: referenceDate).initial
    }
    
    func getNextValidComponent(_ component:CronComponent, _ referenceDate:Date) throws -> (Bool, Int) {
        
        let calendarComponent:Int = try getReferenceComponent(component, referenceDate)
        if(filterSets[component]!.isEmpty){
            return (false, calendarComponent)
        }
        
        var nextValue:Int? = filterSets[component]!.contains(calendarComponent) ?
            calendarComponent :
            filterSets[component]!.tail(reference: calendarComponent)
        
        if(nextValue != nil){
            let range:ComponentRange = getDateInterval(component, fromDate: referenceDate)
            if(nextValue! > range.max){
                nextValue = nil
            }
        }
        
        if(nextValue == nil){
            nextValue = try getInitialComponent(component, referenceDate)
            return (true, nextValue!)
        }
        
        return (false, nextValue!)
    }
}
