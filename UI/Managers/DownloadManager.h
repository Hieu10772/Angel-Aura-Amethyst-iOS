#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, DownloadType) {
    DownloadTypeMod,
    DownloadTypeShader,
    DownloadTypeResourcePack,
    DownloadTypeMap,
    DownloadTypeServer,
    DownloadTypeModpack
};

@interface DownloadTask : NSObject
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *url;
@property (nonatomic) DownloadType type;
@property (nonatomic) NSString *targetPath;
@property (nonatomic) float progress;
@property (nonatomic) BOOL isFinished;
@property (nonatomic) NSError *error;
@end

@interface DownloadManager : NSObject

@property (class, readonly) DownloadManager *shared;

- (void)downloadMod:(NSString *)url name:(NSString *)name version:(NSString *)version completion:(void(^)(BOOL success, NSError *error))completion;
- (void)downloadShader:(NSString *)url name:(NSString *)name version:(NSString *)version completion:(void(^)(BOOL success, NSError *error))completion;
- (void)downloadResourcePack:(NSString *)url name:(NSString *)name version:(NSString *)version completion:(void(^)(BOOL success, NSError *error))completion;
- (void)downloadMap:(NSString *)url name:(NSString *)name version:(NSString *)version completion:(void(^)(BOOL success, NSError *error))completion;
- (void)downloadToPath:(NSString *)url targetPath:(NSString *)targetPath completion:(void(^)(BOOL success, NSError *error))completion;

@end
