#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString * const kCurseForgeAPIKeyPrefKey;

@interface CurseForgeService : NSObject

+ (instancetype)shared;

/// Set the CurseForge API key. Must be called before any API requests.
- (void)setAPIKey:(NSString *)apiKey;

/// Check if API key is configured
- (BOOL)isConfigured;

/// Search mods/modpacks/shaders on CurseForge
/// @param classId: 6 = Mods, 4471 = Modpacks, 6552 = Shaders, 12 = Resource Packs
- (void)searchProjectsWithClassId:(NSInteger)classId
                            query:(NSString *)query
                           offset:(NSInteger)offset
                            limit:(NSInteger)limit
                     loaderFilter:(NSString *)loaderFilter
                gameVersionFilter:(NSString *)gameVersionFilter
                       completion:(void(^)(NSArray<NSDictionary *> *results, NSError *error))completion;

/// Load project versions/files
- (void)loadProjectFiles:(NSString *)projectId
              completion:(void(^)(NSArray<NSDictionary *> *files, NSError *error))completion;

/// Load project details
- (void)loadProjectDetails:(NSString *)projectId
                completion:(void(^)(NSDictionary *project, NSError *error))completion;

@end
