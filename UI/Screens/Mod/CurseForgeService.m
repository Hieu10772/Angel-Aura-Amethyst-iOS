#import "CurseForgeService.h"
#import "LauncherPreferences.h"

static NSString * const kCurseForgeBaseURL = @"https://api.curseforge.com/v1";
static NSInteger const kMinecraftGameId = 432;

NSString * const kCurseForgeAPIKeyPrefKey = @"curseforge.api_key";

@interface CurseForgeService ()
@property (nonatomic, copy) NSString *apiKey;
@end

@implementation CurseForgeService

+ (instancetype)shared {
    static CurseForgeService *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Try loading saved API key
        NSString *savedKey = getPrefObject(kCurseForgeAPIKeyPrefKey);
        if (savedKey.length > 0) {
            _apiKey = savedKey;
        }
    }
    return self;
}

- (void)setAPIKey:(NSString *)apiKey {
    _apiKey = [apiKey copy];
    setPrefObject(kCurseForgeAPIKeyPrefKey, apiKey);
}

- (BOOL)isConfigured {
    return _apiKey.length > 0;
}

#pragma mark - Loader mapping

/// Map loader name to CurseForge modLoaderType enum
/// 1 = Forge, 4 = Fabric, 5 = Quilt, 6 = NeoForge
- (NSInteger)modLoaderTypeForName:(NSString *)name {
    if ([name.lowercaseString isEqualToString:@"forge"]) return 1;
    if ([name.lowercaseString isEqualToString:@"fabric"]) return 4;
    if ([name.lowercaseString isEqualToString:@"quilt"]) return 5;
    if ([name.lowercaseString isEqualToString:@"neoforge"]) return 6;
    return 0; // Any
}

#pragma mark - API Requests

- (NSMutableURLRequest *)requestForPath:(NSString *)path {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kCurseForgeBaseURL, path]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setValue:_apiKey forHTTPHeaderField:@"x-api-key"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    return req;
}

- (void)searchProjectsWithClassId:(NSInteger)classId
                            query:(NSString *)query
                           offset:(NSInteger)offset
                            limit:(NSInteger)limit
                     loaderFilter:(NSString *)loaderFilter
                gameVersionFilter:(NSString *)gameVersionFilter
                       completion:(void(^)(NSArray<NSDictionary *> *results, NSError *error))completion
{
    if (![self isConfigured]) {
        if (completion) completion(nil, [NSError errorWithDomain:@"CurseForge" code:401 userInfo:@{NSLocalizedDescriptionKey: @"CurseForge API key not configured. Go to Settings to add your key."}]);
        return;
    }

    NSURLComponents *components = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"%@/mods/search", kCurseForgeBaseURL]];
    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithArray:@[
        [NSURLQueryItem queryItemWithName:@"gameId" value:[@(kMinecraftGameId) stringValue]],
        [NSURLQueryItem queryItemWithName:@"classId" value:[@(classId) stringValue]],
        [NSURLQueryItem queryItemWithName:@"searchFilter" value:query ?: @""],
        [NSURLQueryItem queryItemWithName:@"index" value:[@(offset) stringValue]],
        [NSURLQueryItem queryItemWithName:@"pageSize" value:[@(limit) stringValue]],
        [NSURLQueryItem queryItemWithName:@"sortField" value:@"2"], // Popularity
        [NSURLQueryItem queryItemWithName:@"sortOrder" value:@"desc"],
    ]];

    if (loaderFilter.length > 0) {
        NSInteger loaderType = [self modLoaderTypeForName:loaderFilter];
        if (loaderType > 0) {
            [queryItems addObject:[NSURLQueryItem queryItemWithName:@"modLoaderType" value:[@(loaderType) stringValue]]];
        }
    }
    if (gameVersionFilter.length > 0) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"gameVersion" value:gameVersionFilter]];
    }

    components.queryItems = queryItems;

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:components.URL];
    [req setValue:_apiKey forHTTPHeaderField:@"x-api-key"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    [[NSURLSession.sharedSession dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data) {
                if (completion) completion(nil, error ?: [NSError errorWithDomain:@"CurseForge" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"No data received"}]);
                return;
            }
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray *rawData = json[@"data"];
            if (![rawData isKindOfClass:[NSArray class]]) {
                if (completion) completion(@[], nil);
                return;
            }
            // Map CurseForge response to a format compatible with our UI
            NSMutableArray *results = [NSMutableArray array];
            for (NSDictionary *mod in rawData) {
                NSString *iconUrl = @"";
                if ([mod[@"logo"] isKindOfClass:[NSDictionary class]]) {
                    iconUrl = mod[@"logo"][@"thumbnailUrl"] ?: @"";
                }
                NSString *author = @"";
                NSArray *authors = mod[@"authors"];
                if ([authors isKindOfClass:[NSArray class]] && authors.count > 0) {
                    author = authors[0][@"name"] ?: @"";
                }
                // Map loaders
                NSMutableArray *loaders = [NSMutableArray array];
                NSArray *latestFilesIndexes = mod[@"latestFilesIndexes"];
                if ([latestFilesIndexes isKindOfClass:[NSArray class]]) {
                    NSMutableSet *loaderSet = [NSMutableSet set];
                    for (NSDictionary *fi in latestFilesIndexes) {
                        NSNumber *modLoader = fi[@"modLoader"];
                        if ([modLoader isKindOfClass:[NSNumber class]]) {
                            switch (modLoader.intValue) {
                                case 1: [loaderSet addObject:@"forge"]; break;
                                case 4: [loaderSet addObject:@"fabric"]; break;
                                case 5: [loaderSet addObject:@"quilt"]; break;
                                case 6: [loaderSet addObject:@"neoforge"]; break;
                            }
                        }
                    }
                    [loaders addObjectsFromArray:loaderSet.allObjects];
                }

                [results addObject:@{
                    @"slug": mod[@"slug"] ?: @"",
                    @"title": mod[@"name"] ?: @"Unknown",
                    @"description": mod[@"summary"] ?: @"",
                    @"project_type": classId == 6 ? @"mod" : classId == 4471 ? @"modpack" : classId == 6552 ? @"shader" : @"unknown",
                    @"icon_url": iconUrl,
                    @"downloads": mod[@"downloadCount"] ?: @0,
                    @"follows": mod[@"thumbsUpCount"] ?: @0,
                    @"author": author,
                    @"loaders": loaders,
                    @"project_id": [mod[@"id"] stringValue] ?: @"",
                    @"_source": @"curseforge",
                }];
            }
            if (completion) completion(results, nil);
        });
    }] resume];
}

- (void)loadProjectFiles:(NSString *)projectId
              completion:(void(^)(NSArray<NSDictionary *> *files, NSError *error))completion
{
    if (![self isConfigured]) {
        if (completion) completion(nil, [NSError errorWithDomain:@"CurseForge" code:401 userInfo:@{NSLocalizedDescriptionKey: @"API key not configured"}]);
        return;
    }
    NSString *path = [NSString stringWithFormat:@"/mods/%@/files", projectId];
    NSMutableURLRequest *req = [self requestForPath:path];
    [[NSURLSession.sharedSession dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data) {
                if (completion) completion(nil, error);
                return;
            }
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray *files = json[@"data"];
            if (completion) completion([files isKindOfClass:[NSArray class]] ? files : @[], nil);
        });
    }] resume];
}

- (void)loadProjectDetails:(NSString *)projectId
                completion:(void(^)(NSDictionary *project, NSError *error))completion
{
    if (![self isConfigured]) {
        if (completion) completion(nil, [NSError errorWithDomain:@"CurseForge" code:401 userInfo:@{NSLocalizedDescriptionKey: @"API key not configured"}]);
        return;
    }
    NSString *path = [NSString stringWithFormat:@"/mods/%@", projectId];
    NSMutableURLRequest *req = [self requestForPath:path];
    [[NSURLSession.sharedSession dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data) {
                if (completion) completion(nil, error);
                return;
            }
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (completion) completion(json[@"data"], nil);
        });
    }] resume];
}

@end
