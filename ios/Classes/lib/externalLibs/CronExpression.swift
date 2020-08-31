//
//  CronExpression.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 29/08/20.
//

import UIKit
import Foundation

public class CronExpression {

    static let SECOND = 0
    static let MINUTE = 1
    static let HOUR = 2
    static let DAY_OF_MONTH = 3
    static let MONTH = 4
    static let DAY_OF_WEEK = 5
    static let YEAR = 6
    static let ALL_SPEC_INT = 99 // '*'
    static let NO_SPEC_INT = 98 // '?'
    static let ALL_SPEC = ALL_SPEC_INT
    static let NO_SPEC = NO_SPEC_INT

    static let monthMap:[String:Int] = [
        "JAN": 0,
        "FEB": 1,
        "MAR": 2,
        "APR": 3,
        "MAY": 4,
        "JUN": 5,
        "JUL": 6,
        "AUG": 7,
        "SEP": 8,
        "OCT": 9,
        "NOV": 10,
        "DEC": 11
    ]
    
    static let dayMap:[String:Int] = [
        "SUN": 1,
        "MON": 2,
        "TUE": 3,
        "WED": 4,
        "THU": 5,
        "FRI": 6,
        "SAT": 7,
    ]

    var cronExpression:String?
    var timeZone:TimeZone?
    var seconds:Set<Int>?
    var minutes:Set<Int>?
    var hours:Set<Int>?
    var daysOfMonth:Set<Int>?
    var months:Set<Int>?
    var daysOfWeek:Set<Int>?
    var years:Set<Int>?

    var lastdayOfWeek:Bool = false
    var nthdayOfWeek = 0
    var lastdayOfMonth:Bool = false
    var nearestWeekday:Bool = false
    var lastdayOffset = 0
    var expressionParsed:Bool = false
/*
    public static let MAX_YEAR:Int = Calendar.current.component(.year, from: Date()) + 100

    init(_ cronExpression:String?) throws {
        
        if (cronExpression == nil) {
            throw PushNotificationError.invalidRequiredFields(msg: "cronExpression cannot be null");
        }

        self.cronExpression = cronExpression!.uppercased()

        try buildExpression(self.cronExpression!)
    }

    init(_ expression:CronExpression) throws {
        /*
         * We don't call the other constructor here since we need to swallow the
         * ParseException. We also elide some of the sanity checking as it is
         * not logically trippable.
         */
        self.cronExpression = expression.getCronExpression()
        do {
            try buildExpression(self.cronExpression!)
        } catch {
            throw PushNotificationError.invalidRequiredFields(msg: "cronExpression is invalid");
        }
    }

    public func isSatisfiedBy(date:Date) -> Bool {
        let testDateCal:Calendar = Calendar.current
        let originalDate:Date = testDateCal.date(bySetting: .nanosecond, value: 0, of: date) ?? date
        
        let timeAfter:Date? = getTimeAfter(testDateCal.date(byAdding: .second, value: -1, to: originalDate))

        return ((timeAfter != nil) && (timeAfter == originalDate))
    }

    public func getNextValidTimeAfter(date:Date) -> Date? {
        return getTimeAfter(date)
    }

    /**
     * Returns the next date/time <I>after</I> the given date/time which does
     * <I>not</I> satisfy the expression
     *
     * @param date the date/time at which to begin the search for the next
     *             invalid date/time
     * @return the next valid date/time
     */
    public func getNextInvalidTimeAfter(date:Date) -> Date? {
        var difference:Int64 = 1000;

        //move back to the nearest second so differences will be accurate
        let adjustCal:Calendar = Calendar.current
        var lastDate:Date = adjustCal.date(bySetting: .nanosecond, value: 0, of: date) ?? date
 
        //FUTURE_TODO: (QUARTZ-481) IMPROVE THIS! The following is a BAD solution to this problem. Performance will be very bad here, depending on the cron expression. It is, however A solution.

        //keep getting the next included time until it's farther than one second
        // apart. At that point, lastDate is the last valid fire time. We return
        // the second immediately following it.
        while (difference == 1000) {
            let newDate:Date? = getTimeAfter(lastDate);

            if(newDate == nil){ break }
            
            difference = newDate!.getTime() - lastDate.getTime()

            if (difference == 1000) {
                lastDate = newDate!;
            }
        }

        return Date(fromMilliseconds: lastDate.getTime() + 1000);
    }

    /**
     * Returns the time zone for which this <code>CronExpression</code>
     * will be resolved.
     */
    public func getTimeZone() -> TimeZone {
        return self.timeZone ?? TimeZone.init(abbreviation: "UTC")!;
    }

    /**
     * Sets the time zone for which  this <code>CronExpression</code>
     * will be resolved.
     */
    public func setTimeZone(timeZone:TimeZone) {
        self.timeZone = timeZone
    }

    /**
     * Returns the string representation of the <CODE>CronExpression</CODE>
     *
     * @return a string representation of the <CODE>CronExpression</CODE>
     */
    public func toString() -> String? {
        return cronExpression;
    }

    /**
     * Indicates whether the specified cron expression can be parsed into a
     * valid cron expression
     *
     * @param cronExpression the expression to evaluate
     * @return a boolean indicating whether the given expression is a valid cron
     *         expression
     */
    public static func isValidExpression(_ cronExpression:String) -> Bool {

        do {
            try CronExpression(cronExpression);
        } catch {
            return false;
        }

        return true;
    }

    public static func validateExpression(_ cronExpression:String) throws {

        try CronExpression(cronExpression);
    }


    ////////////////////////////////////////////////////////////////////////////
    //
    // Expression Parsing Functions
    //
    ////////////////////////////////////////////////////////////////////////////

    func buildExpression(_ expression:String) throws {
        expressionParsed = true;

        do {

            if (seconds == nil) {
                seconds = Set()
            }
            if (minutes == nil) {
                seconds = Set()
            }
            if (hours == nil) {
                seconds = Set()
            }
            if (daysOfMonth == nil) {
                seconds = Set()
            }
            if (months == nil) {
                seconds = Set()
            }
            if (daysOfWeek == nil) {
                seconds = Set()
            }
            if (years == nil) {
                seconds = Set()
            }

            var exprOn:Int = CronExpression.SECOND;

            var tokenDelimiter = " \t"
            let exprsTok = expression.componentsSeparatedByString(tokenDelimiter)
            let nl = exprsTok.count
            var tokens = [[String]]() // declares a 2d string array
            for i in 0 ..< nl {
                if(exprOn > YEAR){break}
                
                let x = exprsTok[i].componentsSeparatedByString(tokenDelimiter) // splits into tokens
                tokens.append(x)
            }

            while (exprsTok.pop && exprOn <= YEAR) {
                var expr:String = exprsTok.nextToken().trim()

                // throw an exception if L is used with other days of the month
                if(exprOn == CronExpression.DAY_OF_MONTH && expr.indexOf("L") != -1 && expr.count > 1 && expr.contains(",")) {
                    throw PushNotificationError.cronException(msg: "Support for specifying 'L' and 'LW' with other days of the month is not implemented", -1);
                }
                // throw an exception if L is used with other days of the week
                if(exprOn == CronExpression.DAY_OF_WEEK && expr.indexOf("L") != -1 && expr.count > 1  && expr.contains(",")) {
                    throw PushNotificationError.cronException(msg: "Support for specifying 'L' with other days of the week is not implemented", -1);
                }
                if(exprOn == CronExpression.DAY_OF_WEEK && expr.indexOf("#") != -1 && expr.indexOf("#", offsetBy: (expr.indexOf("#")! + 1)) != -1) {
                    throw PushNotificationError.cronException(msg: "Support for specifying multiple \"nth\" days is not implemented.", -1);
                }

                let vTok:StringTokenizer = StringTokenizer.init(expr, ",")
                while (vTok.hasMoreTokens()) {
                    let v:String = vTok.nextToken()
                    try storeExpressionVals(0, v, exprOn)
                }

                exprOn += 1
            }

            if (exprOn <= CronExpression.DAY_OF_WEEK) {
                throw PushNotificationError.cronException(msg:"Unexpected end of expression.", expression.count);
            }

            if (exprOn <= CronExpression.YEAR) {
                try storeExpressionVals(0, "*", CronExpression.YEAR);
            }

            var dow:Set<Int> = try getSet(CronExpression.DAY_OF_WEEK);
            var dom:Set<Int> = try getSet(CronExpression.DAY_OF_MONTH);

            // Copying the logic from the UnsupportedOperationException below
            var dayOfMSpec:Bool = !dom.contains(CronExpression.NO_SPEC);
            var dayOfWSpec:Bool = !dow.contains(CronExpression.NO_SPEC);

            if (!dayOfMSpec || dayOfWSpec) {
                if (!dayOfWSpec || dayOfMSpec) {
                    throw PushNotificationError.cronException(msg:"Support for specifying both a day-of-week AND a day-of-month parameter is not implemented.", 0);
                }
            }
        } catch {
            throw PushNotificationError.cronException(msg:"Illegal cron expression format", 0);
        }
    }

    func storeExpressionVals(_ pos:Int,_ s:String,_ type:Int) throws -> Int {

        var incr = 0;
        var i = skipWhiteSpace(pos, s);
        if (i >= s.count) {
            return i
        }
        var c:Character = s.charAt(i)
        if ((c >= "A") && (c <= "Z") && (s != "L") && (s != "LW") && (!s.matches("^L-[0-9]*[W]?"))) {
            var sub:String? = s.substring(i, i + 3)
            var sval = -1
            var eval = -1
            if (type == CronExpression.MONTH) {
                sval = getMonthNumber(sub) + 1
                if (sval <= 0) {
                    throw PushNotificationError.cronException(msg:"Invalid Month value: '\(String(describing: sub))'", i)
                }
                if (s.count > i + 3) {
                    c = s.charAt(i + 3)
                    if (c == "-") {
                        i += 4
                        sub = s.substring(i, i + 3)
                        eval = getMonthNumber(sub) + 1
                        if (eval <= 0) {
                            throw PushNotificationError.cronException(msg:"Invalid Month value: '\(String(describing: sub))'", i)
                        }
                    }
                }
            } else if (type == CronExpression.DAY_OF_WEEK) {
                sval = getDayOfWeekNumber(sub)
                if (sval < 0) {
                    throw PushNotificationError.cronException(msg:"Invalid Day-of-Week value: '\(String(describing: sub))'", i)
                }
                if (s.count > i + 3) {
                    c = s.charAt(i + 3)
                    if (c == "-") {
                        i += 4;
                        sub = s.substring(i, i + 3)
                        eval = getDayOfWeekNumber(sub)
                        if (eval < 0) {
                            throw PushNotificationError.cronException(msg:"Invalid Day-of-Week value: '\(String(describing: sub))'", i)
                        }
                    } else if (c == "#") {
                        do {
                            i += 4;
                            nthdayOfWeek = Int(s.charAt(i).description) ?? -1
                            if (nthdayOfWeek < 1 || nthdayOfWeek > 5) {
                                throw PushNotificationError.exception
                            }
                        } catch {
                            throw PushNotificationError.cronException(msg:"A numeric value between 1 and 5 must follow the '#' option",
                                    i);
                        }
                    } else if (c == "L") {
                        lastdayOfWeek = true;
                        i += 1;
                    }
                }

            } else {
                throw PushNotificationError.cronException(msg:"Illegal characters for this position: '\(String(describing: sub))'",
                        i);
            }
            if (eval != -1) {
                incr = 1;
            }
            
            try addToSet(sval, eval, incr, type);
            return (i + 3);
        }

        if (c == "?") {
            i += 1;
            if ((i + 1) < s.count
                && (s.charAt(i) != " " && s.charAt(i + 1) != "\t")) {
                throw PushNotificationError.cronException(msg:"Illegal character after '?': \(s.charAt(i))", i)
            }
            if (type != CronExpression.DAY_OF_WEEK && type != CronExpression.DAY_OF_MONTH) {
                throw PushNotificationError.cronException(msg:"'?' can only be specified for Day-of-Month or Day-of-Week.",
                        i)
            }
            if (type == CronExpression.DAY_OF_WEEK && !lastdayOfMonth) {
                var val = daysOfMonth!.sorted()[daysOfMonth!.count - 1]
                if (val == CronExpression.NO_SPEC_INT) {
                    throw PushNotificationError.cronException(msg:"'?' can only be specified for Day-of-Month -OR- Day-of-Week.",
                            i)
                }
            }

            try addToSet(CronExpression.NO_SPEC_INT, -1, 0, type)
            return i
        }

        if (c == "*" || c == "/") {
            if (c == "*" && (i + 1) >= s.count) {
                try addToSet(CronExpression.ALL_SPEC_INT, -1, incr, type)
                return i + 1
            } else if (c == "/"
                && ((i + 1) >= s.count || s.charAt(i + 1) == " " || s
                    .charAt(i + 1) == "\t")) {
                throw PushNotificationError.cronException(msg:"'/' must be followed by an integer.", i)
            } else if (c == "*") {
                i += 1
            }
            c = s.charAt(i)
            if (c == "/") { // is an increment specified?
                i += 1
                if (i >= s.count) {
                    throw PushNotificationError.cronException(msg:"Unexpected end of string.", i)
                }

                incr = getNumericValue(s, i);

                i += 1
                if (incr > 10) {
                    i += 1
                }
                try checkIncrementRange(incr, type, i);
            } else {
                incr = 1
            }

            try addToSet(CronExpression.ALL_SPEC_INT, -1, incr, type);
            return i;
        } else if (c == "L") {
            i += 1;
            if (type == CronExpression.DAY_OF_MONTH) {
                lastdayOfMonth = true;
            }
            if (type == CronExpression.DAY_OF_WEEK) {
                try addToSet(7, 7, 0, type);
            }
            if(type == CronExpression.DAY_OF_MONTH && s.count > i) {
                c = s.charAt(i);
                if(c == "-") {
                    let (vsPos, vsValue) = getValue(0, s, i+1);
                    lastdayOffset = vsValue
                    if(lastdayOffset > 30)
                        {throw PushNotificationError.cronException(msg:"Offset from last day must be <= 30", i+1)}
                    i = vsPos
                }
                if(s.count > i) {
                    c = s.charAt(i);
                    if(c == "W") {
                        nearestWeekday = true;
                        i += 1
                    }
                }
            }
            return i;
        } else if (c >= "0" && c <= "9") {
            var val:Int = Int(String(c))!
            i += 1
            if (i >= s.count) {
                try addToSet(val, -1, -1, type);
            } else {
                c = s.charAt(i);
                if (c >= "0" && c <= "9") {
                    let (vsPos, vsValue) = getValue(val, s, i)
                    val = vsValue
                    i = vsPos
                }
                i = try checkNext(i, s, val, type);
                return i;
            }
        } else {
            throw PushNotificationError.cronException(msg:"Unexpected character: \(c)", i);
        }

        return i;
    }

    private func checkIncrementRange(_ incr:Int,_ type:Int,_ idxPos:Int) throws {
        if (incr > 59 && (type == CronExpression.SECOND || type == CronExpression.MINUTE)) {
            throw PushNotificationError.cronException(msg:"Increment > 60 : \(incr)", idxPos);
        } else if (incr > 23 && (type == CronExpression.HOUR)) {
            throw PushNotificationError.cronException(msg:"Increment > 24 : \(incr)", idxPos);
        } else if (incr > 31 && (type == CronExpression.DAY_OF_MONTH)) {
            throw PushNotificationError.cronException(msg:"Increment > 31 : \(incr)", idxPos);
        } else if (incr > 7 && (type == CronExpression.DAY_OF_WEEK)) {
            throw PushNotificationError.cronException(msg:"Increment > 7 : \(incr)", idxPos);
        } else if (incr > 12 && (type == CronExpression.MONTH)) {
            throw PushNotificationError.cronException(msg:"Increment > 12 : \(incr)", idxPos);
        }
    }

    func checkNext(_ pos:Int,_ s:String,_ val:Int,_ type:Int) throws -> Int {

        var end = -1
        var i = pos

        if (i >= s.count) {
            try addToSet(val, end, -1, type)
            return i
        }

        var c:Character = s.charAt(pos)

        if (c == "L") {
            if (type == CronExpression.DAY_OF_WEEK) {
                if(val < 1 || val > 7){
                    throw PushNotificationError.cronException(msg:"Day-of-Week values must be between 1 and 7", -1)
                }
                lastdayOfWeek = true
            } else {
                throw PushNotificationError.cronException(msg:"'L' option is not valid here. (pos=\(i))", i);
            }
            var set:Set = try getSet(type)
            set.insert(val);
            i+=1
            return i;
        }

        if (c == "W") {
            if (type == CronExpression.DAY_OF_MONTH) {
                nearestWeekday = true;
            } else {
                throw PushNotificationError.cronException(msg:"'W' option is not valid here. (pos=\(i))", i);
            }
            if(val > 31)
                {throw PushNotificationError.cronException(msg:"The 'W' option does not make sense with values larger than 31 (max number of days in a month)", i)}
            
            var set:Set = try getSet(type)
            set.insert(val);
            i+=1
            return i;
        }

        if (c == "#") {
            if (type != CronExpression.DAY_OF_WEEK) {
                throw PushNotificationError.cronException(msg:"'#' option is not valid here. (pos=\(i))", i);
            }
            i+=1
            do {
                nthdayOfWeek = Int(String(s.charAt(i))) ?? -1;
                if (nthdayOfWeek < 1 || nthdayOfWeek > 5) {
                    throw PushNotificationError.exception
                }
            } catch {
                throw PushNotificationError.cronException(msg:
                        "A numeric value between 1 and 5 must follow the '#' option",
                        i);
            }
            
            var set:Set = try getSet(type)
            set.insert(val);
            i+=1
            return i;
        }

        if (c == "-") {
            i+=1
            c = s.charAt(i);
            var v:Int = Int(String(c));
            end = v;
            i+=1
            if (i >= s.count) {
                try addToSet(val, end, 1, type);
                return i;
            }
            c = s.charAt(i);
            if (c >= "0" && c <= "9") {
                ValueSet vs = getValue(v, s, i);
                end = vs.value;
                i = vs.pos;
            }
            if (i < s.count && ((c = s.charAt(i)) == '/')) {
                i+=1
                c = s.charAt(i);
                var v2:Int = Int(String.valueOf(c));
                i+=1
                if (i >= s.count) {
                    addToSet(val, end, v2, type);
                    return i;
                }
                c = s.charAt(i);
                if (c >= "0" && c <= "9") {
                    ValueSet vs = getValue(v2, s, i);
                    int v3 = vs.value;
                    addToSet(val, end, v3, type);
                    i = vs.pos;
                    return i;
                } else {
                    addToSet(val, end, v2, type);
                    return i;
                }
            } else {
                addToSet(val, end, 1, type);
                return i;
            }
        }

        if (c == "/") {
            if ((i + 1) >= s.count || s.charAt(i + 1) == " " || s.charAt(i + 1) == "\t") {
                throw PushNotificationError.cronException(msg:"'/' must be followed by an integer.", i);
            }

            i+=1
            c = s.charAt(i);
            var v2:Int = Int(String(c));
            i+=1
            if (i >= s.count) {
                checkIncrementRange(v2, type, i);
                addToSet(val, end, v2, type);
                return i;
            }
            c = s.charAt(i);
            if (c >= "0" && c <= "9") {
                ValueSet vs = getValue(v2, s, i);
                var v3:Int = vs.value;
                checkIncrementRange(v3, type, i);
                addToSet(val, end, v3, type);
                i = vs.pos;
                return i;
            } else {
                throw PushNotificationError.cronException(msg:"Unexpected character '\(c)' after '/'", i);
            }
        }

        addToSet(val, end, 0, type);
        i+=1
        return i;
    }

    public func getCronExpression() -> String? {
        return self.cronExpression
    }

    public func getExpressionSummary() -> String {
        var buf:String = ""

        buf += "seconds: "
        buf += getExpressionSetSummary(seconds)
        buf += "\n"
        buf += "minutes: "
        buf += getExpressionSetSummary(minutes)
        buf += "\n"
        buf += "hours: "
        buf += getExpressionSetSummary(hours)
        buf += "\n"
        buf += "daysOfMonth: "
        buf += getExpressionSetSummary(daysOfMonth)
        buf += "\n"
        buf += "months: "
        buf += getExpressionSetSummary(months)
        buf += "\n"
        buf += "daysOfWeek: "
        buf += getExpressionSetSummary(daysOfWeek)
        buf += "\n"
        buf += "lastdayOfWeek: "
        buf += lastdayOfWeek ? "true" : "false"
        buf += "\n"
        buf += "nearestWeekday: "
        buf += nearestWeekday ? "true" : "false"
        buf += "\n"
        buf += "NthDayOfWeek: "
        buf += String(nthdayOfWeek)
        buf += "\n"
        buf += "lastdayOfMonth: "
        buf += lastdayOfMonth ? "true" : "false"
        buf += "\n"
        buf += "years: "
        buf += getExpressionSetSummary(years)
        buf += "\n"

        return buf
    }

    func getExpressionSetSummary(_ set:Set<Int>?) -> String {

        if(set == nil){ return "" }
        
        if (set!.contains(CronExpression.NO_SPEC)) {
            return "?";
        }
        if (set!.contains(CronExpression.ALL_SPEC)) {
            return "*";
        }

        var buf:String = ""
        var first:Bool = true
        
        for element in set! {
            if (!first) {
                buf += ","
            }
            buf += "\(element)"
            first = false;
        }

        return buf
    }

    func getExpressionSetSummary(_ list:[Int]?) -> String {

        if(list == nil){ return "" }

        if (list!.contains(CronExpression.NO_SPEC)) {
            return "?";
        }
        if (list!.contains(CronExpression.ALL_SPEC)) {
            return "*";
        }

        return list!.description
    }

    func skipWhiteSpace(_ initialPos:Int,_ s:String) -> Int {
        var i = initialPos
        repeat {
           i += 1
        } while (i < s.count && (s.charAt(i) == " " || s.charAt(i) == "\t"))
        return i
    }

    func findNextWhiteSpace(_ initialPos:Int,_ s:String) -> Int {
        var i = initialPos
        repeat {
           i += 1
        } while (i < s.count && (s.charAt(i) != " " || s.charAt(i) != "\t"))
        return i
    }

    func addToSet(_ val:Int,_ end:Int,_ initialIncrement:Int,_ type:Int) throws {

        var incr = initialIncrement
        
        var set:Set<Int> = try getSet(type);

        if (type == CronExpression.SECOND || type == CronExpression.MINUTE) {
            if ((val < 0 || val > 59 || end > 59) && (val != CronExpression.ALL_SPEC_INT)) {
                throw PushNotificationError.cronException(msg:
                        "Minute and Second values must be between 0 and 59",
                        -1);
            }
        } else if (type == CronExpression.HOUR) {
            if ((val < 0 || val > 23 || end > 23) && (val != CronExpression.ALL_SPEC_INT)) {
                throw PushNotificationError.cronException(msg:
                        "Hour values must be between 0 and 23", -1);
            }
        } else if (type == CronExpression.DAY_OF_MONTH) {
            if ((val < 1 || val > 31 || end > 31) && (val != CronExpression.ALL_SPEC_INT)
                && (val != CronExpression.NO_SPEC_INT)) {
                throw PushNotificationError.cronException(msg:
                        "Day of month values must be between 1 and 31", -1);
            }
        } else if (type == CronExpression.MONTH) {
            if ((val < 1 || val > 12 || end > 12) && (val != CronExpression.ALL_SPEC_INT)) {
                throw PushNotificationError.cronException(msg:
                        "Month values must be between 1 and 12", -1);
            }
        } else if (type == CronExpression.DAY_OF_WEEK) {
            if ((val == 0 || val > 7 || end > 7) && (val != CronExpression.ALL_SPEC_INT)
                && (val != CronExpression.NO_SPEC_INT)) {
                throw PushNotificationError.cronException(msg:
                        "Day-of-Week values must be between 1 and 7", -1);
            }
        }

        if ((incr == 0 || incr == -1) && val != CronExpression.ALL_SPEC_INT) {
            if (val != -1) {
                set.insert(val);
            } else {
                set.insert(CronExpression.NO_SPEC);
            }

            return;
        }

        var startAt:Int = val
        var stopAt:Int = end

        if (val == CronExpression.ALL_SPEC_INT && incr <= 0) {
            incr = 1;
            set.insert(CronExpression.ALL_SPEC); // put in a marker, but also fill values
        }

        if (type == CronExpression.SECOND || type == CronExpression.MINUTE) {
            if (stopAt == -1) {
                stopAt = 59;
            }
            if (startAt == -1 || startAt == CronExpression.ALL_SPEC_INT) {
                startAt = 0;
            }
        } else if (type == CronExpression.HOUR) {
            if (stopAt == -1) {
                stopAt = 23;
            }
            if (startAt == -1 || startAt == CronExpression.ALL_SPEC_INT) {
                startAt = 0;
            }
        } else if (type == CronExpression.DAY_OF_MONTH) {
            if (stopAt == -1) {
                stopAt = 31;
            }
            if (startAt == -1 || startAt == CronExpression.ALL_SPEC_INT) {
                startAt = 1;
            }
        } else if (type == CronExpression.MONTH) {
            if (stopAt == -1) {
                stopAt = 12;
            }
            if (startAt == -1 || startAt == CronExpression.ALL_SPEC_INT) {
                startAt = 1;
            }
        } else if (type == CronExpression.DAY_OF_WEEK) {
            if (stopAt == -1) {
                stopAt = 7;
            }
            if (startAt == -1 || startAt == CronExpression.ALL_SPEC_INT) {
                startAt = 1;
            }
        } else if (type == CronExpression.YEAR) {
            if (stopAt == -1) {
                stopAt = CronExpression.MAX_YEAR;
            }
            if (startAt == -1 || startAt == CronExpression.ALL_SPEC_INT) {
                startAt = 1970;
            }
        }

        // if the end of the range is before the start, then we need to overflow into
        // the next day, month etc. This is done by adding the maximum amount for that
        // type, and using modulus max to determine the value being added.
        var max:Int = -1;
        if (stopAt < startAt) {
            switch (type) {
                case       CronExpression.SECOND : max = 60; break;
                case       CronExpression.MINUTE : max = 60; break;
                case         CronExpression.HOUR : max = 24; break;
                case        CronExpression.MONTH : max = 12; break;
                case  CronExpression.DAY_OF_WEEK : max = 7;  break;
                case CronExpression.DAY_OF_MONTH : max = 31; break;
                case         CronExpression.YEAR : throw PushNotificationError.exceptionMsg(msg: "Start year must be less than stop year")
                default : throw PushNotificationError.exceptionMsg(msg: "Unexpected type encountered")
            }
            stopAt += max;
        }

        for i:Int in startAt...stopAt {
            if (max == -1) {
                // ie: there's no max to overflow over
                set.insert(i);
            }
            else {
                // take the modulus to get the real value
                var i2:Int = i % max;

                // 1-indexed ranges should not include 0, and should include their max
                if (i2 == 0 && (type == CronExpression.MONTH || type == CronExpression.DAY_OF_WEEK || type == CronExpression.DAY_OF_MONTH) ) {
                    i2 = max;
                }

                set.insert(i2);
            }
        }
    }

    func getSet(_ type:Int) throws -> Set<Int> {
        
        switch (type) {
            
            case CronExpression.SECOND:
                if(seconds == nil) {seconds = Set<Int>()}
                return seconds!
            
            case CronExpression.MINUTE:
                if(minutes == nil) {minutes = Set<Int>()}
                return minutes!
            
            case CronExpression.HOUR:
                if(hours == nil) {hours = Set<Int>()}
                return hours!
            
            case CronExpression.DAY_OF_MONTH:
                if(daysOfMonth == nil) {daysOfMonth = Set<Int>()}
                return daysOfMonth!
            
            case CronExpression.MONTH:
                if(months == nil) {months = Set<Int>()}
                return months!
            
            case CronExpression.DAY_OF_WEEK:
                if(daysOfWeek == nil) {daysOfWeek = Set<Int>()}
                return daysOfWeek!
            
            case CronExpression.YEAR:
                if(years == nil) {years = Set<Int>()}
                return years!
            
            default:
                throw PushNotificationError.exceptionMsg(msg: "invalid set")
        }
    }

    func getValue(_ v:Int, _ s:String, _ pos:Int) -> (Int, Int) {
        var i:Int = pos
        var c:Character = s.charAt(i)
        var s1:String = String(v)
        
        while (c >= "0" && c <= "9") {
            s1.append(c);
            i+=1
            if (i >= s.count) {
                break;
            }
            c = s.charAt(i);
        }

        let pos = (i < s.count) ? i : i + 1
        let value = Int(s1) ?? -1
        return (pos, value)
    }

    func getNumericValue(_ s:String,_ i:Int) -> Int {
        let endOfVal = findNextWhiteSpace(i, s)
        let val = s.substring(i, endOfVal) ?? "-1"
        return Int(val)!
    }

    func getMonthNumber(_ s:String?) -> Int {
        return CronExpression.monthMap[s ?? "-1"] ?? -1
    }

    func getDayOfWeekNumber(_ s:String?) -> Int {
        return CronExpression.dayMap[s ?? "-1"] ?? -1
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // Computation Functions
    //
    ////////////////////////////////////////////////////////////////////////////

    func getTimeAfter(_ referenceTime:Date?) -> Date? {
        if(referenceTime == nil){ return nil }
        
        var afterTime = referenceTime
        
        // Computation is based on Gregorian year only.
        var cl:Calendar = Calendar(identifier: .gregorian)

        // move ahead one second, since we're computing the time *after* the
        // given time
        afterTime = Date(fromMilliseconds: afterTime!.getTime() + 1000);
        
        // CronTrigger does not deal with milliseconds
        let components = Calendar.current.dateComponents(in: timeZone!, from: afterTime!)

        var gotOne:Bool = false
        
        // loop until we've computed the next time, or we've past the endTime
        while (!gotOne) {

            //if (endTime != null && cl.getTime().after(endTime)) return null;
            if(components.year ?? 3000 > 2999) { // prevent endless loop...
                return nil;
            }

            var st:Set<Int>?;
            var t = 0;

            var sec:Int = components.second!
            var min:Int = components.minute!

            // get second.................................................
            st = getSet(CronExpression.SECOND).split(whereSeparator: { (value:Int) -> Bool in
                return value <= sec
            })[0];
            
            if !(st?.isEmpty ?? true) {
                sec = st[0]
            } else {
                sec = seconds.first();
                min+=1;
                cl.set(Calendar.MINUTE, min);
            }
            cl.set(Calendar.SECOND, sec);

            min = cl.get(Calendar.MINUTE);
            int hr = cl.get(Calendar.HOUR_OF_DAY);
            t = -1;

            // get minute.................................................
            st = minutes.tailSet(min);
            if (st != null && st.size() != 0) {
                t = min;
                min = st.first();
            } else {
                min = minutes.first();
                hr++;
            }
            if (min != t) {
                cl.set(Calendar.SECOND, 0);
                cl.set(Calendar.MINUTE, min);
                setCalendarHour(cl, hr);
                continue;
            }
            cl.set(Calendar.MINUTE, min);

            hr = cl.get(Calendar.HOUR_OF_DAY);
            int day = cl.get(Calendar.DAY_OF_MONTH);
            t = -1;

            // get hour...................................................
            st = hours.tailSet(hr);
            if (st != null && st.size() != 0) {
                t = hr;
                hr = st.first();
            } else {
                hr = hours.first();
                day++;
            }
            if (hr != t) {
                cl.set(Calendar.SECOND, 0);
                cl.set(Calendar.MINUTE, 0);
                cl.set(Calendar.DAY_OF_MONTH, day);
                setCalendarHour(cl, hr);
                continue;
            }
            cl.set(Calendar.HOUR_OF_DAY, hr);

            day = cl.get(Calendar.DAY_OF_MONTH);
            int mon = cl.get(Calendar.MONTH) + 1;
            // '+ 1' because calendar is 0-based for this field, and we are
            // 1-based
            t = -1;
            int tmon = mon;

            // get day...................................................
            boolean dayOfMSpec = !daysOfMonth.contains(NO_SPEC);
            boolean dayOfWSpec = !daysOfWeek.contains(NO_SPEC);
            if (dayOfMSpec && !dayOfWSpec) { // get day by day of month rule
                st = daysOfMonth.tailSet(day);
                if (lastdayOfMonth) {
                    if(!nearestWeekday) {
                        t = day;
                        day = getLastDayOfMonth(mon, cl.get(Calendar.YEAR));
                        day -= lastdayOffset;
                        if(t > day) {
                            mon++;
                            if(mon > 12) {
                                mon = 1;
                                tmon = 3333; // ensure test of mon != tmon further below fails
                                cl.add(Calendar.YEAR, 1);
                            }
                            day = 1;
                        }
                    } else {
                        t = day;
                        day = getLastDayOfMonth(mon, cl.get(Calendar.YEAR));
                        day -= lastdayOffset;

                        Calendar tcal = Calendar.getInstance(getTimeZone());
                        tcal.set(Calendar.SECOND, 0);
                        tcal.set(Calendar.MINUTE, 0);
                        tcal.set(Calendar.HOUR_OF_DAY, 0);
                        tcal.set(Calendar.DAY_OF_MONTH, day);
                        tcal.set(Calendar.MONTH, mon - 1);
                        tcal.set(Calendar.YEAR, cl.get(Calendar.YEAR));

                        int ldom = getLastDayOfMonth(mon, cl.get(Calendar.YEAR));
                        int dow = tcal.get(Calendar.DAY_OF_WEEK);

                        if(dow == Calendar.SATURDAY && day == 1) {
                            day += 2;
                        } else if(dow == Calendar.SATURDAY) {
                            day -= 1;
                        } else if(dow == Calendar.SUNDAY && day == ldom) {
                            day -= 2;
                        } else if(dow == Calendar.SUNDAY) {
                            day += 1;
                        }

                        tcal.set(Calendar.SECOND, sec);
                        tcal.set(Calendar.MINUTE, min);
                        tcal.set(Calendar.HOUR_OF_DAY, hr);
                        tcal.set(Calendar.DAY_OF_MONTH, day);
                        tcal.set(Calendar.MONTH, mon - 1);
                        Date nTime = tcal.getTime();
                        if(nTime.before(afterTime)) {
                            day = 1;
                            mon++;
                        }
                    }
                } else if(nearestWeekday) {
                    t = day;
                    day = daysOfMonth.first();

                    Calendar tcal = Calendar.getInstance(getTimeZone());
                    tcal.set(Calendar.SECOND, 0);
                    tcal.set(Calendar.MINUTE, 0);
                    tcal.set(Calendar.HOUR_OF_DAY, 0);
                    tcal.set(Calendar.DAY_OF_MONTH, day);
                    tcal.set(Calendar.MONTH, mon - 1);
                    tcal.set(Calendar.YEAR, cl.get(Calendar.YEAR));

                    int ldom = getLastDayOfMonth(mon, cl.get(Calendar.YEAR));
                    int dow = tcal.get(Calendar.DAY_OF_WEEK);

                    if(dow == Calendar.SATURDAY && day == 1) {
                        day += 2;
                    } else if(dow == Calendar.SATURDAY) {
                        day -= 1;
                    } else if(dow == Calendar.SUNDAY && day == ldom) {
                        day -= 2;
                    } else if(dow == Calendar.SUNDAY) {
                        day += 1;
                    }


                    tcal.set(Calendar.SECOND, sec);
                    tcal.set(Calendar.MINUTE, min);
                    tcal.set(Calendar.HOUR_OF_DAY, hr);
                    tcal.set(Calendar.DAY_OF_MONTH, day);
                    tcal.set(Calendar.MONTH, mon - 1);
                    Date nTime = tcal.getTime();
                    if(nTime.before(afterTime)) {
                        day = daysOfMonth.first();
                        mon++;
                    }
                } else if (st != null && st.size() != 0) {
                    t = day;
                    day = st.first();
                    // make sure we don't over-run a short month, such as february
                    int lastDay = getLastDayOfMonth(mon, cl.get(Calendar.YEAR));
                    if (day > lastDay) {
                        day = daysOfMonth.first();
                        mon++;
                    }
                } else {
                    day = daysOfMonth.first();
                    mon++;
                }

                if (day != t || mon != tmon) {
                    cl.set(Calendar.SECOND, 0);
                    cl.set(Calendar.MINUTE, 0);
                    cl.set(Calendar.HOUR_OF_DAY, 0);
                    cl.set(Calendar.DAY_OF_MONTH, day);
                    cl.set(Calendar.MONTH, mon - 1);
                    // '- 1' because calendar is 0-based for this field, and we
                    // are 1-based
                    continue;
                }
            } else if (dayOfWSpec && !dayOfMSpec) { // get day by day of week rule
                if (lastdayOfWeek) { // are we looking for the last XXX day of
                    // the month?
                    int dow = daysOfWeek.first(); // desired
                    // d-o-w
                    int cDow = cl.get(Calendar.DAY_OF_WEEK); // current d-o-w
                    int daysToAdd = 0;
                    if (cDow < dow) {
                        daysToAdd = dow - cDow;
                    }
                    if (cDow > dow) {
                        daysToAdd = dow + (7 - cDow);
                    }

                    int lDay = getLastDayOfMonth(mon, cl.get(Calendar.YEAR));

                    if (day + daysToAdd > lDay) { // did we already miss the
                        // last one?
                        cl.set(Calendar.SECOND, 0);
                        cl.set(Calendar.MINUTE, 0);
                        cl.set(Calendar.HOUR_OF_DAY, 0);
                        cl.set(Calendar.DAY_OF_MONTH, 1);
                        cl.set(Calendar.MONTH, mon);
                        // no '- 1' here because we are promoting the month
                        continue;
                    }

                    // find date of last occurrence of this day in this month...
                    while ((day + daysToAdd + 7) <= lDay) {
                        daysToAdd += 7;
                    }

                    day += daysToAdd;

                    if (daysToAdd > 0) {
                        cl.set(Calendar.SECOND, 0);
                        cl.set(Calendar.MINUTE, 0);
                        cl.set(Calendar.HOUR_OF_DAY, 0);
                        cl.set(Calendar.DAY_OF_MONTH, day);
                        cl.set(Calendar.MONTH, mon - 1);
                        // '- 1' here because we are not promoting the month
                        continue;
                    }

                } else if (nthdayOfWeek != 0) {
                    // are we looking for the Nth XXX day in the month?
                    int dow = daysOfWeek.first(); // desired
                    // d-o-w
                    int cDow = cl.get(Calendar.DAY_OF_WEEK); // current d-o-w
                    int daysToAdd = 0;
                    if (cDow < dow) {
                        daysToAdd = dow - cDow;
                    } else if (cDow > dow) {
                        daysToAdd = dow + (7 - cDow);
                    }

                    boolean dayShifted = false;
                    if (daysToAdd > 0) {
                        dayShifted = true;
                    }

                    day += daysToAdd;
                    int weekOfMonth = day / 7;
                    if (day % 7 > 0) {
                        weekOfMonth++;
                    }

                    daysToAdd = (nthdayOfWeek - weekOfMonth) * 7;
                    day += daysToAdd;
                    if (daysToAdd < 0
                            || day > getLastDayOfMonth(mon, cl
                            .get(Calendar.YEAR))) {
                        cl.set(Calendar.SECOND, 0);
                        cl.set(Calendar.MINUTE, 0);
                        cl.set(Calendar.HOUR_OF_DAY, 0);
                        cl.set(Calendar.DAY_OF_MONTH, 1);
                        cl.set(Calendar.MONTH, mon);
                        // no '- 1' here because we are promoting the month
                        continue;
                    } else if (daysToAdd > 0 || dayShifted) {
                        cl.set(Calendar.SECOND, 0);
                        cl.set(Calendar.MINUTE, 0);
                        cl.set(Calendar.HOUR_OF_DAY, 0);
                        cl.set(Calendar.DAY_OF_MONTH, day);
                        cl.set(Calendar.MONTH, mon - 1);
                        // '- 1' here because we are NOT promoting the month
                        continue;
                    }
                } else {
                    int cDow = cl.get(Calendar.DAY_OF_WEEK); // current d-o-w
                    int dow = daysOfWeek.first(); // desired
                    // d-o-w
                    st = daysOfWeek.tailSet(cDow);
                    if (st != null && st.size() > 0) {
                        dow = st.first();
                    }

                    int daysToAdd = 0;
                    if (cDow < dow) {
                        daysToAdd = dow - cDow;
                    }
                    if (cDow > dow) {
                        daysToAdd = dow + (7 - cDow);
                    }

                    int lDay = getLastDayOfMonth(mon, cl.get(Calendar.YEAR));

                    if (day + daysToAdd > lDay) { // will we pass the end of
                        // the month?
                        cl.set(Calendar.SECOND, 0);
                        cl.set(Calendar.MINUTE, 0);
                        cl.set(Calendar.HOUR_OF_DAY, 0);
                        cl.set(Calendar.DAY_OF_MONTH, 1);
                        cl.set(Calendar.MONTH, mon);
                        // no '- 1' here because we are promoting the month
                        continue;
                    } else if (daysToAdd > 0) { // are we swithing days?
                        cl.set(Calendar.SECOND, 0);
                        cl.set(Calendar.MINUTE, 0);
                        cl.set(Calendar.HOUR_OF_DAY, 0);
                        cl.set(Calendar.DAY_OF_MONTH, day + daysToAdd);
                        cl.set(Calendar.MONTH, mon - 1);
                        // '- 1' because calendar is 0-based for this field,
                        // and we are 1-based
                        continue;
                    }
                }
            } else { // dayOfWSpec && !dayOfMSpec
                throw new UnsupportedOperationException(
                        "Support for specifying both a day-of-week AND a day-of-month parameter is not implemented.");
            }
            cl.set(Calendar.DAY_OF_MONTH, day);

            mon = cl.get(Calendar.MONTH) + 1;
            // '+ 1' because calendar is 0-based for this field, and we are
            // 1-based
            int year = cl.get(Calendar.YEAR);
            t = -1;

            // test for expressions that never generate a valid fire date,
            // but keep looping...
            if (year > MAX_YEAR) {
                return null;
            }

            // get month...................................................
            st = months.tailSet(mon);
            if (st != null && st.size() != 0) {
                t = mon;
                mon = st.first();
            } else {
                mon = months.first();
                year++;
            }
            if (mon != t) {
                cl.set(Calendar.SECOND, 0);
                cl.set(Calendar.MINUTE, 0);
                cl.set(Calendar.HOUR_OF_DAY, 0);
                cl.set(Calendar.DAY_OF_MONTH, 1);
                cl.set(Calendar.MONTH, mon - 1);
                // '- 1' because calendar is 0-based for this field, and we are
                // 1-based
                cl.set(Calendar.YEAR, year);
                continue;
            }
            cl.set(Calendar.MONTH, mon - 1);
            // '- 1' because calendar is 0-based for this field, and we are
            // 1-based

            year = cl.get(Calendar.YEAR);
            t = -1;

            // get year...................................................
            st = years.tailSet(year);
            if (st != null && st.size() != 0) {
                t = year;
                year = st.first();
            } else {
                return null; // ran out of years...
            }

            if (year != t) {
                cl.set(Calendar.SECOND, 0);
                cl.set(Calendar.MINUTE, 0);
                cl.set(Calendar.HOUR_OF_DAY, 0);
                cl.set(Calendar.DAY_OF_MONTH, 1);
                cl.set(Calendar.MONTH, 0);
                // '- 1' because calendar is 0-based for this field, and we are
                // 1-based
                cl.set(Calendar.YEAR, year);
                continue;
            }
            cl.set(Calendar.YEAR, year);

            gotOne = true;
        } // while( !done )

        return cl.getTime();
    }

    /**
     * Advance the calendar to the particular hour paying particular attention
     * to daylight saving problems.
     *
     * @param cal the calendar to operate on
     * @param hour the hour to set
     */
    func setCalendarHour(_ cal:Calendar, _ hour:Int) {
        
        cal.set(Calendar.HOUR_OF_DAY, hour);
        if (cal.get(Calendar.HOUR_OF_DAY) != hour && hour != 24) {
            cal.set(Calendar.HOUR_OF_DAY, hour + 1);
        }
    }

    /**
     * NOT YET IMPLEMENTED: Returns the time before the given time
     * that the <code>CronExpression</code> matches.
     */
    public func getTimeBefore(_ endTime:Date) -> Date? {
        // FUTURE_TODO: implement QUARTZ-423
        return nil;
    }

    /**
     * NOT YET IMPLEMENTED: Returns the final time that the
     * <code>CronExpression</code> will match.
     */
    public func getFinalFireTime() -> Date? {
        // FUTURE_TODO: implement QUARTZ-423
        return nil
    }

    func isLeapYear(_ year:Int) -> Bool {
        return ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0))
    }

    func getLastDayOfMonth(_ monthNum:Int, _ year:Int) throws -> Int {

        switch (monthNum) {
            case 1:
                return 31;
            case 2:
                return (isLeapYear(year)) ? 29 : 28;
            case 3:
                return 31;
            case 4:
                return 30;
            case 5:
                return 31;
            case 6:
                return 30;
            case 7:
                return 31;
            case 8:
                return 31;
            case 9:
                return 30;
            case 10:
                return 31;
            case 11:
                return 30;
            case 12:
                return 31;
            default:
                throw PushNotificationError.cronException(msg: "Illegal month number", monthNum)
        }
    }

    public func clone() -> CronExpression {
        return CronExpression(self)
    }*/
}

class ValueSet {
    public var value:Int?
    public var pos:Int?
}
