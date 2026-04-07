//
//  HyprMXAdapterConfiguration.m
//  HyprMX-AdMob-QA
//
//  Created by Sean Reinhardt on 10/7/21.
//

#import "HyprMXAdapterConfiguration.h"
#import "HyprMXAdapterConfiguration+Internal.h"

NSString * const kHyprMarketplaceAppConfigKeyDistributorId = @"distributorId";
NSString * const kHyprMarketplaceAppConfigKeyPlacementName = @"placementName";

@interface HyprMXAdapterConfiguration()
@property (strong, atomic, readonly) NSString *distributorId;
@property (strong, atomic, readonly) NSString *placementName;
@property (class, nonatomic) HyprConsentStatus consentStatus;
+ (nullable instancetype)fromServerParameter:(NSString*)serverParameter;
@end

@implementation HyprMXAdapterConfiguration

static HyprConsentStatus hyprmxCustomConsentStatus = CONSENT_STATUS_UNKNOWN;

@synthesize distributorId = _distributorId;
-(void)setDistributorId:(NSString * _Nonnull)distributorId {
    _distributorId = distributorId;
}

@synthesize placementName = _placementName;
-(void)setPlacementName:(NSString * _Nonnull)placementName {
    _placementName = placementName;
}

+(void)setHasUserConsent:(BOOL)hasUserConsent {
    [self setConsentStatus:(hasUserConsent ? CONSENT_GIVEN : CONSENT_DECLINED)];
}

+(HyprConsentStatus)consentStatus {
    return hyprmxCustomConsentStatus;
}

+(void)setConsentStatus:(HyprConsentStatus)consentStatus {
    hyprmxCustomConsentStatus = consentStatus;
    [HyprMX setConsentStatus:hyprmxCustomConsentStatus];
}

+ (nullable instancetype)fromServerParameter:(NSString*)serverParameter {
    if (!serverParameter
            || ![serverParameter isKindOfClass:NSString.class]
            || serverParameter.length == 0) {

        NSLog(@"[HyprMX] HYPRAdMobVideoAdapter could not initialize - serverParameter must be a non-empty string. Please check your AdMob Dashboard's AdUnit Settings");

        return nil;
    }
    
    HyprMXAdapterConfiguration *config = HyprMXAdapterConfiguration.new;
    
    NSError *error;
    NSMutableDictionary *decodedJSON = [[NSJSONSerialization JSONObjectWithData:[serverParameter dataUsingEncoding:NSUTF8StringEncoding]
                                                                        options:0
                                                                          error:&error] mutableCopy];
    if (error) {
        NSLog(@"[HyprMX] HYPRAdMobVideoAdapter could not parse JSON in server parameter");

        /*
         * We assume in this case the server parameter is just the distributor ID as a string
         */
        config.distributorId = serverParameter;
        return config;
    }

    config.distributorId = [self clientDistributorIdFromDictionary:decodedJSON];
    config.placementName = [self clientPlacementNameFromDictionary:decodedJSON];
    return config;
}

+ (NSString *)clientDistributorIdFromDictionary:(NSDictionary *)dictionary {
    return [HyprMXAdapterConfiguration clientValueForParam:kHyprMarketplaceAppConfigKeyDistributorId
                                                dictionary:dictionary];
}

+ (NSString *)clientPlacementNameFromDictionary:(NSDictionary *)dictionary {
    return [HyprMXAdapterConfiguration clientValueForParam:kHyprMarketplaceAppConfigKeyPlacementName
                                                dictionary:dictionary];
}


+ (nullable NSString *)clientValueForParam:(NSString *)param dictionary:(NSDictionary *)dictionary {
    NSArray *keys = [dictionary allKeys];
    NSUInteger index = [keys indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj respondsToSelector:(@selector(lowercaseString))] && [[(NSString *)obj lowercaseString] isEqualToString:[param lowercaseString]];
    }];
    return index == NSNotFound ? nil : dictionary[keys[index]];
}

@end

/** Unity API */

void HYPRUMHyprMXSetConsent(BOOL hasUserConsent) {
    [HyprMXAdapterConfiguration setHasUserConsent:hasUserConsent];
}
