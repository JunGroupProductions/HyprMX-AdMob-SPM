//
//  GADMediationAdapterHyprMX.h
//  HyprMX-AdMob-QA
//
//  Created by Sean Reinhardt on 8/5/22.
//

#import <Foundation/Foundation.h>
@import GoogleMobileAds;
@import HyprMX;
NS_ASSUME_NONNULL_BEGIN

extern NSString * const kHyprMXAdErrorDomain;
extern NSString * const kServerParameterKey;

typedef NS_ENUM(NSInteger, HyprMXAdMobErrorCode) {
    HyprMXAdMobErrorCodeLoadInProgress,
    HyprMXAdMobErrorCodeNoAdAvailable,
    HyprMXAdMobErrorCodeAdapterConfigurationError
};
@interface GADMediationAdapterHyprMX : NSObject
<
GADMediationAdapter,
GADMediationRewardedAd,
GADMediationInterstitialAd,
HyprMXPlacementShowDelegate,
HyprMXPlacementExpiredDelegate
>

@property(nonatomic, weak, nullable) id <GADMediationAdEventDelegate> delegate;
@property(nonatomic, strong, nullable) NSString *placementName;
@property(nonatomic, strong, nullable) HyprMXPlacement *placement;

- (void)loadAdWithAdConfiguration:(nonnull GADMediationAdConfiguration *)adConfiguration;
- (void)adAvailableForPlacement:(HyprMXPlacement *)placement;
- (void)adNotAvailableForPlacement:(HyprMXPlacement *)placement;
+ (NSError *)setupError;
- (void)failedToSetupAdapter;
+ (NSString *)hyprmxAdMobAdapterVersion;
- (BOOL)canLoadRequest;
+ (void)synchronizeAgeRestricted;
@end

NS_ASSUME_NONNULL_END
