#if UA_USE_MODULE_IMPORT
#import <AirshipCore/AirshipCore.h>
#else
#import "NSObject+UAAdditions.h"
#import "NSJSONSerialization+UAAdditions.h"
#import "NSString+UALocalizationAdditions.h"
#import "NSString+UAURLEncoding.h"
#import "UAAction.h"
#import "UAActionArguments.h"
#import "UAActionResult.h"
#import "UAActionRunner.h"
#import "UAAnalytics.h"
#import "UAAppIntegration.h"
#import "UAApplicationMetrics.h"
#import "UAAsyncOperation.h"
#import "UAAutomationModuleLoaderFactory.h"
#import "UABespokeCloseView.h"
#import "UABeveledLoadingIndicator.h"
#import "UAChannel.h"
#import "UAColorUtils.h"
#import "UAComponent.h"
#import "UAConfig.h"
#import "UACustomEvent.h"
#import "UADate.h"
#import "UADeepLinkAction.h"
#import "UADisposable.h"
#import "UAEvent.h"
#import "UAGlobal.h"
#import "UAJSONMatcher.h"
#import "UAJSONPredicate.h"
#import "UAJSONValueMatcher.h"
#import "UAModuleLoader.h"
#import "UANotificationAction.h"
#import "UANotificationCategories.h"
#import "UANotificationCategory.h"
#import "UANotificationContent.h"
#import "UANotificationResponse.h"
#import "UAPadding.h"
#import "UAPush.h"
#import "UAPushableComponent.h"
#import "UARegionEvent.h"
#import "UARemoteDataPayload.h"
#import "UARuntimeConfig.h"
#import "UASystemVersion.h"
#import "UATagGroups.h"
#import "UAUtils.h"
#import "UAViewUtils.h"
#import "UA_Base64.h"
#import "UAirship.h"
#import "UAirshipVersion.h"
#import "UAJavaScriptCommand.h"
#import "UAJavaScriptCommandDelegate.h"
#import "UAJavaScriptEnvironment.h"
#import "UANativeBridge.h"
#import "UANativeBridgeDelegate.h"
#import "UANativeBridgeExtensionDelegate.h"
#import "UAWebView.h"
#import "UADispatcher.h"
#import "UARemoteDataProvider.h"
#import "UAVersionMatcher.h"
#import "UACoreData.h"
#import "UAActionPredicateProtocol.h"
#import "UAJSONSerialization.h"
#import "UANamedUser.h"
#import "UATagGroupsMutation.h"
#import "UAAttributePendingMutations.h"
#import "UALocaleManager.h"
#import "UATaskManager.h"
#import "NSDictionary+UAAdditions.h"
#import "UANetworkMonitor.h"
#endif
