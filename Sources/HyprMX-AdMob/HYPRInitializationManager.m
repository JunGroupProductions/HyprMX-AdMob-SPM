#import "HYPRInitializationManager.h"
@import GoogleMobileAds;
#import "HyprMXAdapterConfiguration+Internal.h"
#import "GADMediationAdapterHyprMX.h"

@interface HYPRInitializationManager()
@property (nonatomic, strong) NSString *hyprDistributorId;
@end

@implementation HYPRInitializationManager

+ (HYPRInitializationManager *)sharedInstance {
    static HYPRInitializationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _completionCallbackBlocks = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)initializeSDKWithCredentials:(GADMediationCredentials *)credentials
                       childDirected:(NSNumber *)childDirected
              completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
    HyprMXAdapterConfiguration *config = [self parseServerCredentials:credentials];
    if (self.hyprDistributorId && ![self.hyprDistributorId isEqualToString:config.distributorId]) {
        NSLog(@"[HyprMX] WARNING: HYPRManager already initialized with another distributor ID");
        if (completionHandler) {
            completionHandler([GADMediationAdapterHyprMX setupError]);
        }
        return;
    }
    GADMediationAdapterSetUpCompletionBlock handler = [completionHandler copy];
    if (handler != nil && self.completionCallbackBlocks.count > 0) {
        NSLog(@"[HyprMX] Initialization already in progress.  Waiting for init response");
        [self.completionCallbackBlocks addObject:handler];
        return;
    }
    BOOL shouldInitialize = NO;
    switch (HyprMX.initializationStatus) {
        case NOT_INITIALIZED:
        case INITIALIZATION_FAILED:
            NSLog(@"[HyprMX] Initializing SDK with Distributor Id: %@", config.distributorId);

            if (completionHandler) {
                [self.completionCallbackBlocks addObject:handler];
            }
            shouldInitialize = YES;
            self.hyprDistributorId = config.distributorId;
            break;
        case INITIALIZING:
            NSLog(@"[HyprMX] Initialization already in progress.  Waiting for init response");
            // Note.  What should we do here when the parameter changes during an init request?
            if (completionHandler) {
                [self.completionCallbackBlocks addObject:handler];
            }
            break;
        case INITIALIZATION_COMPLETE:
            if (completionHandler) {
                completionHandler(nil);
            }
            break;
    }
    if (shouldInitialize) {
        [HyprMX setMediationProvider:HyprMXMediationProviderAdmob
                  mediatorSDKVersion:GADGetStringFromVersionNumber(GADMobileAds.sharedInstance.versionNumber)
                      adapterVersion:GADMediationAdapterHyprMX.hyprmxAdMobAdapterVersion];
        [HyprMX setConsentStatus:HyprMXAdapterConfiguration.consentStatus];
        [HyprMX setAgeRestrictedUser:GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment];
        [HyprMX initWithDistributorId:config.distributorId completion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self initializationDidComplete];
            } else {
                [self initializationFailed];
            }
        }];
    }
}

-(HyprMXAdapterConfiguration *)parseServerCredentials:(GADMediationCredentials *) credentials {
        if (credentials.settings[kServerParameterKey]) {
            HyprMXAdapterConfiguration *config = [HyprMXAdapterConfiguration fromServerParameter:credentials.settings[kServerParameterKey]];
            if (config.distributorId) {
                return config;
            }
        }
    NSLog(@"[HYPRInitializationManager] Error parsing adapter configuration from credentials");
    return nil;
}

- (void)initializationDidComplete {
    NSLog(@"[HYPR] initializationDidComplete with %lu callbacks to fire", (unsigned long)self.completionCallbackBlocks.count);
    for (GADMediationAdapterSetUpCompletionBlock callback in self.completionCallbackBlocks) {
        callback(nil);
    }
    [self.completionCallbackBlocks removeAllObjects];
}

- (void)initializationFailed {
    NSLog(@"[HYPR] initializationFailed with %lu callbacks to fire", (unsigned long)self.completionCallbackBlocks.count);
    for (GADMediationAdapterSetUpCompletionBlock callback in self.completionCallbackBlocks) {
        callback([GADMediationAdapterHyprMX setupError]);
    }
    [self.completionCallbackBlocks removeAllObjects];
}

@end
