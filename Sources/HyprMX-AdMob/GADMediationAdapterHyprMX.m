//
//  GADMediationAdapterHyprMX.m
//  HyprMX-AdMob-QA
//
//  Created by Sean Reinhardt on 8/5/22.
//

#import "GADMediationAdapterHyprMX.h"
#import "HyprMXAdapterConfiguration+Internal.h"
#import "HYPRInitializationManager.h"
@import HyprMX;

NSString * const kServerParameterKey = @"parameter";
NSString * const kHyprMXAdErrorDomain = @"HyprMXAdError";
// The release build number - corresponds to the matching HyprSDK Version
NSString * const kHyprMarketplace_PatchVersion = @"0";
// The build number of this adapter
NSInteger const kHyprMarketplace_BuildNumber = 140;

@implementation GADMediationAdapterHyprMX

@synthesize placement = _placement;
- (HyprMXPlacement *)placement {
    if (!_placement) {
        HyprMXPlacement *p = [HyprMX getPlacement:self.placementName];
        _placement = p;
    }
    return _placement;
}

/**
 * The version of the adapter.
 * Adapters are tied to SDKs and have a build number of their own.
 * In terms of reporting, we report only build number of the adapter
 *
 * @return The version of the adapter
 */
+ (GADVersionNumber)adapterVersion {
    GADVersionNumber version = {0};
    version.patchVersion = kHyprMarketplace_BuildNumber;
    return version;
}

/**
 * Defines the SDK Version that we are tied to
 *
 * @return The version of the SDK we are tied to
 */
+ (GADVersionNumber)adSDKVersion {
    NSArray *versionComponents = [[HyprMX versionString] componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    if (versionComponents.count == 3) {
        version.majorVersion = [versionComponents[0] integerValue];
        version.minorVersion = [versionComponents[1] integerValue];
        version.patchVersion = [versionComponents[2] integerValue];
    }
    return version;
}

+ (NSString *)hyprmxAdMobAdapterVersion {
    return [NSString stringWithFormat:@"%@.%@", [HyprMX versionString], kHyprMarketplace_PatchVersion];
}

/**
 * The extras class that is used to specify additional parameters for a request to this ad network.
 */
+ (Class <GADAdNetworkExtras>)networkExtrasClass {
    return nil;
}


/// Tells the adapter to set up its underlying ad network SDK and perform any necessary prefetching
/// or configuration work. The adapter must call completionHandler once the adapter can service ad
/// requests, or if it encounters an error while setting up.
+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [GADMediationAdapterHyprMX synchronizeAgeRestricted];
        [[HYPRInitializationManager sharedInstance] initializeSDKWithCredentials:configuration.credentials.firstObject
                                                                   childDirected:nil
                                                               completionHandler: completionHandler];
    }];
}

- (void)loadAdWithAdConfiguration:(nonnull GADMediationAdConfiguration *)adConfiguration {
    if ([self canLoadRequest]) {
        [GADMediationAdapterHyprMX synchronizeAgeRestricted];
        [self loadAdWithAdCredentials:adConfiguration.credentials];
    } else {
        [self failedToSetupAdapter];
    }
}

- (void)loadAdWithAdCredentials:(nonnull GADMediationCredentials *)credentials {
    // Support for Preinit AdNetworks == false
    if (HyprMX.initializationStatus == NOT_INITIALIZED) {
        __weak typeof(self) weakSelf = self;
        [[HYPRInitializationManager sharedInstance] initializeSDKWithCredentials:credentials
            childDirected:GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment
            completionHandler:^(NSError * _Nullable error) {
            [weakSelf loadAdWithAdCredentials:credentials];
        }];
        return;
    }
    HyprMXAdapterConfiguration *config = [HyprMXAdapterConfiguration fromServerParameter:credentials.settings[kServerParameterKey]];
    self.placementName = config.placementName;
    
    if (!self.placementName) {
        NSLog(@"[HYPRAdMobRewardedAdapter] loadRewardedAdForAdConfiguration requested with no placement name");
        [self failedToSetupAdapter];
        return;
    }
    if (!self.placement) {
        NSLog(@"[HYPRAdMobRewardedAdapter] loadAd requested for placement in-progress");
        [self failedToSetupAdapter];
        return;
    }
    NSLog(@"[HYPRAdMobRewardedAdapter] loadRewardedAdForAdConfiguration for placement %@", self.placementName);
    NSLog(@"[HYPRAdMobRewardedAdapter] Loading ad for placement %@", self.placementName);
    __weak typeof(self) weakSelf = self;
    [[self placement] loadAdWithCompletion:^(BOOL success) {
        if (success) {
            weakSelf.placement.expiredDelegate = weakSelf;
            [weakSelf adAvailableForPlacement:[weakSelf placement]];
        } else {
            [weakSelf adNotAvailableForPlacement:[weakSelf placement]];
        }
    }];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    if ([[self placement] isAdAvailable]) {
        // The reward based video ad is available, present the ad.
        [[self placement] showAdFromViewController:viewController delegate:self];
    } else {
        NSError *error =
                [NSError errorWithDomain:kHyprMXAdErrorDomain
                                    code:HyprMXAdMobErrorCodeNoAdAvailable
                                userInfo:@{NSLocalizedDescriptionKey: @"Unable to display ad."}];
        [self.delegate didFailToPresentWithError:error];
    }
}

- (void)adWillStartForPlacement:(HyprMXPlacement *)placement {
    [self.delegate willPresentFullScreenView];
    [self.delegate reportImpression];
}

- (void)adDidCloseForPlacement:(HyprMXPlacement *)placement didFinishAd:(BOOL)finished {
    [self.delegate willDismissFullScreenView];
    [self.delegate didDismissFullScreenView];
    
    // Disconnect placement from this adapter instance so it can be used by a new instance
    self.placement.expiredDelegate = nil;
}

- (void)adDisplayError:(NSError *)error placement:(HyprMXPlacement *)placement {
    NSLog(@"[GADMediationAdapterHyprMX] Error displaying %@ ad: %@", placement.placementName, error.localizedDescription);
    [self.delegate didFailToPresentWithError:error];
}

- (void)adExpiredForPlacement:(HyprMXPlacement *)placement {
    // No AdMob support
    NSLog(@"[GADMediationAdapterHyprMX] The Ad for %@ has expired", self.placementName);
}

- (void)adAvailableForPlacement:(HyprMXPlacement *)placement {
    NSLog(@"[GADMediationAdapterHyprMX] Ad available for placement: %@", self.placementName);
}

- (void)adNotAvailableForPlacement:(HyprMXPlacement *)placement {
    NSLog(@"[GADMediationAdapterHyprMX] no Ads available for placement: %@", self.placementName);
}

+ (NSError *)setupError {
    return  [NSError errorWithDomain:kHyprMXAdErrorDomain
                                code:HyprMXAdMobErrorCodeAdapterConfigurationError
                            userInfo:@{NSLocalizedDescriptionKey:@"Rewarded Adapter not initialized"}
    ];
}

- (void)failedToSetupAdapter {
    
}

- (BOOL)canLoadRequest {
    // we're still initializing from pre-init, unsafe to load ad
    if (HyprMX.initializationStatus == INITIALIZING) {
        NSLog(@"[HYPRInitializationManager] loadRequestWithConfig requested while preinitialization in progress. Denying ad load request");
        return NO;
    }
    return YES;
}

+ (void)synchronizeAgeRestricted {
    [HyprMX setAgeRestrictedUser:[GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment boolValue]];
}
@end
