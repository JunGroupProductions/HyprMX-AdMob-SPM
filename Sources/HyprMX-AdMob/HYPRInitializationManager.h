#import <Foundation/Foundation.h>
@import HyprMX;
#import "HyprMXAdapterConfiguration.h"
@import GoogleMobileAds;

@interface HYPRInitializationManager : NSObject
@property (atomic, strong) NSMutableArray<GADMediationAdapterSetUpCompletionBlock> *completionCallbackBlocks;
+ (HYPRInitializationManager *)sharedInstance;
- (void)initializeSDKWithCredentials:(GADMediationCredentials *)credentials
                       childDirected:(NSNumber *)childDirected
                   completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler;
@end
