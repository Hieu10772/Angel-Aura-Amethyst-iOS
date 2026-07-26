#import "DownloadManager.h"
#import "VersionDirectoryManager.h"
#import "AFNetworking.h"

@implementation DownloadTask
@end

@interface DownloadManager ()
@property (nonatomic) NSMutableArray<DownloadTask *> *activeTasks;
@end

@implementation DownloadManager

+ (DownloadManager *)shared {
    static DownloadManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _activeTasks = [NSMutableArray array];
    }
    return self;
}

- (void)downloadMod:(NSString *)url name:(NSString *)name version:(NSString *)version completion:(void(^)(BOOL, NSError *))completion {
    NSString *modsDir = [VersionDirectoryManager.shared modsPathForVersion:version];
    NSString *targetPath = [modsDir stringByAppendingPathComponent:name];
    if (![targetPath hasSuffix:@".jar"]) {
        targetPath = [targetPath stringByAppendingPathExtension:@"jar"];
    }
    [self downloadToPath:url targetPath:targetPath completion:completion];
}

- (void)downloadShader:(NSString *)url name:(NSString *)name version:(NSString *)version completion:(void(^)(BOOL, NSError *))completion {
    NSString *shaderDir = [VersionDirectoryManager.shared shaderPacksPathForVersion:version];
    NSString *targetPath = [shaderDir stringByAppendingPathComponent:name];
    if (![targetPath hasSuffix:@".zip"]) {
        targetPath = [targetPath stringByAppendingPathExtension:@"zip"];
    }
    [self downloadToPath:url targetPath:targetPath completion:completion];
}

- (void)downloadResourcePack:(NSString *)url name:(NSString *)name version:(NSString *)version completion:(void(^)(BOOL, NSError *))completion {
    NSString *rpDir = [VersionDirectoryManager.shared resourcePacksPathForVersion:version];
    NSString *targetPath = [rpDir stringByAppendingPathComponent:name];
    if (![targetPath hasSuffix:@".zip"]) {
        targetPath = [targetPath stringByAppendingPathExtension:@"zip"];
    }
    [self downloadToPath:url targetPath:targetPath completion:completion];
}

- (void)downloadMap:(NSString *)url name:(NSString *)name version:(NSString *)version completion:(void(^)(BOOL, NSError *))completion {
    NSString *savesDir = [VersionDirectoryManager.shared savesPathForVersion:version];
    NSString *targetPath = [savesDir stringByAppendingPathComponent:name];
    if (![targetPath hasSuffix:@".zip"]) {
        targetPath = [targetPath stringByAppendingPathExtension:@"zip"];
    }
    [self downloadToPath:url targetPath:targetPath completion:completion];
}

- (void)downloadToPath:(NSString *)urlString targetPath:(NSString *)targetPath completion:(void(^)(BOOL, NSError *))completion {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        if (completion) completion(NO, [NSError errorWithDomain:@"DownloadManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}]);
        return;
    }

    NSString *dir = targetPath.stringByDeletingLastPathComponent;
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDownloadTask *task = [[AFHTTPSessionManager manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath_, NSURLResponse *response) {
        NSString *suggested = response.suggestedFilename ?: targetPath.lastPathComponent;
        NSString *finalPath = [targetPath.stringByDeletingLastPathComponent stringByAppendingPathComponent:suggested];
        return [NSURL fileURLWithPath:finalPath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (error) {
            if (completion) completion(NO, error);
        } else {
            if (completion) completion(YES, nil);
        }
    }];
    [task resume];
}

@end
