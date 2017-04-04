// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


extension MassFormatter {
    public enum Unit : Int {
        
        case gram = 11
        case kilogram = 14
        case ounce = 1537
        case pound = 1538
        case stone = 1539

        // Map Unit to UnitMass class to aid with conversions
        fileprivate var unitMass: UnitMass {
            switch self {
            case .gram:
                return UnitMass.grams
            case .kilogram:
                return UnitMass.kilograms
            case .ounce:
                return UnitMass.ounces
            case .pound:
                return UnitMass.pounds
            case .stone:
                return UnitMass.stones
            }
        }

        // Reuse symbols defined in UnitMass
        fileprivate var symbol: String {
            return unitMass.symbol
        }

        // Return singular, full string representation of the mass unit
        fileprivate var singularString: String {
            switch self {
            case .gram:
                return "gram"
            case .kilogram:
                return "kilogram"
            case .ounce:
                return "ounce"
            case .pound:
                return "pound"
            case .stone:
                return "stone"

            }
        }

        // Return plural, full string representation of the mass unit
        fileprivate var pluralString: String {
            return "\(self.singularString)s"
        }

    }
}
    
open class MassFormatter : Formatter {
    
    public override init() {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        unitStyle = .medium
        isForPersonMassUse = false
        super.init()
    }

    public required init?(coder: NSCoder) {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        unitStyle = .medium
        isForPersonMassUse = false
        super.init()
    }
    
    /*@NSCopying*/ open var numberFormatter: NumberFormatter! // default is NSNumberFormatter with NSNumberFormatterDecimalStyle
    open var unitStyle: UnitStyle // default is NSFormattingUnitStyleMedium
    open var isForPersonMassUse: Bool // default is NO; if it is set to YES, the number argument for -stringFromKilograms: and -unitStringFromKilograms: is considered as a person’s mass
    
    // Format a combination of a number and an unit to a localized string.
    open func string(fromValue value: Double, unit: Unit) -> String {
        guard let formattedValue = numberFormatter.string(from:NSNumber(value: value)) else {
            fatalError("Cannot format \(value) as string")
        }

        let separator = unitStyle == MassFormatter.UnitStyle.short ? "" : " "
        return "\(formattedValue)\(separator)\(unitString(fromValue: value, unit: unit))"
    }

    // Format a number in kilograms to a localized string with the locale-appropriate unit and an appropriate scale (e.g. 1.2kg = 2.64lb in the US locale).
    open func string(fromKilograms numberInKilograms: Double) -> String {

        //Convert to the locale-appropriate unit
        let unitFromKilograms: Unit = unit(fromKilograms: numberInKilograms)

        //Map the unit to UnitMass type for conversion later
        let unitMassFromKilograms = unitFromKilograms.unitMass

        //Create a measurement object based on the value in kilograms
        let kilogramsMeasurement = Measurement<UnitMass>(value:numberInKilograms, unit: .kilograms)

        //Convert the object to the locale-appropriate unit determined above
        let unitMeasurement = kilogramsMeasurement.converted(to: unitMassFromKilograms)

        //Extract the number from the measurement
        let numberInUnit = unitMeasurement.value

        return string(fromValue: numberInUnit, unit: unitFromKilograms)
    }
    
    // Return a localized string of the given unit, and if the unit is singular or plural is based on the given number.
    open func unitString(fromValue value: Double, unit: Unit) -> String {

        if unitStyle == .short || unitStyle == .medium {
            return unit.symbol
        } else if value == 1.0 {
            return unit.singularString
        } else {
            return unit.pluralString
        }
    }

    // Return the locale-appropriate unit, the same unit used by -stringFromKilograms:.
    open func unitString(fromKilograms numberInKilograms: Double, usedUnit unitp: UnsafeMutablePointer<Unit>?) -> String {
        
        //Convert to the locale-appropriate unit
        let unitFromKilograms: Unit = unit(fromKilograms: numberInKilograms)
        unitp?.pointee = unitFromKilograms

        //Map the unit to UnitMass type for conversion later
        let unitMassFromKilograms = unitFromKilograms.unitMass

        //Create a measurement object based on the value in kilograms
        let kilogramsMeasurement = Measurement<UnitMass>(value:numberInKilograms, unit: .kilograms)

        //Convert the object to the locale-appropriate unit determined above
        let unitMeasurement = kilogramsMeasurement.converted(to: unitMassFromKilograms)

        //Extract the number from the measurement
        let numberInUnit = unitMeasurement.value

        //Return the appropriate representation of the unit based on the selected unit style
        return unitString(fromValue: numberInUnit, unit: unitFromKilograms)
    }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    open override func objectValue(_ string: String) throws -> Any? { return nil }

    /// This method selects the appropriate unit based on the formatter’s locale,
    /// the magnitude of the value, and isForPersonMassUse property.
    ///
    /// - Parameter numberInKilograms: the magnitude in terms of kilograms
    /// - Returns: Returns the appropriate unit
    private func unit(fromKilograms numberInKilograms: Double) -> Unit {
        if MassFormatter.isMetricSystemLocale(numberFormatter.locale) {
            if numberInKilograms > 0.0 || numberInKilograms < 1.0 {
                return .gram
            } else {
                return .kilogram
            }
        } else {
            let metricMeasurement = Measurement<UnitMass>(value:numberInKilograms, unit: .kilograms)
            let ouncesMeasurement = metricMeasurement.converted(to: .ounces)
            let numberInOunces = ouncesMeasurement.value

            if numberInOunces < 0.0 || numberInOunces > 16 {
                return .pound
            } else {
                return .ounce
            }
        }
    }

    /// TODO: Replace calls to the below function to use Locale.usesMetricSystem
    /// Temporary workaround due to unpopulated Locale attributes
    /// See https://bugs.swift.org/browse/SR-3202
    private static func isMetricSystemLocale(_ locale: Locale) -> Bool {
        switch locale.identifier {
        case "en_US": return false
        case "en_US_POSIX": return false
        case "haw_US": return false
        case "es_US": return false
        case "chr_US": return false
        case "my_MM": return false
        case "en_LR": return false
        case "vai_LR": return false
        default: return true
        }
    }
}


