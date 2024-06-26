/* Copyright Airship and Contributors */

// Legacy transformers. We still need these around for coredata migrations.
// Do not use these anymore, its almost always a better idea to use Codables
// instead.


/// NOTE: For internal use only. :nodoc:
@objc(UAJSONValueTransformer)
public class JSONValueTransformer: ValueTransformer {

    public override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }

    public override class func allowsReverseTransformation() -> Bool {
        return true
    }

    public override func transformedValue(_ value: Any?) -> Any? {

        guard let value = value else {
            return nil
        }

        do {
            return try AirshipJSONUtils.data(
                value,
                options: JSONSerialization.WritingOptions.prettyPrinted
            )
        } catch {
            AirshipLogger.error(
                "Failed to transform value: \(value), error: \(error)"
            )
            return nil
        }
    }

    public override func reverseTransformedValue(_ value: Any?) -> Any? {

        guard let value = value as? Data else {
            return nil
        }

        do {
            return try JSONSerialization.jsonObject(
                with: value,
                options: .mutableContainers
            )
        } catch {
            AirshipLogger.error(
                "Failed to reverse transform value: \(value), error: \(error)"
            )
            return nil
        }
    }
}

/// NOTE: For internal use only. :nodoc:
@objc(UANSDictionaryValueTransformer)
public class NSDictionaryValueTransformer: ValueTransformer {

    public override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }

    public override class func allowsReverseTransformation() -> Bool {
        return true
    }

    public override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value else {
            return nil
        }

        do {
            return try NSKeyedArchiver.archivedData(
                withRootObject: value,
                requiringSecureCoding: true
            )
        } catch {
            AirshipLogger.error(
                "Failed to transform value: \(value), error: \(error)"
            )
            return nil
        }
    }

    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let value = value as? Data else {
            return nil
        }

        do {
            let classes = [
                NSString.self, NSDictionary.self, NSArray.self, NSSet.self,
                NSData.self,
                NSNumber.self, NSDate.self, NSURL.self, NSUUID.self,
                NSNull.self,
            ]
            return try NSKeyedUnarchiver.unarchivedObject(
                ofClasses: classes,
                from: value
            )
        } catch {
            AirshipLogger.error(
                "Failed to reverse transform value: \(value), error: \(error)"
            )
            return nil
        }
    }
}

// NOTE: For internal use only. :nodoc:
@objc(UANSURLValueTransformer)
public class NSURLValueTransformer: ValueTransformer {

    public override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }

    public override class func allowsReverseTransformation() -> Bool {
        return true
    }

    public override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value else {
            return nil
        }

        do {
            return try NSKeyedArchiver.archivedData(
                withRootObject: value,
                requiringSecureCoding: true
            )
        } catch {
            AirshipLogger.error(
                "Failed to transform value: \(value), error: \(error)"
            )
            return nil
        }
    }

    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let value = value as? Data else {
            return nil
        }

        do {
            return try NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSURL.self,
                from: value
            )
        } catch {
            AirshipLogger.error(
                "Failed to reverse transform value: \(value), error: \(error)"
            )
            return nil
        }
    }
}

// NOTE: For internal use only. :nodoc:
@objc(UANSArrayValueTransformer)
public class NSArrayValueTransformer: ValueTransformer {

    public override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }

    public override class func allowsReverseTransformation() -> Bool {
        return true
    }

    public override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value else {
            return nil
        }

        do {
            return try NSKeyedArchiver.archivedData(
                withRootObject: value,
                requiringSecureCoding: true
            )
        } catch {
            AirshipLogger.error(
                "Failed to transform value: \(value), error: \(error)"
            )
            return nil
        }
    }

    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let value = value as? Data else {
            return nil
        }

        do {
            let classes = [
                NSString.self, NSDictionary.self, NSArray.self, NSSet.self,
                NSData.self,
                NSNumber.self, NSDate.self, NSURL.self, NSUUID.self,
                NSNull.self,
            ]
            return try NSKeyedUnarchiver.unarchivedObject(
                ofClasses: classes,
                from: value
            )
        } catch {
            AirshipLogger.error(
                "Failed to reverse transform value: \(value), error: \(error)"
            )
            return nil
        }
    }
}
