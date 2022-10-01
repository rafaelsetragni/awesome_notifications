package me.carda.awesome_notifications.core.externalLibs;

/*
public class CronNotationType {
    public static final String anyOne   = "\*"; // anything
    public static final String list     = "^\d+(,\d+)*$";  // 1,5,3,45
    public static final String range    = "^\d+-\d+$";  // 1-5
    public static final String interval = "^(\*|\d+)\/\d+$";  // 5
    public static final String wildCard = "^\?$";  // ?
    public static final String unknow = "";
}

class ComponentRange {
    public final int min, max, initial;
    ComponentRange(int min, int max, int initial){
        this.min = min;
        this.max = max;
        this.initial = initial;
    }
}

public enum CronComponent {

    second,
    minute,
    hour,
    day,
    month,
    weekday,
    year;

    public static CronComponent getMostRelevant() {
        return CronComponent.year;
    }

    public static CronComponent getLessRelevant() {
        return CronComponent.second;
    }

    public static List<CronComponent> getDateComponents() {
        return Arrays.asList(
            CronComponent.second,
            CronComponent.minute,
            CronComponent.hour,
            CronComponent.day,
            CronComponent.month,
            CronComponent.year
        );
    }

    public CronComponent bellowComponent() {
        switch (this) {
            case CronComponent.second:   return null;
            case CronComponent.minute:   return CronComponent.second;
            case CronComponent.hour:     return CronComponent.minute;
            case CronComponent.day:      return CronComponent.hour;
            case CronComponent.weekday:  return CronComponent.hour;
            case CronComponent.month:    return CronComponent.day;
            case CronComponent.year:     return CronComponent.month;
        }
        return null;
    }

    public CronComponent aboveComponent() {
        switch (this) {
            case CronComponent.second:   return CronComponent.minute;
            case CronComponent.minute:   return CronComponent.hour;
            case CronComponent.hour:     return CronComponent.day;
            case CronComponent.day:      return CronComponent.month;
            case CronComponent.weekday:  return CronComponent.month;
            case CronComponent.month:    return CronComponent.year;
            case CronComponent.year:     return null;
        }
        return null;
    }

    public int getRespectiveCalendar() {
        switch (this) {
            case CronComponent.second:  return Calendar.SECOND;
            case CronComponent.minute:  return Calendar.MINUTE;
            case CronComponent.hour:    return Calendar.HOUR;
            case CronComponent.weekday: return Calendar.DAY_OF_WEEK;
            case CronComponent.day:     return Calendar.DAY_OF_MONTH;
            case CronComponent.month:   return Calendar.MONTH;
            case CronComponent.year:    return Calendar.YEAR;
        }
    }
}

public class SuperCronExpression {

    public TimeZone timeZone = DateUtils.getUtcTimeZone();
    public Boolean isValidExpression = false;

    Date now = new Date();
    Calendar calendar = Calendar.getInstance();

    List<CronComponent> filterSets = new ArrayList<>();

    Map<CronComponent, Map<String, Integer>> translationSets =
        new HashMap<CronComponent, Map<String, Integer>>(){{
            put(CronComponent.month, new HashMap<String, Integer>(){{
                put("JAN", 1);
                put("FEB", 2);
                put("MAR", 3);
                put("APR", 4);
                put("MAY", 5);
                put("JUN", 6);
                put("JUL", 7);
                put("AUG", 8);
                put("SEP", 9);
                put("OCT",10);
                put("NOV", 11);
                put("DEC", 12);
            }});
            put(CronComponent.weekday, new HashMap<String, Integer>(){{
                put("SUN", 1);
                put("MON", 2);
                put("TUE", 3);
                put("WED", 4);
                put("THU", 5);
                put("FRI", 6);
                put("SAT", 7);
            }});
        }};

    boolean isLeapYear(int year) {
        return ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0));
    }

    public ComponentRange getDateInterval(CronComponent component, Map<CronComponent, Integer> fromComponents) {
        switch (component) {
            
            case CronComponent.second:
            case CronComponent.minute:
                return new ComponentRange(0, 59, 0);
                
            case CronComponent.hour:
                return new ComponentRange(0, 23, 0);
                
            case CronComponent.weekday:
                return new ComponentRange(0, 6, 0);
                
            case CronComponent.day:
                switch (fromComponents.get(CronComponent.month)) {
                    case 1:
                        return new ComponentRange(1, 31, 1);
                    case 2:
                        return new ComponentRange(
                            1,
                            isLeapYear(fromComponents.get(CronComponent.year)) ?
                                    29 : 28,
                            1);
                    case 3:
                        return new ComponentRange(1, 31, 1);
                    case 4:
                        return new ComponentRange(1, 30, 1);
                    case 5:
                        return new ComponentRange(1, 31, 1);
                    case 6:
                        return new ComponentRange(1, 30, 1);
                    case 7:
                        return new ComponentRange(1, 31, 1);
                    case 8:
                        return new ComponentRange(1, 31, 1);
                    case 9:
                        return new ComponentRange(1, 30, 1);
                    case 10:
                        return new ComponentRange(1, 31, 1);
                    case 11:
                        return new ComponentRange(1, 30, 1);
                    case 12:
                        return new ComponentRange(1, 31, 1);
                    default:
                        return new ComponentRange(-1, -1, -1);
                }
            case CronComponent.month:
                return new ComponentRange(0, 12, 0);
            case CronComponent.year:
                return new ComponentRange(0, 9999, fromComponents.get(CronComponent.year));
        }
    }

        func getDateInterval(_ component:CronComponent, fromDate:Date) -> ComponentRange {
            switch component {
                case .second:
                return ComponentRange(0, 59, 0)
                case .minute:
                return ComponentRange(0, 59, 0)
                case .hour:
                return ComponentRange(0, 23, 0)
                case .weekday:
                return ComponentRange(0, 6, 0)
                case .day:
                switch calendar.component(.month, from: fromDate) {
                    case 1:
                        return ComponentRange(1, 31, 1)
                    case 2:
                        return ComponentRange(1, isLeapYear(calendar.component(.year, from: fromDate)) ? 29 : 28, 1)
                    case 3:
                        return ComponentRange(1, 31, 1)
                    case 4:
                        return ComponentRange(1, 30, 1)
                    case 5:
                        return ComponentRange(1, 31, 1)
                    case 6:
                        return ComponentRange(1, 30, 1)
                    case 7:
                        return ComponentRange(1, 31, 1)
                    case 8:
                        return ComponentRange(1, 31, 1)
                    case 9:
                        return ComponentRange(1, 30, 1)
                    case 10:
                        return ComponentRange(1, 31, 1)
                    case 11:
                        return ComponentRange(1, 30, 1)
                    case 12:
                        return ComponentRange(1, 31, 1)
                    default:
                        return ComponentRange(-1, -1, -1)
                }
                case .month:
                return ComponentRange(0, 12, 0)
                case .year:
                return ComponentRange(0, 9999, calendar.component(.year, from: fromDate))
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

}
*/
