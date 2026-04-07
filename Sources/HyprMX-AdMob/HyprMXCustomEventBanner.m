//
//  HyprMXCustomEventBanner.m
//  HyprMX-AdMob-QA
//
//  Created by Sean Reinhardt on 7/29/21.
//

#import "HyprMXCustomEventBanner.h"
#import "HyprMXAdapterConfiguration+Internal.h"
#import "HYPRInitializationManager.h"
@import HyprMX;
@interface HyprMXCustomEventBanner () <HyprMXBannerDelegate>
@property (strong, nonatomic) HyprMXBannerView *bannerView;
@property(nonatomic, strong, nullable) GADMediationBannerLoadCompletionHandler completionHandler;
@end

@implementation HyprMXCustomEventBanner

-(UIView *)view {
    return self.bannerView;
}

/// Asks the adapter to load a banner ad with the provided ad configuration. The adapter must call
/// back completionHandler with the loaded ad, or it may call back with an error. This method is
/// called on the main thread, and completionHandler must be called back on the main thread.
- (void)loadBannerForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:
(nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
    
    // Support for Preinit AdNetworks == false
    if (HyprMX.initializationStatus == NOT_INITIALIZED) {
        __weak typeof(self) weakSelf = self;
        [[HYPRInitializationManager sharedInstance] initializeSDKWithCredentials:adConfiguration.credentials
            childDirected:GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment
            completionHandler:^(NSError * _Nullable error) {
            [weakSelf loadBannerForAdConfiguration:adConfiguration completionHandler:completionHandler];
        }];
        return;
    }
    HyprMXAdapterConfiguration *config = [HyprMXAdapterConfiguration fromServerParameter:adConfiguration.credentials.settings[kServerParameterKey]];
    CGSize size = adConfiguration.adSize.size;
    self.completionHandler = completionHandler;
    if ([self canLoadRequest]) {
        [[self class] synchronizeAgeRestricted];
        [self initializeBannerViewWithConfiguration:config size:size];
    } else {
        [self adFailedToLoad:self.bannerView error:self.class.setupError];
    }
}

-(void)initializeBannerViewWithConfiguration:(HyprMXAdapterConfiguration *)config
                                        size:(CGSize)size {
    self.bannerView = [[HyprMXBannerView alloc] initWithPlacementName:config.placementName
                                                               adSize:size];
    self.bannerView.placementDelegate = self;
    [self.bannerView loadAdWithCompletion:^(BOOL success) {
        if (success) {
            [self adDidLoad:self.bannerView];
        } else {
            NSString* description = @"There is no fill available for this placement";
            NSDictionary* userInfo = @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
            [self adFailedToLoad:self.bannerView error:[NSError errorWithDomain:@"HyprMXAdError" code:NO_FILL userInfo:userInfo]];
        }
    }];
}

-(void)adDidLoad:(HyprMXBannerView *)bannerView {
    self.delegate = self.completionHandler(self, nil);
    self.completionHandler = nil;
    [self.delegate reportImpression];
}

-(void)adFailedToLoad:(HyprMXBannerView *)bannerView error:(NSError *)error {
    if (self.completionHandler == nil) {
        NSLog(@"[HyprMXCustomEventBanner] adFailedToLoad -- self.completionHandler == nil");
        self.delegate = nil;
        return;
    }
    self.completionHandler(self, error);
    self.completionHandler = nil;
    self.delegate = nil;
}

-(void)adDidOpen:(HyprMXBannerView *)bannerView {
    [self.delegate willPresentFullScreenView];
}

-(void)adDidClose:(HyprMXBannerView *)bannerView {
    [self.delegate willDismissFullScreenView];
    [self.delegate didDismissFullScreenView];
}

-(void)adWasClicked:(HyprMXBannerView *)bannerView {
    [self.delegate reportClick];
}

@end
