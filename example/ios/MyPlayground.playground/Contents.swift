import UIKit


extension String {
    
    public func charAt(_ pos:Int) -> Character {
        if(pos < 0 || pos >= count) { return Character("") }
        return Array(self)[pos]
    }
    
    public func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    public func indexOf(_ char: Character) -> Int? {
       return firstIndex(of: char)?.utf16Offset(in: self)
    }

    public func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    public func substring(_ from: Int,_ until: Int) -> String? {
        let fromIndex = index(from: from)
        let untilIndex = index(from: until)
        return String(self[fromIndex..<untilIndex])
    }
    
    public func indexOf(_ char: Character, offsetBy:Int) -> Int? {
        return substring(from: offsetBy).firstIndex(of: char)?.utf16Offset(in: self)
    }
    
    public var isDigits: Bool {
        let notDigits = NSCharacterSet.decimalDigits.inverted
        return rangeOfCharacter(from: notDigits, options: String.CompareOptions.literal, range: nil) == nil
    }
    
    public var isLetters: Bool {
        let notLetters = NSCharacterSet.letters.inverted
        return rangeOfCharacter(from: notLetters, options: String.CompareOptions.literal, range: nil) == nil
    }
    
    public var isAlphanumeric: Bool {
        let notAlphanumeric = NSCharacterSet.decimalDigits.union(NSCharacterSet.letters).inverted
        return rangeOfCharacter(from: notAlphanumeric, options: String.CompareOptions.literal, range: nil) == nil
    }

    public func matches(_ expression: String) -> Bool {
        if let range = range(of: expression, options: .regularExpression, range: nil, locale: nil) {
            return range.lowerBound == startIndex && range.upperBound == endIndex
        } else {
            return false
        }
    }

    public mutating func replaceRegex(_ pattern: String, replaceWith: String = "") -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, self.count)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
            return true
        } catch {
            return false
        }
    }

    public func toDate(_ format: String = "yyyy-MM-dd HH:mm:ss", with timeZone: TimeZone = TimeZone(abbreviation: "UTC")!)-> Date?{

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)

        return date
    }

    public func split(regex pattern: String) -> [String] {

        guard let re = try? NSRegularExpression(pattern: pattern, options: [])
            else { return [] }

        let nsString = self as NSString // needed for range compatibility
        let stop = "<SomeStringThatYouDoNotExpectToOccurInSelf>"
        let modifiedString = re.stringByReplacingMatches(
            in: self,
            options: [],
            range: NSRange(location: 0, length: nsString.length),
            withTemplate: stop)
        return modifiedString.components(separatedBy: stop)
    }
    
}

//
//  TreeSet.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 31/08/20.
//

import Foundation

public class TreeSet<E: Comparable & Hashable>: Equatable, Collection, CustomStringConvertible {
    
    public typealias Element = E
    public typealias Index = Int
    
    private let reverse:Bool

  #if swift(>=4.1.50)
    public typealias Indices = Range<Int>
  #else
    public typealias Indices = CountableRange<Int>
  #endif

    internal var array: [Element]

    /// Creates an empty ordered set.
    public init() {
        self.reverse = false
        self.array = []
    }

    /// Creates an empty ordered set.
    public init(reverse:Bool) {
        self.reverse = reverse
        self.array = []
    }

    /// Creates an ordered set with the contents of `array`.
    ///
    /// If an element occurs more than once in `element`, only the first one
    /// will be included.
    public init(_ initialValues: [Element], reverse:Bool?) {
        self.reverse = reverse ?? false
        self.array = initialValues
        self.array = self.array.sorted(by: self.compare)
    }

    // MARK: Working with an ordered set
    /// The number of elements the ordered set stores.
    public var count: Int { return array.count }

    /// Returns `true` if the set is empty.
    public var isEmpty: Bool { return array.isEmpty }

    /// Returns the contents of the set as an array.
    public var contents: [Element] { return array }

    /// Returns `true` if the ordered set contains `member`.
    public func contains(_ member: Element) -> Bool {
        return array.contains(member)
    }
    
    /// Adds an element to the ordered set.
    ///
    /// If it already contains the element, then the set is unchanged.
    ///
    /// - returns: True if the item was inserted.
    public func insert(_ newElement: Element) -> Bool {
        let inserted = array.contains(newElement)
        if !inserted {
            self.array.append(newElement)
            self.array = self.array.sorted(by: self.compare)
        }
        return !inserted
    }

    private func compare(first:E, second:E) -> Bool {
        return reverse ? (first > second) : (first < second)
    }
    
    /// Remove and return the element at the beginning of the ordered set.
    public func removeFirst() -> Element {
        let firstElement = array.removeFirst()
        return firstElement
    }

    /// Remove and return the element at the end of the ordered set.
    public func removeLast() -> Element {
        let lastElement = array.removeLast()
        return lastElement
    }
    
    /// Remove all elements.
    public func removeAll(keepingCapacity keepCapacity: Bool) {
        array.removeAll(keepingCapacity: keepCapacity)
    }
    
    public func tail(reference:E) -> E? {
        if(isEmpty){ return nil }
        for val in array {
            if compare(first:reference, second:val) { return val }
        }
        return nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.array)
    }

    public var description: String { return "(TreeSet)\(self.array)" }
}

extension TreeSet: RandomAccessCollection {
    public var startIndex: Int { return contents.startIndex }
    public var endIndex: Int { return contents.endIndex }
    public subscript(index: Int) -> Element {
      return contents[index]
    }
}

public func == <T>(lhs: TreeSet<T>, rhs: TreeSet<T>) -> Bool {
    return lhs.contents == rhs.contents
}

extension TreeSet: Hashable where Element: Hashable { }


public class CronExpression {

    public let timeZone:TimeZone = TimeZone(abbreviation: "UTC")!
    public var isValidExpression:Bool = false
    
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
        var secondFuruteDate:Date? = incrementByComponentDate(component: CronComponent.lessRelevant, date: referenceDate!)
        var finalComponents:[CronComponent:Int] = [:]
        
        return runSuperCronAlgorithm(
            currentComponent: CronComponent.mostRelevant,
            shiftedToFuture: false,
            finalComponents: &finalComponents,
            referenceDate: &secondFuruteDate
        )
    }
    
    func runSuperCronAlgorithm(
        currentComponent:CronComponent,
        shiftedToFuture:Bool,
        finalComponents: inout [CronComponent:Int],
        referenceDate: inout Date?
    ) -> Date? {
        if(referenceDate == nil){ return nil }
        
        let currentFilter:TreeSet = filterSets[currentComponent]!
        
        // shifted mark should not propagates towards to top
        var shiftedToFuture:Bool = shiftedToFuture
        
        // if top component was shifted to future, every lower component must be initial, otherwise is current
        var currentValue =
            shiftedToFuture ?
                currentFilter.first ?? getDateInterval(currentComponent, fromDate: referenceDate!).initial :
                getRespectiveCalendarValue(currentComponent, referenceDate!)
        
        // get the respective lower component. if is on the bottom, sinalizes it with null
        var nextComponent:CronComponent? = currentComponent.rawValue == 0 ? nil : CronComponent.dateComponents[currentComponent.rawValue - 1]
        
        // if there is restrictions to this component value, process it
        if(!currentFilter.isEmpty){
            
            // if current element does not correspond to an allowed value
            if(!currentFilter.contains(currentValue)){
                
                // now every generated date is in the future
                shiftedToFuture = true
                
                let nextValue:Int? = getNextValidComponent(currentComponent, referenceValue: currentValue, referenceDate!)
                
                // if there is no more next valid componet, so the base component needs to be shifted one level above
                if(nextValue == nil){
                    
                    // if there is no more valid component to shift, there is no more next valid dates
                    if(nextComponent == CronComponent.mostRelevant){
                        return nil
                    }
                    
                    // if tail valid elements has ended, the top component must be shifted
                    nextComponent = CronComponent.dateComponents[currentComponent.rawValue + 1]
                    
                }
                else {
                    currentValue = nextValue!
                }
            }
        }

        // update current component value
        finalComponents[currentComponent] = currentValue
        
        referenceDate = getNextDateFromComponents(
            components: finalComponents,
            referenceDate: &referenceDate
        )
        
        if(referenceDate == nil){ return nil }
        
        // if it reachs the bottom component, so there is a next valid date
        if(nextComponent == nil){
            
            return referenceDate
            
        }
        else {
            
            // process next step
            return runSuperCronAlgorithm(
                currentComponent: nextComponent!,
                shiftedToFuture: shiftedToFuture,
                finalComponents: &finalComponents,
                referenceDate: &referenceDate
            )
        }
    }
    
    func getNextDateFromComponents(components:[CronComponent:Int], referenceDate: inout Date?) -> Date? {
        
        for (component, value) in components {
            referenceDate = calendar.date(bySetting: component.respectiveCalendar, value: value, of: referenceDate!)
            if(referenceDate == nil){ return nil }
        }
        return referenceDate
    }
    
    func isLeapYear(_ fromDate:Date) -> Bool {
        let year:Int = getYear(fromDate)
        return ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0))
    }
    
    func getYear(_ fromDate:Date) -> Int {
        return calendar.component(.year, from: fromDate)
    }
    
    func getRespectiveCalendarValue(_ component:CronComponent, _ referenceDate:Date) -> Int {
        
        return calendar.component(component.respectiveCalendar, from: referenceDate)
    }
    
    func incrementDateComponent(_ component:CronComponent, _ referenceDate:Date) -> Date {
        
        return calendar.date(byAdding: component.respectiveCalendar, value: 1, to: referenceDate)!
    }
    
    func getNextValidComponent(_ component:CronComponent, referenceValue:Int, _ referenceDate:Date) -> Int? {
        
        let nextValue:Int? = filterSets[component]!.tail(reference: referenceValue)
        
        // if has next filter
        if(nextValue != nil){
            let range:ComponentRange = getDateInterval(component, fromDate: referenceDate)
            
            // if next filter is invalid to current date
            if(nextValue! > range.max){
                return nil
            }
        }
        
        return nextValue
    }
}


var components = CronExpression.CronComponent.dateComponents

for component in components {
    print(component)
}

print( components[CronExpression.CronComponent.mostRelevant.rawValue - 1] )

print("end...")
