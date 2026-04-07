#import "HYPRAdMobVideoAdapter.h"
@import HyprMX;

@interface HYPRAdMobVideoAdapter ()
@property(nonatomic, strong, nullable) GADMediationInterstitialLoadCompletionHandler completionHandler;
@end

@implementation HYPRAdMobVideoAdapter


/// Asks the adapter to load an interstitial ad with the provided ad configuration. The adapter
/// must call back completionHandler with the loaded ad, or it may call back with an error. This
/// method is called on the main thread, and completionHandler must be called back on the main
/// thread.
- (void)loadInterstitialForAdConfiguration:
            (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)
completionHandler {
    
    if (self.completionHandler != nil) {
        NSString *description = @"[HYPRAdMobRewardedAdapter] loadInterstitialForAdConfiguration requested with load in progress";
        NSLog(@"%@", description);
        NSDictionary* userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
        completionHandler(nil, [NSError errorWithDomain:kHyprMXAdErrorDomain
                                                   code:HyprMXAdMobErrorCodeLoadInProgress
                                               userInfo:userInfo]);
        return;
    }
    self.completionHandler = completionHandler;
    [self loadAdWithAdConfiguration:adConfiguration];
}

- (void)adAvailableForPlacement:(HyprMXPlacement *)placement {
    if (self.completionHandler == nil) {
        NSLog(@"[HYPRAdMobVideoAdapter] adAvailableForPlacement -- self.completionHandler == nil");
        return;
    }

    self.delegate = self.completionHandler(self, nil);
    self.completionHandler = nil;
}

- (void)adNotAvailableForPlacement:(HyprMXPlacement *)placement {
    if (self.completionHandler == nil) {
        NSLog(@"[HYPRAdMobVideoAdapter] adNotAvailableForPlacement -- self.completionHandler == nil");
        return;
    }

    NSError *error = [NSError errorWithDomain:kHyprMXAdErrorDomain
                                         code:HyprMXAdMobErrorCodeNoAdAvailable
                                     userInfo:@{NSLocalizedDescriptionKey:
                                             @"No Ads Available"}];

    self.completionHandler(nil, error);
    self.completionHandler = nil;
}

- (void)failedToSetupAdapter {
    [super failedToSetupAdapter];
    if (self.completionHandler == nil) {
        NSLog(@"[HYPRAdMobVideoAdapter] failedToSetupRewardedAdapter -- self.completionHandler == nil");
        return;
    }

    self.completionHandler(nil, [self.class setupError]);
    self.completionHandler = nil;
}
@end


