#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ModrinthService : NSObject

+ (instancetype)shared;

- (void)searchProjectsWithType:(NSString *)projectType
                         query:(NSString *)query
                        offset:(NSInteger)offset
                         limit:(NSInteger)limit
                  categoryFilter:(NSString *)categoryFilter
                   loaderFilter:(NSString *)loaderFilter
              gameVersionFilter:(NSString *)gameVersionFilter
                    completion:(void(^)(NSArray<NSDictionary *> *results, NSError *error))completion;

- (void)loadProjectVersions:(NSString *)projectId
                 completion:(void(^)(NSArray<NSDictionary *> *versions, NSError *error))completion;

- (void)loadProjectDetails:(NSString *)projectId
                completion:(void(^)(NSDictionary *project, NSError *error))completion;

- (NSURLSessionDownloadTask *)downloadFile:(NSString *)url
                                     name:(NSString *)name
                            progressBlock:(void(^)(float progress))progress
                                completion:(void(^)(NSString *path, NSError *error))completion;

@end
