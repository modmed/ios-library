/* Copyright Airship and Contributors */

#import "UALegacyInAppMessaging+Internal.h"
#import "UALegacyInAppMessage.h"
#import "UAInAppMessageResolutionEvent+Internal.h"
#import "UAInAppMessage+Internal.h"
#import "UAInAppMessageSchedule.h"
#import "UAInAppAutomation.h"
#import "UAInAppMessageBannerDisplayContent.h"
#import "UAAirshipAutomationCoreImport.h"

// Legacy key for the last displayed message ID
NSString *const UALastDisplayedInAppMessageID = @"UALastDisplayedInAppMessageID";

// The default primary color for IAMs: white
#define kUALegacyInAppMessageDefaultPrimaryColor [UIColor whiteColor]

// The default secondary color for IAMs: gray-ish
#define kUALegacyInAppMessageDefaultSecondaryColor [UIColor colorWithRed:(28.0/255.0) green:(28.0/255.0) blue:(28.0/255.0) alpha:1]

// APNS payload key
#define kUALegacyIncomingInAppMessageKey @"com.urbanairship.in_app"

// Message Center action name
#define kUALegacyMessageCenterActionName @"_uamid"

@interface UALegacyInAppMessaging ()
@property(nonatomic, strong) UAPreferenceDataStore *dataStore;
@property(nonatomic, strong) UAAnalytics *analytics;
@property(nonatomic, weak) UAInAppAutomation *inAppAutomation;
@end

@implementation UALegacyInAppMessaging

- (instancetype)initWithAnalytics:(UAAnalytics *)analytics
                        dataStore:(UAPreferenceDataStore *)dataStore
                  inAppAutomation:(UAInAppAutomation *)inAppAutomation {

    self = [super initWithDataStore:dataStore];
    if (self) {
        // Clean up the old datastore
        [self.dataStore removeObjectForKey:kUAPendingInAppMessageDataStoreKey];
        [self.dataStore removeObjectForKey:kUAAutoDisplayInAppMessageDataStoreKey];
        [self.dataStore removeObjectForKey:UALastDisplayedInAppMessageID];

        self.dataStore = dataStore;
        self.analytics = analytics;
        self.inAppAutomation = inAppAutomation;

        self.factoryDelegate = self;
        self.displayASAPEnabled = YES;
    }

    return self;
}

+ (instancetype)inAppMessagingWithAnalytics:(UAAnalytics *)analytics
                                  dataStore:(UAPreferenceDataStore *)dataStore
                            inAppAutomation:(UAInAppAutomation *)inAppAutomation {

    return [[UALegacyInAppMessaging alloc] initWithAnalytics:analytics
                                                   dataStore:dataStore
                                             inAppAutomation:inAppAutomation];
}

- (NSString *)pendingMessageID {
    return [self.dataStore objectForKey:kUAPendingInAppMessageIDDataStoreKey];
}

- (void)setPendingMessageID:(NSString *)pendingMessageID {
    [self.dataStore setObject:pendingMessageID forKey:kUAPendingInAppMessageIDDataStoreKey];
}

-(void)receivedNotificationResponse:(UANotificationResponse *)response completionHandler:(void (^)(void))completionHandler {
    NSDictionary *apnsPayload = response.notificationContent.notificationInfo;
    if (!apnsPayload[kUALegacyIncomingInAppMessageKey]) {
        completionHandler();
        return;
    }

    NSString *newMessageID = apnsPayload[@"_"];
    NSString *pendingMessageID = self.pendingMessageID;

    if (newMessageID.length && [newMessageID isEqualToString:pendingMessageID]) {
        UA_WEAKIFY(self);
        [self.inAppAutomation cancelScheduleWithID:pendingMessageID completionHandler:^(BOOL result) {
            UA_STRONGIFY(self)
            if (result) {
                UA_LTRACE(@"The in-app message delivery push was directly launched for message: %@", pendingMessageID);

                UAInAppMessageResolutionEvent *event = [UAInAppMessageResolutionEvent legacyDirectOpenEventWithMessageID:pendingMessageID];
                [self.analytics addEvent:event];
            }

            self.pendingMessageID = nil;
            completionHandler();
        }];
    } else {
        completionHandler();
    }
}

-(void)receivedRemoteNotification:(UANotificationContent *)notification completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // Set the send ID as the IAM unique identifier
    NSDictionary *apnsPayload = notification.notificationInfo;
    if (!apnsPayload[kUALegacyIncomingInAppMessageKey]) {
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }

    NSMutableDictionary *messagePayload = [NSMutableDictionary dictionaryWithDictionary:apnsPayload[kUALegacyIncomingInAppMessageKey]];
    UALegacyInAppMessage *message = [UALegacyInAppMessage messageWithPayload:messagePayload];

    if (apnsPayload[@"_"]) {
        message.identifier = apnsPayload[@"_"];
    }

    // Copy the `_uamid` into the onClick actions if set on the payload to support launching the MC from an IAM
    if (apnsPayload[kUALegacyMessageCenterActionName]) {
        NSMutableDictionary *actions = [NSMutableDictionary dictionaryWithDictionary:message.onClick];
        actions[kUALegacyMessageCenterActionName] = apnsPayload[kUALegacyMessageCenterActionName];
        message.onClick = actions;
    }

    [self scheduleMessage:message];
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)scheduleMessage:(UALegacyInAppMessage *)message {
    UASchedule *schedule =  [self.factoryDelegate scheduleForMessage:message];
    if (!schedule) {
        UA_LERR(@"Failed to convert legacy in-app automation: %@", message);
        return;
    }

    NSString *previousMessageID = self.pendingMessageID;

    // If there is a pending message ID, cancel it
    if (previousMessageID) {
        UA_WEAKIFY(self)
        [self.inAppAutomation cancelScheduleWithID:previousMessageID completionHandler:^(BOOL result) {
            UA_STRONGIFY(self)
            if (result) {
                UA_LDEBUG(@"LegacyInAppMessageManager - Pending in-app message replaced");
                UAInAppMessageResolutionEvent *event = [UAInAppMessageResolutionEvent legacyReplacedEventWithMessageID:previousMessageID replacementID:schedule.identifier];
                [self.analytics addEvent:event];
            }
        }];
    }

    self.pendingMessageID = schedule.identifier;
    [self.inAppAutomation schedule:schedule completionHandler:^(BOOL result) {
        UA_LDEBUG(@"LegacyInAppMessageManager - saved schedule: %@ result: %d", schedule, result);
    }];
}

- (UASchedule *)scheduleForMessage:(UALegacyInAppMessage *)message {
    UIColor *primaryColor = message.primaryColor ? message.primaryColor : kUALegacyInAppMessageDefaultPrimaryColor;
    UIColor *secondaryColor = message.secondaryColor ? message.secondaryColor : kUALegacyInAppMessageDefaultSecondaryColor;
    CGFloat borderRadius = 2;

    UAInAppMessageBannerDisplayContent *displayContent = [UAInAppMessageBannerDisplayContent displayContentWithBuilderBlock:^(UAInAppMessageBannerDisplayContentBuilder * _Nonnull builder) {
        builder.backgroundColor = primaryColor;
        builder.dismissButtonColor = secondaryColor;
        builder.borderRadiusPoints = borderRadius;
        builder.buttonLayout = UAInAppMessageButtonLayoutTypeSeparate;
        builder.placement = message.position == UALegacyInAppMessagePositionTop ? UAInAppMessageBannerPlacementTop : UAInAppMessageBannerPlacementBottom;
        builder.actions = message.onClick;

        UAInAppMessageTextInfo *textInfo = [UAInAppMessageTextInfo textInfoWithBuilderBlock:^(UAInAppMessageTextInfoBuilder * _Nonnull builder) {
            builder.text = message.alert;
            builder.color = secondaryColor;
        }];

        builder.body = textInfo;

        builder.durationSeconds = message.duration;

        NSMutableArray<UAInAppMessageButtonInfo *> *buttonInfos = [NSMutableArray array];

        for (int i = 0; i < message.notificationActions.count; i++) {
            if (i > UAInAppMessageBannerMaxButtons) {
                break;
            }
            UANotificationAction *notificationAction = [message.notificationActions objectAtIndex:i];
            UAInAppMessageTextInfo *labelInfo = [UAInAppMessageTextInfo textInfoWithBuilderBlock:^(UAInAppMessageTextInfoBuilder * _Nonnull builder) {
                builder.alignment = UAInAppMessageTextInfoAlignmentCenter;
                builder.color = primaryColor;
                builder.text = notificationAction.title;
            }];

            UAInAppMessageButtonInfo *buttonInfo = [UAInAppMessageButtonInfo buttonInfoWithBuilderBlock:^(UAInAppMessageButtonInfoBuilder * _Nonnull builder) {
                builder.actions = message.buttonActions[notificationAction.identifier];
                builder.identifier = notificationAction.identifier;
                builder.backgroundColor = secondaryColor;
                builder.borderRadiusPoints = borderRadius;
                builder.label = labelInfo;
            }];

            if (buttonInfo) {
                [buttonInfos addObject:buttonInfo];
            }
        }

        builder.buttons = buttonInfos;
    }];

    id<UALegacyInAppMessageBuilderExtender> extender = self.builderExtender;

    UAInAppMessage *inAppMessage = [UAInAppMessage messageWithBuilderBlock:^(UAInAppMessageBuilder * _Nonnull builder) {
        builder.displayContent = displayContent;
        builder.extras = message.extra;

        // Allow the app to customize the message builder if necessary
        if (extender && [extender respondsToSelector:@selector(extendMessageBuilder:message:)]) {
            [extender extendMessageBuilder:builder message:message];
        }

        builder.identifier = message.identifier;
        builder.source = UAInAppMessageSourceLegacyPush;
    }];

    return [UAInAppMessageSchedule scheduleWithMessage:inAppMessage
                                          builderBlock:^(UAScheduleBuilder * _Nonnull builder) {

        UAScheduleTrigger *trigger;

        // In terms of the scheduled message model, displayASAP means using an active session trigger.
        // Otherwise the closest analog to the v1 behavior is the foreground trigger.
        if (self.displayASAPEnabled) {
            trigger = [UAScheduleTrigger activeSessionTriggerWithCount:1];
        } else {
            trigger = [UAScheduleTrigger foregroundTriggerWithCount:1];
        }

        builder.triggers = @[trigger];
        builder.end = message.expiry;
        builder.identifier = message.identifier;

        // Allow the app to customize the schedule info builder if necessary
        if (extender && [extender respondsToSelector:@selector(extendScheduleBuilder:message:)]) {
            [extender extendScheduleBuilder:builder message:message];
        }
    }];
}

@end
