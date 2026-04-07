#import "HYPRAdMobRewardedAdapter.h"
@import HyprMX;

@interface HYPRAdMobRewardedAdapter ()
@property(nonatomic, strong, nullable) GADMediationRewardedLoadCompletionHandler completionHandler;
@end

@implementation HYPRAdMobRewardedAdapter

- (id <GADMediationRewardedAdEventDelegate>)rewardedDelegate {
    return (id <GADMediationRewardedAdEventDelegate>)[self delegate];
}

/**
  * Asks the adapter to load a rewarded ad with the provided ad configuration. The adapter must
  * call back completionHandler with the loaded ad, or it may call back with an error. This method
  * is called on the main thread, and completionHandler must be called back on the main thread.
  */
- (void)loadRewardedAdForAdConfiguration:(nonnull GADMediationAdConfiguration *)adConfiguration
                       completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {

    if (self.completionHandler != nil) {
        NSString *description = @"[HYPRAdMobRewardedAdapter] loadRewardedAdForAdConfiguration requested with load in progress";
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

- (void)adWillStartForPlacement:(HyprMXPlacement *)placement {
    [super adWillStartForPlacement:placement];
    [self.rewardedDelegate didStartVideo];
}

- (void)adDidCloseForPlacement:(HyprMXPlacement *)placement
                   didFinishAd:(BOOL)finished {
    [self.rewardedDelegate didEndVideo];
    [super adDidCloseForPlacement:placement didFinishAd:finished];
}

- (void)adDidRewardForPlacement:(HyprMXPlacement *)placement
                     rewardName:(NSString *)rewardName
                    rewardValue:(NSInteger)rewardValue {
    /**
     * AdMob 9.8.0 introduced `GADMediationRewardedAdEventDelegate didRewardUser` and deprecated
     * `GADMediationRewardedAdEventDelegate didRewardUserWithReward:`
     *  This dynamic selector determination can be removed when the adpapter minimum support version reaches 9.8.0 or greater.
     */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL selector = @selector(didRewardUser);
    if (selector && [self.rewardedDelegate respondsToSelector:selector]) {
        NSLog(@"[HYPRAdMobRewardedAdapter] didRewardUser");
        [self.rewardedDelegate performSelector:@selector(didRewardUser)];
        return;
    }
    SEL legacySelector = @selector(didRewardUserWithReward:);
    if (legacySelector && [self.rewardedDelegate respondsToSelector:legacySelector]) {
        NSLog(@"[HYPRAdMobRewardedAdapter] didRewardUserWithReward:");
        [self.rewardedDelegate performSelector:@selector(didRewardUserWithReward:)
                                    withObject:GADAdReward.new];
        return;
    }
#pragma clang diagnostic pop
    NSLog(@"[HYPRAdMobRewardedAdapter] error - unable to invoke didRewardUser callback");
}

- (void)adAvailableForPlacement:(HyprMXPlacement *)placement {
    [super adAvailableForPlacement:placement];
    if (self.completionHandler == nil) {
        NSLog(@"[HYPRAdMobRewardedAdapter] adAvailableForPlacement -- self.completionHandler == nil");
        return;
    }

    self.delegate = self.completionHandler(self, nil);
    self.completionHandler = nil;
}

- (void)adNotAvailableForPlacement:(HyprMXPlacement *)placement {
    [super adNotAvailableForPlacement:placement];
    if (self.completionHandler == nil) {
        NSLog(@"[HYPRAdMobRewardedAdapter] adNotAvailableForPlacement -- self.completionHandler == nil");
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
        NSLog(@"[HYPRAdMobRewardedAdapter] failedToSetupRewardedAdapter -- self.completionHandler == nil");
        return;
    }

    self.completionHandler(nil, [self.class setupError]);
    self.completionHandler = nil;
}
@end
