/* Copyright Airship and Contributors */

#import <Foundation/Foundation.h>

#if !TARGET_OS_TV

#import "UANativeBridge+Internal.h"
#import "UAGlobal.h"
#import "UAirship.h"
#import "UAURLAllowList.h"
#import "UAJavaScriptCommand.h"
#import "NSString+UAURLEncoding.h"
#import "UANativeBridgeActionHandler+Internal.h"
#import "UANamedUser.h"

NSString *const UANativeBridgeUAirshipScheme = @"uairship";
NSString *const UANativeBridgeCloseCommand = @"close";
NSString *const UANativeBridgeSetNamedUserCommand = @"named_user";
NSString *const UANativeBridgeMultiCommand = @"multi";

@interface UANativeBridge()
@property (nonatomic, strong, nonnull) UANativeBridgeActionHandler *actionHandler;
@property (nonatomic, copy, nonnull) UAJavaScriptEnvironment *(^javaScriptEnvironmentFactoryBlock)(void);
@end

@implementation UANativeBridge

#pragma mark UANavigationDelegate

- (instancetype)initWithActionHandler:(UANativeBridgeActionHandler *)actionHandler
    javaScriptEnvironmentFactoryBlock:(UAJavaScriptEnvironment *(^)(void))javaScriptEnvironmentFactoryBlock {

    self = [super init];
    if (self) {
        self.actionHandler = actionHandler;
        self.javaScriptEnvironmentFactoryBlock = javaScriptEnvironmentFactoryBlock;
    }

    return self;
}

+(instancetype)nativeBridge {
    return [[self alloc] initWithActionHandler:[[UANativeBridgeActionHandler alloc] init]
             javaScriptEnvironmentFactoryBlock:^UAJavaScriptEnvironment *{
        return [UAJavaScriptEnvironment defaultEnvironment];
    }];
}

+ (instancetype)nativeBridgeWithActionHandler:(UANativeBridgeActionHandler *)actionHandler
            javaScriptEnvironmentFactoryBlock:(UAJavaScriptEnvironment * (^)(void))javaScriptEnvironmentFactoryBlock {

    return [[self alloc] initWithActionHandler:actionHandler javaScriptEnvironmentFactoryBlock:javaScriptEnvironmentFactoryBlock];
}

/**
 * Decide whether to allow or cancel a navigation.
 *
 * If a uairship:// URL, process it ourselves
 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    WKNavigationType navigationType = navigationAction.navigationType;
    NSURLRequest *request = navigationAction.request;
    NSURL *originatingURL = webView.URL;

    // Always handle uairship urls
    if ([self isAllowedAirshipRequest:request originatingURL:originatingURL]) {
        if ((navigationType == WKNavigationTypeLinkActivated) || (navigationType == WKNavigationTypeOther)) {
            UAJavaScriptCommand *command = [UAJavaScriptCommand commandForURL:request.URL];
            [self handleAirshipCommand:command webView:webView];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    // If the forward delegate responds to the selector, let it decide
    id strongDelegate = self.forwardNavigationDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [strongDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:^(WKNavigationActionPolicy policyForThisURL) {
            // Override any special link actions
            if ((policyForThisURL == WKNavigationActionPolicyAllow) && (navigationType == WKNavigationTypeLinkActivated)) {
                [self handleLinkClick:request.URL completionHandler:^(BOOL success) {
                    decisionHandler(success ? WKNavigationActionPolicyCancel : WKNavigationActionPolicyAllow);
                }];
                return;
            }
            decisionHandler(policyForThisURL);
        }];
        return;
    }

    void (^handleLink)(void) = ^{
        // If target frame is a new window navigation, have OS handle it
        if (!navigationAction.targetFrame) {
#if NS_EXTENSION_UNAVAILABLE_IOS
            [[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{} completionHandler:^(BOOL success) {
                decisionHandler(success ? WKNavigationActionPolicyCancel : WKNavigationActionPolicyAllow);
            }];
            return;
#endif
        }

        // Default behavior
        decisionHandler(WKNavigationActionPolicyAllow);
    };

    // Override any special link actions
    if (navigationType == WKNavigationTypeLinkActivated) {
        [self handleLinkClick:request.URL completionHandler:^(BOOL success) {
            if (success) {
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
            handleLink();
        }];
    } else {
        handleLink();
    }
}

/**
 * Decide whether to allow or cancel a navigation after its response is known.
 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    id strongDelegate = self.forwardNavigationDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationResponse:decisionHandler:)]) {
        [strongDelegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationResponsePolicyAllow);
    }
}

/**
 * Called when the navigation is complete.
 */
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self populateJavascriptEnvironmentIfAllowed:webView];
    id strongDelegate = self.forwardNavigationDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [strongDelegate webView:webView didFinishNavigation:navigation];
    }
}

/**
 * Called when the web view’s web content process is terminated.
 */
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    id strongDelegate = self.forwardNavigationDelegate;
    if ([strongDelegate respondsToSelector:@selector(webViewWebContentProcessDidTerminate:)]) {
        [strongDelegate webViewWebContentProcessDidTerminate:webView];
    }
}

/**
 * Called when the web view begins to receive web content.
 */
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    id strongDelegate = self.forwardNavigationDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didCommitNavigation:)]) {
        [strongDelegate webView:webView didCommitNavigation:navigation];
    }
}

/**
 * Called when web content begins to load in a web view.
 */
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    id strongDelegate = self.forwardNavigationDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [strongDelegate webView:webView didStartProvisionalNavigation:navigation];
    }
}

/**
 * Called when an error occurs during navigation.
 */
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    id strongDelegate = self.forwardNavigationDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didFailNavigation:withError:)]) {
        [strongDelegate webView:webView didFailNavigation:navigation withError:error];
    }
}

/**
 * Called when an error occurs while the web view is loading content.
 */
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    id strongDelegate = self.forwardNavigationDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
        [strongDelegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}

/**
 * Called when a web view receives a server redirect.
 */
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    id strongDelegate = self.forwardNavigationDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didReceiveServerRedirectForProvisionalNavigation:)]) {
        [strongDelegate webView:webView didReceiveServerRedirectForProvisionalNavigation:navigation];
    }
}

/**
 * Called when the web view needs to respond to an authentication challenge.
 */
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    id strongDelegate = self.forwardNavigationDelegate;
    if ([strongDelegate respondsToSelector:@selector(webView:didReceiveAuthenticationChallenge:completionHandler:)]) {
        [strongDelegate webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)closeWindowAnimated:(BOOL)animated {
    id strongDelegate = self.forwardNavigationDelegate;
    if ([strongDelegate respondsToSelector:@selector(closeWindowAnimated:)]) {
        [strongDelegate closeWindowAnimated:animated];
    }
}

- (void)populateJavascriptEnvironmentIfAllowed:(WKWebView *)webView  {
    NSURL *url = webView.URL;
    if (![[UAirship shared].URLAllowList isAllowed:url scope:UAURLAllowListScopeJavaScriptInterface]) {
        // Don't log in the special case of about:blank URLs
        if (![url.absoluteString isEqualToString:@"about:blank"]) {
            UA_LDEBUG(@"URL %@ is not allowed, not populating JS interface", url);
        }
        return;
    }

    UAJavaScriptEnvironment *js = self.javaScriptEnvironmentFactoryBlock();
    id nativeBridgeExtensionDelegate = self.nativeBridgeExtensionDelegate;
    if ([nativeBridgeExtensionDelegate respondsToSelector:@selector(extendJavaScriptEnvironment:webView:)]) {
        [nativeBridgeExtensionDelegate extendJavaScriptEnvironment:js webView:webView];
    }

    [webView evaluateJavaScript:[js build] completionHandler:nil];
}

- (void)handleAirshipCommand:(UAJavaScriptCommand *)command webView:(WKWebView *)webView {
    // Close
    if ([command.name isEqualToString:UANativeBridgeCloseCommand]) {
        [self.nativeBridgeDelegate close];
        return;
    }

    // Actions
    if ([UANativeBridgeActionHandler isActionCommand:command]) {
        NSDictionary *metadata;
        id nativeBridgeExtensionDelegate = self.nativeBridgeExtensionDelegate;
        if ([nativeBridgeExtensionDelegate respondsToSelector:@selector(actionsMetadataForCommand:webView:)]) {
            metadata = [nativeBridgeExtensionDelegate actionsMetadataForCommand:command webView:webView];
        } else {
            metadata = @{};
        }

        __weak WKWebView *weakWebView = webView;
        [self.actionHandler runActionsForCommand:command
                                        metadata:metadata
                               completionHandler:^(NSString *script) {
            if (script) {
                [weakWebView evaluateJavaScript:script completionHandler:nil];
            }
        }];
        return;
    }
    
    // Set named user command
    if ([command.name isEqualToString:UANativeBridgeSetNamedUserCommand]) {
        NSArray *idArgs = command.options[@"id"];
        NSString *argument = idArgs.firstObject;
    
        if (!argument || [argument isKindOfClass:[NSNull class]]) {
            UA_LERR(@"Malformed Named User command: %@", argument);
        } else {
            [UAirship namedUser].identifier = argument;
        }
    }

    // Multi command
    if ([command.name isEqualToString:UANativeBridgeMultiCommand]) {
        NSArray *URLs = [command.URL.query componentsSeparatedByString:@"&"];
        for (NSString *URLString in URLs) {
            NSURL *URL = [NSURL URLWithString:[URLString stringByRemovingPercentEncoding]];
            if ([[URL scheme] isEqualToString:UANativeBridgeUAirshipScheme]) {
                UAJavaScriptCommand *command = [UAJavaScriptCommand commandForURL:URL];
                [self handleAirshipCommand:command webView:webView];
            }
        }
        return;
    }
    
    // Local JavaScript command delegate
    if ([self.javaScriptCommandDelegate performCommand:command webView:webView]) {
        return;
    }

    // App defined JavaScript command delegate
    if ([[UAirship shared].javaScriptCommandDelegate performCommand:command webView:webView]) {
        return;
    }

    UA_LDEBUG(@"Unhandled JavaScript command: %@", command);
}

/**
 * Handles a link click.
 *
 * @param url The link's URL.
 * @param completion  The completion handler to execute when openURL processing is complete.
 */
- (void)handleLinkClick:(NSURL *)url completionHandler:(void (^)(BOOL success))completion NS_EXTENSION_UNAVAILABLE_IOS("Uses APIs not available for use in App Extensions.") {
    NSArray *forwardSchemes = @[@"itms-apps", @"maps", @"sms", @"tel", @"mailto"];
    NSArray *forwardHosts = @[@"maps.google.com", @"www.youtube.com", @"phobos.apple.com", @"itunes.apple.com"];
    if ([forwardSchemes containsObject:[url scheme].lowercaseString] || [forwardHosts containsObject:[url host].lowercaseString]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            // Its better to return YES here and no-op on these links instead of reporting an unhandled URL
            // to avoid the message thinking it failed to load. The only time a NO will happen is on a simulator
            // without access to the app store.
            completion(YES);
        }];
    } else {
        completion(NO);
    }
}

- (BOOL)isAirshipRequest:(NSURLRequest *)request {
    return [[request.URL scheme] isEqualToString:UANativeBridgeUAirshipScheme];
}

- (BOOL)isAllowed:(NSURL *)url {
    return [[UAirship shared].URLAllowList isAllowed:url scope:UAURLAllowListScopeJavaScriptInterface];
}

- (BOOL)isAllowedAirshipRequest:(NSURLRequest *)request originatingURL:(NSURL *)originatingURL {
    // uairship://command/[<arguments>][?<options>]
    return [self isAirshipRequest:request] && [self isAllowed:originatingURL];
}

@end

#endif
