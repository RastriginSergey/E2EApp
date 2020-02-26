#import <Foundation/Foundation.h>

/**
 @brief Object containing NXMClient endpoints configuration.
 */
@interface NXMClientConfig : NSObject

@property (nonnull, nonatomic, readonly) NSString *apiUrl;
@property (nonnull, nonatomic, readonly) NSString *websocketUrl;
@property (nonnull, nonatomic, readonly) NSString *ipsUrl;
@property (nonnull, nonatomic, readonly) NSArray<NSString *> *iceServerUrls;

/**
 @brief Default values:
     apiURL:        @"https://api.nexmo.com/"
     websocketUrl:  @"https://ws.nexmo.com/"
     ipsUrl:        @"https://api.nexmo.com/v1/image/"
     iceServerUrls: @[@"stun:stun.l.google.com:19302"]
 */
- (nonnull instancetype)init;

- (nonnull instancetype)initWithApiUrl:(nonnull NSString *)apiURL
                          websocketUrl:(nonnull NSString *)websocketUrl
                                ipsUrl:(nonnull NSString *)ipsUrl;

- (nonnull instancetype)initWithApiUrl:(nonnull NSString *)apiURL
                          websocketUrl:(nonnull NSString *)websocketUrl
                                ipsUrl:(nonnull NSString *)ipsUrl
                         iceServerUrls:(nonnull NSArray<NSString *> *)iceServerUrls;

+ (nonnull NXMClientConfig *)LON;
+ (nonnull NXMClientConfig *)SNG;
+ (nonnull NXMClientConfig *)DAL;
+ (nonnull NXMClientConfig *)WDC;

@end
