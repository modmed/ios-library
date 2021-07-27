/* Copyright Airship and Contributors */

#import "UAOpenExternalURLAction.h"
#import "UAirship.h"
#import "UAURLAllowList.h"
#import "UADispatcher.h"

NSString * const UAOpenExternalURLActionDefaultRegistryName = @"open_external_url_action";
NSString * const UAOpenExternalURLActionDefaultRegistryAlias = @"^u";

NSString * const UAOpenExternalURLActionErrorDomain = @"com.urbanairship.actions.externalurlaction";

@implementation UAOpenExternalURLAction

- (BOOL)acceptsArguments:(UAActionArguments *)arguments {
    if (arguments.situation == UASituationBackgroundPush || arguments.situation == UASituationBackgroundInteractiveButton) {
        return NO;
    }

    NSURL *url = [UAOpenExternalURLAction parseURLFromArguments:arguments];
    if (!url) {
        return NO;
    }

    if (![[UAirship shared].URLAllowList isAllowed:url scope:UAURLAllowListScopeOpenURL]) {
        UA_LERR(@"URL %@ not allowed. Unable to open URL.", url);
        return NO;
    }

    return YES;
}

- (void)performWithArguments:(UAActionArguments *)arguments
           completionHandler:(UAActionCompletionHandler)completionHandler {

    NSURL *url = [UAOpenExternalURLAction parseURLFromArguments:arguments];

    // do this in the background in case we're opening our own app!
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self openURL:url completionHandler:completionHandler];
    });
}

- (void)openURL:(NSURL *)url completionHandler:(UAActionCompletionHandler)completionHandler {
   [[UADispatcher mainDispatcher] dispatchAsync:^{
#if NS_EXTENSION_UNAVAILABLE_IOS
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                // Unable to open url
                NSError *error =  [NSError errorWithDomain:UAOpenExternalURLActionErrorDomain
                                                      code:UAOpenExternalURLActionErrorCodeURLFailedToOpen
                                                  userInfo:@{NSLocalizedDescriptionKey : @"Unable to open URL"}];

                completionHandler([UAActionResult resultWithError:error]);
            } else {
                completionHandler([UAActionResult resultWithValue:url.absoluteString]);
            }
        }];
#endif
   }];
}

+ (nullable NSURL *)parseURLFromArguments:(UAActionArguments *)arguments {
    if (![arguments.value isKindOfClass:[NSString class]] && ![arguments.value isKindOfClass:[NSURL class]]) {
        return nil;
    }

    return [arguments.value isKindOfClass:[NSURL class]] ? arguments.value : [NSURL URLWithString:arguments.value];
}

@end
