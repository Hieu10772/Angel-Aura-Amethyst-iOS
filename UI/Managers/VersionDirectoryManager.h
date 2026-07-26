#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VersionProfile : NSObject
@property (nonatomic) NSString *versionId;
@property (nonatomic) NSString *mcVersion;
@property (nonatomic) NSString *modLoader;
+ (instancetype)profileWithVersionId:(NSString *)versionId;
- (NSString *)iconName;
@end

@interface VersionDirectoryManager : NSObject

@property (class, readonly) VersionDirectoryManager *shared;
@property (nonatomic) NSString *currentVersion;
@property (nonatomic) NSString *currentInstance;
@property (nonatomic, nullable) VersionProfile *currentProfile;

+ (NSString *)autoDetectLwjglVersionForMcVersion:(NSString *)mcVersion;
+ (NSString *)resolveEffectiveLwjglVersion;

- (NSString *)instancePath;
- (NSString *)versionsRootPath;
- (NSString *)versionPathForVersion:(NSString *)version;

- (NSString *)downloadsPath;
- (NSString *)modsPathForVersion:(NSString *)version;
- (NSString *)savesPathForVersion:(NSString *)version;
- (NSString *)resourcePacksPathForVersion:(NSString *)version;
- (NSString *)shaderPacksPathForVersion:(NSString *)version;
- (NSString *)serversPathForVersion:(NSString *)version;

- (void)ensureVersionDirectoriesForVersion:(NSString *)version;
- (void)prepareGameDirectoryForVersion:(NSString *)version;
- (void)refreshCurrentProfile;

@end

NS_ASSUME_NONNULL_END
