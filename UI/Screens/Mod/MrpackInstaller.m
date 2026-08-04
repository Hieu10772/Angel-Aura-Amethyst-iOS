#import "MrpackInstaller.h"
#import "DownloadProgressOverlay.h"
#import "DownloadManager.h"
#import "VersionDirectoryManager.h"
#import "JavaGUIViewController.h"
#import "ModpackUtils.h"
#import "PLProfiles.h"
#import "ios_uikit_bridge.h"
#import "utils.h"
#import "UnzipKit.h"

static NSString *readInstallerVersionId(NSString *jarPath) {
    NSError *uzError;
    UZKArchive *archive = [[UZKArchive alloc] initWithPath:jarPath error:&uzError];
    if (uzError) return nil;
    NSData *profileData = [archive extractDataFromFile:@"install_profile.json" error:&uzError];
    if (uzError || !profileData) return nil;
    NSDictionary *profileJson = [NSJSONSerialization JSONObjectWithData:profileData options:0 error:nil];
    if (![profileJson isKindOfClass:[NSDictionary class]]) return nil;

    NSData *verData = nil;
    NSDictionary *versionInfo = profileJson[@"versionInfo"];
    if ([versionInfo isKindOfClass:[NSDictionary class]]) {
        verData = [NSJSONSerialization dataWithJSONObject:versionInfo options:0 error:nil];
    } else if ([profileJson[@"json"] isKindOfClass:[NSString class]]) {
        NSString *jsonStr = profileJson[@"json"];
        if ([jsonStr hasPrefix:@"/"]) {
            verData = [archive extractDataFromFile:[jsonStr substringFromIndex:1] error:&uzError];
        } else {
            verData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        }
    } else if ([profileJson[@"json"] isKindOfClass:[NSDictionary class]]) {
        verData = [NSJSONSerialization dataWithJSONObject:profileJson[@"json"] options:0 error:nil];
    } else if ([profileJson[@"install"] isKindOfClass:[NSDictionary class]] &&
               [profileJson[@"install"][@"versionInfo"] isKindOfClass:[NSDictionary class]]) {
        verData = [NSJSONSerialization dataWithJSONObject:profileJson[@"install"][@"versionInfo"] options:0 error:nil];
    }
    NSDictionary *parsed = verData ? [NSJSONSerialization JSONObjectWithData:verData options:0 error:nil] : nil;
    if ([parsed isKindOfClass:[NSDictionary class]]) {
        id vId = parsed[@"id"];
        if ([vId isKindOfClass:[NSString class]] && [vId length] > 0) return vId;
    }
    return nil;
}

@implementation MrpackInstaller

+ (void)installMrpackAtPath:(NSString *)dlPath title:(NSString *)title hostVC:(UIViewController *)hostVC removeOnCompletion:(BOOL)removeOnCompletion {
    DownloadProgressOverlay *overlay = [DownloadProgressOverlay showInView:hostVC.view title:@"Installing Modpack"];
    [overlay updateProgress:0.1 message:@"Parsing modpack..."];

    NSError *uzError;
    UZKArchive *archive = [[UZKArchive alloc] initWithPath:dlPath error:&uzError];
    if (uzError) {
        if (removeOnCompletion) [[NSFileManager defaultManager] removeItemAtPath:dlPath error:nil];
        [overlay finishWithMessage:@"Invalid modpack"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [overlay dismiss]; });
        return;
    }

    NSData *indexData = [archive extractDataFromFile:@"modrinth.index.json" error:&uzError];
    if (uzError || !indexData) {
        if (removeOnCompletion) [[NSFileManager defaultManager] removeItemAtPath:dlPath error:nil];
        [overlay finishWithMessage:@"Missing index"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [overlay dismiss]; });
        return;
    }

    NSDictionary *indexDict = [NSJSONSerialization JSONObjectWithData:indexData options:0 error:&uzError];
    if (uzError || ![indexDict isKindOfClass:[NSDictionary class]]) {
        if (removeOnCompletion) [[NSFileManager defaultManager] removeItemAtPath:dlPath error:nil];
        [overlay finishWithMessage:@"Corrupt index"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [overlay dismiss]; });
        return;
    }

    NSString *rawName = indexDict[@"name"] ?: [dlPath.lastPathComponent stringByDeletingPathExtension];
    NSString *displayTitle = title ?: rawName;
    NSString *cleanName = [[displayTitle lowercaseString] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    cleanName = [cleanName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString *versionName = cleanName;

    NSString *versionDir = [VersionDirectoryManager.shared versionPathForVersion:versionName];
    [[NSFileManager defaultManager] createDirectoryAtPath:versionDir withIntermediateDirectories:YES attributes:nil error:nil];
    [VersionDirectoryManager.shared ensureVersionDirectoriesForVersion:versionName];

    NSArray *indexFiles = indexDict[@"files"];
    NSUInteger totalFiles = [indexFiles isKindOfClass:[NSArray class]] ? indexFiles.count : 0;
    [overlay updateProgress:0.4 message:[NSString stringWithFormat:@"Downloading %lu files...", (unsigned long)totalFiles]];
    __block NSUInteger completedFiles = 0;
    __block BOOL installFailed = NO;
    dispatch_group_t modGroup = dispatch_group_create();

    for (NSDictionary *indexFile in indexFiles) {
        dispatch_group_enter(modGroup);
        NSString *modUrl = [indexFile[@"downloads"] firstObject];
        NSString *modPath = indexFile[@"path"] ?: @"";
        NSString *targetPath = [versionDir stringByAppendingPathComponent:modPath];
        if (modUrl.length > 0) {
            [DownloadManager.shared downloadToPath:modUrl targetPath:targetPath completion:^(BOOL success, NSError *e) {
                if (!success) installFailed = YES;
                completedFiles++;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [overlay updateProgress:0.4 + (0.3 * completedFiles / totalFiles) message:[NSString stringWithFormat:@"Downloading files... (%lu/%lu)", (unsigned long)completedFiles, (unsigned long)totalFiles]];
                });
                dispatch_group_leave(modGroup);
            }];
        } else {
            completedFiles++;
            dispatch_group_leave(modGroup);
        }
    }

    dispatch_group_notify(modGroup, dispatch_get_main_queue(), ^{
        if (installFailed) {
            if (removeOnCompletion) [[NSFileManager defaultManager] removeItemAtPath:dlPath error:nil];
            [overlay finishWithMessage:@"Some files failed"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [overlay dismiss]; });
            return;
        }

        [overlay updateProgress:0.7 message:@"Extracting overrides..."];
        [ModpackUtils archive:archive extractDirectory:@"overrides" toPath:versionDir error:nil];
        [ModpackUtils archive:archive extractDirectory:@"client-overrides" toPath:versionDir error:nil];
        if (removeOnCompletion) [[NSFileManager defaultManager] removeItemAtPath:dlPath error:nil];

        [overlay updateProgress:0.8 message:@"Setting up version..."];
        NSDictionary *deps = indexDict[@"dependencies"];
        NSString *currentMC = VersionDirectoryManager.shared.currentVersion.length > 0
            ? VersionDirectoryManager.shared.currentVersion : @"1.21.4";
        NSString *packMcVersion = [deps[@"minecraft"] isKindOfClass:[NSString class]] && [deps[@"minecraft"] length] > 0
            ? deps[@"minecraft"] : currentMC;

        __block NSString *loaderInheritsFrom = nil;
        void (^finalizeInstall)(BOOL) = ^(BOOL showAlert) {
            NSString *versionJsonPath = [versionDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", versionName]];
            NSMutableDictionary *modpackJson = [NSMutableDictionary dictionary];
            modpackJson[@"id"] = versionName;
            modpackJson[@"type"] = @"release";
            modpackJson[@"libraries"] = @[];
            modpackJson[@"minecraftVersion"] = packMcVersion;
            if (deps[@"fabric-loader"] || deps[@"quilt-loader"]) {
                NSString *loaderType = deps[@"fabric-loader"] ? @"fabric" : @"quilt";
                NSString *loaderVer = deps[@"fabric-loader"] ?: deps[@"quilt-loader"];
                NSString *profileId = [NSString stringWithFormat:@"%@-loader-%@-%@", loaderType, loaderVer, packMcVersion];
                modpackJson[@"inheritsFrom"] = profileId;
            } else if (deps[@"forge"]) {
                modpackJson[@"inheritsFrom"] = loaderInheritsFrom ?: packMcVersion;
            } else if (deps[@"neoforge"]) {
                modpackJson[@"inheritsFrom"] = loaderInheritsFrom ?: packMcVersion;
            }
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:modpackJson options:NSJSONWritingPrettyPrinted error:nil];
            if (jsonData) [jsonData writeToFile:versionJsonPath atomically:YES];

            [MrpackInstaller downloadClientJarForModpack:versionName];

            NSString *profileName = displayTitle;
            NSMutableDictionary *existing = PLProfiles.current.profiles[profileName];
            if (existing) {
                existing = [existing mutableCopy];
                existing[@"lastVersionId"] = versionName;
                existing[@"gameDir"] = [NSString stringWithFormat:@"./versions/%@", versionName];
                PLProfiles.current.profiles[profileName] = existing;
            } else {
                PLProfiles.current.profiles[profileName] = @{
                    @"name": profileName,
                    @"lastVersionId": versionName,
                    @"gameDir": [NSString stringWithFormat:@"./versions/%@", versionName]
                }.mutableCopy;
            }
            PLProfiles.current.selectedProfileName = profileName;
            [PLProfiles.current save];
            VersionDirectoryManager.shared.currentVersion = versionName;

            if (showAlert) {
                [overlay finishWithMessage:@"Installed!"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [overlay dismiss];
                    showDialog(@"Modpack Installed", [NSString stringWithFormat:@"%@ installed as profile.", profileName]);
                });
            }
        };

        NSString *loaderType = nil, *loaderVer = nil;
        if (deps[@"fabric-loader"]) {
            loaderType = @"fabric"; loaderVer = deps[@"fabric-loader"];
        } else if (deps[@"quilt-loader"]) {
            loaderType = @"quilt"; loaderVer = deps[@"quilt-loader"];
        }

        if (loaderType && loaderVer) {
            NSString *profileId = [NSString stringWithFormat:@"%@-loader-%@-%@", loaderType, loaderVer, packMcVersion];
            NSString *loaderDir = [VersionDirectoryManager.shared versionPathForVersion:profileId];
            NSString *loaderJsonPath = [loaderDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", profileId]];

            if (![[NSFileManager defaultManager] fileExistsAtPath:loaderJsonPath]) {
                NSString *profileUrl;
                if ([loaderType isEqualToString:@"fabric"]) {
                    profileUrl = [NSString stringWithFormat:@"https://meta.fabricmc.net/v2/versions/loader/%@/%@/profile/json", packMcVersion, loaderVer];
                } else {
                    profileUrl = [NSString stringWithFormat:@"https://meta.quiltmc.org/v3/versions/loader/%@/%@/profile/json", packMcVersion, loaderVer];
                }
                [overlay updateProgress:0.82 message:@"Downloading loader profile..."];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSData *profileData = [NSData dataWithContentsOfURL:[NSURL URLWithString:profileUrl]];
                    if (profileData) {
                        [[NSFileManager defaultManager] createDirectoryAtPath:loaderDir withIntermediateDirectories:YES attributes:nil error:nil];
                        [profileData writeToFile:loaderJsonPath atomically:YES];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{ finalizeInstall(YES); });
                });
                return;
            }
        } else if (deps[@"forge"] || deps[@"neoforge"]) {
            BOOL isNeo = (deps[@"neoforge"] != nil);
            NSString *loaderVer2 = isNeo ? deps[@"neoforge"] : deps[@"forge"];
            NSString *profileId = isNeo
                ? [NSString stringWithFormat:@"neoforge-%@", loaderVer2]
                : [NSString stringWithFormat:@"%@-forge-%@", packMcVersion, loaderVer2];
            NSString *loaderJsonPath = [[VersionDirectoryManager.shared versionPathForVersion:profileId]
                stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", profileId]];

            if ([[NSFileManager defaultManager] fileExistsAtPath:loaderJsonPath]) {
                loaderInheritsFrom = profileId;
                finalizeInstall(YES);
                return;
            }

            NSString *installerUrl = isNeo
                ? [NSString stringWithFormat:@"https://maven.neoforged.net/releases/net/neoforged/neoforge/%@/neoforge-%@-installer.jar", loaderVer2, loaderVer2]
                : [NSString stringWithFormat:@"https://maven.minecraftforge.net/net/minecraftforge/forge/%@-%@/forge-%@-%@-installer.jar", packMcVersion, loaderVer2, packMcVersion, loaderVer2];
            [overlay updateProgress:0.82 message:[NSString stringWithFormat:@"Downloading %@ installer...", isNeo ? @"NeoForge" : @"Forge"]];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *jarData = [NSData dataWithContentsOfURL:[NSURL URLWithString:installerUrl]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *installerPath = nil;
                    if (jarData && jarData.length > 4) {
                        NSString *installersDir = [NSString stringWithFormat:@"%s/installers", getenv("POJAV_HOME") ?: ""];
                        if ([installersDir length] > [@"/installers" length]) {
                            [[NSFileManager defaultManager] createDirectoryAtPath:installersDir withIntermediateDirectories:YES attributes:nil error:nil];
                            installerPath = [installersDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@-installer.jar", isNeo ? @"neoforge" : @"forge", loaderVer2]];
                            [[NSFileManager defaultManager] removeItemAtPath:installerPath error:nil];
                            [jarData writeToFile:installerPath atomically:YES];
                        }
                    }
                    NSString *realId = installerPath ? readInstallerVersionId(installerPath) : nil;
                    if (realId.length > 0) {
                        loaderInheritsFrom = realId;
                        NSString *realJsonPath = [[VersionDirectoryManager.shared versionPathForVersion:realId]
                            stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", realId]];
                        if ([[NSFileManager defaultManager] fileExistsAtPath:realJsonPath]) {
                            finalizeInstall(YES);
                            return;
                        }
                    } else {
                        loaderInheritsFrom = profileId;
                    }

                    finalizeInstall(NO);
                    if (!installerPath) {
                        [overlay updateProgress:0.9 message:@"Installer download failed"];
                        showDialog(@"Installer Failed", [NSString stringWithFormat:@"Could not download the %@ installer. The modpack profile was still created.", isNeo ? @"NeoForge" : @"Forge"]);
                        return;
                    }
                    [overlay updateProgress:0.9 message:[NSString stringWithFormat:@"Running %@ installer...", isNeo ? @"NeoForge" : @"Forge"]];
                    NSString *installDir = [NSString stringWithFormat:@"%s/instances/%@",
                        getenv("POJAV_HOME") ?: "", VersionDirectoryManager.shared.currentInstance ?: @"default"];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [overlay dismiss];
                        JavaGUIViewController *vc = [[JavaGUIViewController alloc] init];
                        vc.filepath = installerPath;
                        vc.jvmArgs = @[@"--installClient", installDir];
                        vc.modalPresentationStyle = UIModalPresentationFullScreen;
                        [hostVC presentViewController:vc animated:YES completion:nil];
                    });
                });
            });
            return;
        }

        finalizeInstall(YES);
    });
}

+ (void)downloadClientJarForModpack:(NSString *)versionName {
    NSString *versionDir = [VersionDirectoryManager.shared versionPathForVersion:versionName];
    NSString *jarPath = [versionDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jar", versionName]];
    if ([NSFileManager.defaultManager fileExistsAtPath:jarPath]) return;

    NSString *jsonPath = [versionDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", versionName]];
    NSMutableDictionary *json = parseJSONFromFile(jsonPath);
    if (json[@"NSErrorObject"]) return;

    NSString *mcVersion = json[@"minecraftVersion"];
    if (!mcVersion) return;

    NSURL *manifestURL = [NSURL URLWithString:@"https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"];
    NSData *manifestData = [NSData dataWithContentsOfURL:manifestURL];
    if (!manifestData) return;

    NSDictionary *manifest = [NSJSONSerialization JSONObjectWithData:manifestData options:0 error:nil];
    if (![manifest[@"versions"] isKindOfClass:[NSArray class]]) return;

    NSString *versionJsonUrl = nil;
    for (NSDictionary *v in manifest[@"versions"]) {
        if ([v[@"id"] isEqualToString:mcVersion]) {
            versionJsonUrl = v[@"url"];
            break;
        }
    }
    if (!versionJsonUrl) return;

    NSData *versionData = [NSData dataWithContentsOfURL:[NSURL URLWithString:versionJsonUrl]];
    if (!versionData) return;

    NSDictionary *versionJson = [NSJSONSerialization JSONObjectWithData:versionData options:0 error:nil];
    NSString *jarUrl = versionJson[@"downloads"][@"client"][@"url"];
    if (!jarUrl) return;

    NSLog(@"[Mrpack] Downloading client jar for %@ from %@", versionName, jarUrl);
    NSData *jarData = [NSData dataWithContentsOfURL:[NSURL URLWithString:jarUrl]];
    if (jarData) {
        [jarData writeToFile:jarPath atomically:YES];
        NSLog(@"[Mrpack] Saved client jar to %@", jarPath);
    }
}

@end
