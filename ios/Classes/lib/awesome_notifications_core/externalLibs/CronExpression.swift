//
//  CronExpression.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 01/09/20.
//

import Foundation

public class CronExpression {

    public let timeZone:TimeZone = TimeZone(identifier: DateUtils.utcTimeZone.identifier)!
    public var isValidExpression:Bool = false
    
    public enum CronError: Error {
        case invalidExpression(msg: String)
        case error(msg: String)
    }

    public enum CronComponent : Int, CaseIterable {
        
        case second = 0
        case minute = 1
        case hour = 2
        case day = 3
        case month = 4
        case weekday = 5
        case year = 6
        
        public static var mostRelevant:CronComponent {
            get { return .year }
        }
        
        public static var lessRelevant:CronComponent {
            get { return .second }
        }
        
        public static var dateComponents:[CronComponent] {
            get { return [.second, .minute, .hour, .day, .month, .year].sorted(by: {(first,second) in return first.rawValue < second.rawValue}) }
        }
        
        public var bellowComponent:CronComponent? {
            get {
                switch self {
                    case .second:   return nil
                    case .minute:   return .second
                    case .hour:     return .minute
                    case .day:      return .hour
                    case .weekday:  return .hour
                    case .month:    return .day
                    case .year:     return .month
                }
            }
        }
        
        public var aboveComponent:CronComponent? {
            get {
                switch self {
                    case .second:   return .minute
                    case .minute:   return .hour
                    case .hour:     return .day
                    case .day:      return .month
                    case .weekday:  return .month
                    case .month:    return .year
                    case .year:     return nil
                }
            }
        }
        
        public var respectiveCalendar:Calendar.Component {
            get {
                switch self {
                    case .second:  return Calendar.Component.second
                    case .minute:  return Calendar.Component.minute
                    case .hour:    return Calendar.Component.hour
                    case .weekday: return Calendar.Component.weekday
                    case .day:     return Calendar.Component.day
                    case .month:   return Calendar.Component.month
                    case .year:    return Calendar.Component.year
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
    
    func isLeapYear(_ year:Int) -> Bool {
        return ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0))
    }
    
    func getDateInterval(_ component:CronComponent, fromComponents:[CronComponent:Int]) -> ComponentRange {
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
                switch fromComponents[.month]! {
                    case 1:
                        return ComponentRange(min: 1, max: 31, initial: 1)
                    case 2:
                        return ComponentRange(min: 1, max: isLeapYear(fromComponents[.year]!) ? 29 : 28, initial: 1)
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
                return ComponentRange(min: 0, max: 9999, initial: fromComponents[.year]!)
        }
    }
    
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
                    return ComponentRange(min: 1, max: isLeapYear(calendar.component(.year, from: fromDate)) ? 29 : 28, initial: 1)
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
        
        self.isValidExpression = false
        
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
            return cronExpression.isValidExpression
        } catch {
            return false
        }
    }

    func parse(_ cronExpression: String) throws {
        
        let cronElements = cronExpression.split(regex:"\\s+")
        
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
        
        self.isValidExpression = true
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
                break
                //if(!populateFromWildCard(component, translatedElement))
                //{throw CronError.invalidExpression(msg:"WildCard paramater is invalid (\(cronElement))")}
                //break
            
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
    
    public func isValidDate(referenceDate:Date) -> Bool {
        if(!isValidExpression) { return false }
        
        return (
            (
                filterSets[CronComponent.year]!.isEmpty ||
                filterSets[CronComponent.year]!.contains(
                    calendar.component(CronComponent.year.respectiveCalendar, from: referenceDate)
                )
            ) &&
            (
                filterSets[CronComponent.month]!.isEmpty ||
                filterSets[CronComponent.month]!.contains(
                    calendar.component(CronComponent.month.respectiveCalendar, from: referenceDate)
                )
            ) &&
            (
                filterSets[CronComponent.day]!.isEmpty ||
                filterSets[CronComponent.day]!.contains(
                    calendar.component(CronComponent.day.respectiveCalendar, from: referenceDate)
                )
            ) &&
            (
                filterSets[CronComponent.hour]!.isEmpty ||
                filterSets[CronComponent.hour]!.contains(
                    calendar.component(CronComponent.hour.respectiveCalendar, from: referenceDate)
                )
            ) &&
            (
                filterSets[CronComponent.minute]!.isEmpty ||
                filterSets[CronComponent.minute]!.contains(
                    calendar.component(CronComponent.minute.respectiveCalendar, from: referenceDate)
                )
            ) &&
            (
               filterSets[CronComponent.second]!.isEmpty ||
               filterSets[CronComponent.second]!.contains(
                   calendar.component(CronComponent.second.respectiveCalendar, from: referenceDate)
               )
            )
        )
    }
    
    func incrementByComponentDate(component:CronComponent, date: Date) -> Date {
        return calendar.date(byAdding: component.respectiveCalendar, value: 1, to: date)!
    }
    
    public func getNextValidDate(referenceDate:Date?) -> Date? {
        if(!isValidExpression || referenceDate == nil) { return nil }
        
        // add 1 second to ensure to return the next valid date
        let secondFuruteDate:Date? = incrementByComponentDate(component: CronComponent.lessRelevant, date: referenceDate!)
        let shiftedToFuture:Bool = false
        
        var finalComponents:[CronComponent:Int] = [:]
        
        finalComponents[.year]   = calendar.component(.year,   from: secondFuruteDate!)
        finalComponents[.month]  = calendar.component(.month,  from: secondFuruteDate!)
        finalComponents[.day]    = calendar.component(.day,    from: secondFuruteDate!)
        finalComponents[.hour]   = calendar.component(.hour,   from: secondFuruteDate!)
        finalComponents[.minute] = calendar.component(.minute, from: secondFuruteDate!)
        finalComponents[.second] = calendar.component(.second, from: secondFuruteDate!)
        
        let isInvalidDate = runSuperCronAlgorithm(
            currentComponent: CronComponent.mostRelevant,
            shiftedToFuture: shiftedToFuture,
            finalComponents: &finalComponents
        )
        
        let finalDate:Date? = isInvalidDate ? nil : getDateFromComponents(components: finalComponents)
        
        if(finalDate != nil && !isValidDate(referenceDate: finalDate!)){
            return nil
        }
        
        return finalDate
    }
    
    func runSuperCronAlgorithm(
        currentComponent: CronComponent,
        shiftedToFuture: Bool,
        finalComponents: inout [CronComponent:Int]
    ) -> Bool {
        
        var reachsInvalidDate = false
        
        // shifted mark should not propagates towards to top
        var shiftedToFuture:Bool = shiftedToFuture
        
        // if the components bellow reach their limits, i should run again
        repeat {
            
            let currentFilter:TreeSet = filterSets[currentComponent]!
            
            // if is the first time this level runs and and above component was shifted to future,
            // every lower component must be initial, otherwise is current
            var currentValue =
                !reachsInvalidDate && shiftedToFuture ?
                    currentFilter.first ?? getDateInterval(currentComponent, fromComponents: finalComponents).initial :
                    finalComponents[currentComponent]!
            
            // update current component value
            finalComponents[currentComponent] = currentValue
            
            // get the respective lower component. if is on the bottom, sinalizes it with null
            var nextComponent:CronComponent? = currentComponent.bellowComponent
            
            // if the present value does not match the boundaries or the previous rules
            // so it should be changed
            if(reachsInvalidDate || !isValidComponent(currentComponent, currentValue, finalComponents)){
                    
                // now every generated date is in the future
                shiftedToFuture = true
                
                let nextValue:Int? = getNextValidComponent(currentComponent, finalComponents)
                
                // if there is no more next valid componet, so the base component needs to be shifted one level above
                if(nextValue == nil){
                    
                    // if tail valid elements has ended, the top component must be shifted
                    nextComponent = currentComponent.aboveComponent
                    
                    // if there is no more valid component to shift, there is no more next valid dates
                    if(nextComponent == nil){
                        return true
                    }
                    
                }
                else {
                    currentValue = nextValue!
                }
                
            }

            // update current component value
            finalComponents[currentComponent] = currentValue
            
            // if it reachs the bottom component, so we found a next valid date
            if(nextComponent == nil){
                
                return false
                
            }
            else {
                
                // tell to above component that he needs to shift to the future
                if(nextComponent == currentComponent.aboveComponent){
                    return true
                }
                
                // process next step
                (reachsInvalidDate) = runSuperCronAlgorithm(
                    currentComponent: nextComponent!,
                    shiftedToFuture: shiftedToFuture,
                    finalComponents: &finalComponents
                )
            
            }
        
            // if this component should run again, do it without call another method
            // (to save memory)
        } while (reachsInvalidDate)

        // if the levels bellow reached the bottom component, so we found a next valid date
        return false
    }
    
    func getDateFromComponents(components:[CronComponent:Int]) -> Date? {
        
        // avoid calendar to be unsync in case of invalid components
        for (component, value) in components {
            if(!isValidComponent(component, value, components)){
                return nil
            }
        }
        
        let calendarDateComponents: DateComponents = DateComponents(
            year:   components[.year],
            month:  components[.month],
            day:    components[.day],
            hour:   components[.hour],
            minute: components[.minute],
            second: components[.second]
        )
            
        return calendar.date(from: calendarDateComponents)
    }
    
    func isValidComponent(_ component:CronComponent, _ value:Int, _ components:[CronComponent:Int]) -> Bool {
        
        let currentFilter = filterSets[component]!
        let range:ComponentRange = getDateInterval(component, fromComponents: components)
        
        return (currentFilter.isEmpty || currentFilter.contains(value)) && (value <= range.max && value >= range.min);
    }
    
    func getNextValidComponent(_ component:CronComponent, _ components:[CronComponent:Int]) -> Int? {
        
        var nextValue:Int?
        let currentFilter = filterSets[component]!
        
        if currentFilter.isEmpty {
            nextValue = components[component]!
            nextValue! += 1
        }
        else {
            nextValue = currentFilter.tail(reference: components[component]!)
        }
        
        // if has next filter
        if(nextValue != nil){
            let range:ComponentRange = getDateInterval(component, fromComponents: components)
            
            // if next filter is invalid to current date
            if(nextValue! > range.max){
                return nil
            }
        }
        
        return nextValue
    }
    
    /// Produces a cartesian product of dates components, expressed by UNNotificationTrigger objects, that togetter are capable to represent a single cron expression
    @available(iOS 10.0, *)
    func getTriggerList() -> [UNCalendarNotificationTrigger] {
        var triggerList:[UNCalendarNotificationTrigger] = []
        
        var positions:[CronComponent:Int] = [:]
        for (component, filters) in filterSets {
            if(!filters.isEmpty){
                positions[component] = 0
            }
        }
        
        var notExausted:Bool = true
        repeat {
            
            var dateComponents = DateComponents()
            for (component, position) in positions {
                
                switch component {
                    case .second:   dateComponents.second   = filterSets[component]?.atIndex(position); break
                    case .minute:   dateComponents.minute   = filterSets[component]?.atIndex(position); break
                    case .hour:     dateComponents.hour     = filterSets[component]?.atIndex(position); break
                    case .day:      dateComponents.day      = filterSets[component]?.atIndex(position); break
                    case .month:    dateComponents.month    = filterSets[component]?.atIndex(position); break
                    case .weekday:  dateComponents.weekday  = filterSets[component]?.atIndex(position); break
                    case .year:     dateComponents.year     = filterSets[component]?.atIndex(position); break
                }
            }
            triggerList.append(UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true))
            
            notExausted = false
            positions.forEach({ (component, _) -> Void in
                positions[component]! += 1
                if positions[component]! >= filterSets[component]!.count {
                    positions[component] = 0
                } else {
                    notExausted = true
                    return
                }
            })
        
        } while notExausted
        
        return triggerList
    }
}
