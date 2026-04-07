//
//  HyprMXAdapterConfiguration+Internal.h
//  HyprMX-AdMob-QA
//
//  Created by Sean Reinhardt on 10/7/21.
//

#import "HyprMXAdapterConfiguration.h"

@interface HyprMXAdapterConfiguration(Internal)
@property (strong, atomic, readonly, nullable) NSString *distributorId;
@property (strong, atomic, readonly, nullable) NSString *placementName;
@property (class, nonatomic) HyprConsentStatus consentStatus;
+ (nullable instancetype)fromServerParameter:(nullable NSString *)serverParameter;
@end
