/* Copyright Airship and Contributors */

#import "UAAddTagsAction.h"
#import "UAChannel.h"
#import "UAirship.h"

#if __has_include("AirshipCore/AirshipCore-Swift.h")
#import <AirshipCore/AirshipCore-Swift.h>
#elif __has_include("Airship/Airship-Swift.h")
#import <Airship/Airship-Swift.h>
#endif

@implementation UAAddTagsAction

NSString * const UAAddTagsActionDefaultRegistryName = @"add_tags_action";
NSString * const UAAddTagsActionDefaultRegistryAlias = @"^+t";

- (void)applyChannelTags:(NSArray *)tags {
    [[UAirship channel] addTags:tags];
}

- (void)applyChannelTags:(NSArray *)tags group:(NSString *)group {
    UATagGroupsEditor *editor = [[UAirship channel] editTagGroups];
    [editor addTags:tags group:group];
    [editor apply];}

- (void)applyNamedUserTags:(NSArray *)tags group:(NSString *)group {
    UATagGroupsEditor *editor = [[UAirship contact] editTagGroups];
    [editor addTags:tags group:group];
    [editor apply];
}

@end
