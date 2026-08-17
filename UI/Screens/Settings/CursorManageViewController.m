#import "CursorManageViewController.h"
#import "CursorHitboxEditorViewController.h"
#import "CursorManager.h"
#import "ThemeManager.h"
#import "HapticManager.h"
#import "ios_uikit_bridge.h"
#import "LauncherPreferences.h"
#import <PhotosUI/PhotosUI.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface CursorManageViewController () <UITableViewDelegate, UITableViewDataSource, PHPickerViewControllerDelegate, UIDocumentPickerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSString *> *cursorNames;
@property (nonatomic, strong) UIBarButtonItem *addButton;
@property (nonatomic, assign) BOOL isImporting;

// Biến lưu trạng thái đang chọn chỉnh sửa loại con trỏ nào ở Section 0
@property (nonatomic, assign) CursorManageType currentSelectedType;

@end

@implementation CursorManageViewController

#pragma mark - Lấy Tên và Ảnh Đang Gán

// Hiển thị tên các loại chuột
- (NSString *)nameForType:(CursorManageType)type {
    switch (type) {
        case CursorManageTypeNormal: return @"Default (Normal)";
        case CursorManageTypeHand: return @"Hand";
        case CursorManageTypeIBeam: return @"IBeam";
        case CursorManageTypeResizeEW: return @"Resize (EW)";
        case CursorManageTypeResizeNS: return @"Resize (NS)";
    }
}

// Lấy tên ảnh đang được gán cho từng loại
- (NSString *)assignedCursorForType:(CursorManageType)type {
    switch (type) {
        case CursorManageTypeHand: return CursorManager.handCursorName;
        case CursorManageTypeIBeam: return CursorManager.ibeamCursorName;
        case CursorManageTypeResizeEW: return CursorManager.resizeEWCursorName;
        case CursorManageTypeResizeNS: return CursorManager.resizeNSCursorName;
        case CursorManageTypeNormal:
        default: return CursorManager.normalCursorName;
    }
}

// Gán ảnh mới cho loại đang được chọn
- (void)setSelectedCursorName:(NSString *)name {
    switch (self.currentSelectedType) {
        case CursorManageTypeHand: [CursorManager setHandCursorName:name]; break;
        case CursorManageTypeIBeam: [CursorManager setIBeamCursorName:name]; break;
        case CursorManageTypeResizeEW: [CursorManager setResizeEWCursorName:name]; break;
        case CursorManageTypeResizeNS: [CursorManager setResizeNSCursorName:name]; break;
        case CursorManageTypeNormal:
        default: [CursorManager setNormalCursorName:name]; break;
    }
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Mặc định chọn loại Normal khi vừa vào
    _currentSelectedType = CursorManageTypeNormal;

    self.view.backgroundColor = ThemeManager.shared.contentBackgroundColor;
    self.navigationItem.title = @"Mouse Cursors";

    _addButton = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
        target:self
        action:@selector(showImportOptions)];

    self.navigationItem.rightBarButtonItem = _addButton;

    _tableView = [[UITableView alloc]
        initWithFrame:CGRectZero
        style:UITableViewStyleInsetGrouped];

    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = UIColor.clearColor;

    [self.view addSubview:_tableView];

    [NSLayoutConstraint activateConstraints:@[
        [_tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [self reloadCursors];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadCursors];
}

- (void)reloadCursors {
    @try {
        // Lấy TẤT CẢ các ảnh cursor đã import để hiển thị ở danh sách bên dưới
        _cursorNames = [CursorManager cursorNames];

        if (!_cursorNames) {
            _cursorNames = @[];
        }
    } @catch (NSException *exception) {
        _cursorNames = @[];
    }
    [_tableView reloadData];
}

#pragma mark - Import Logic

- (void)showImportOptions {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Add Cursor"
                                                                   message:@"Choose an image, GIF, or cursor file"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Photo Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self openPhotoPicker];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Files" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self openDocumentPicker];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        sheet.popoverPresentationController.barButtonItem = _addButton;
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)openPhotoPicker {
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.filter = [PHPickerFilter imagesFilter];
    config.selectionLimit = 1;
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)openDocumentPicker {
    NSArray *types = @[
        [UTType typeWithFilenameExtension:@"png"],
        [UTType typeWithFilenameExtension:@"jpg"],
        [UTType typeWithFilenameExtension:@"jpeg"],
        [UTType typeWithFilenameExtension:@"gif"],
        [UTType typeWithFilenameExtension:@"webp"],
        [UTType typeWithFilenameExtension:@"cur"],
        [UTType typeWithFilenameExtension:@"ani"],
        [UTType typeWithFilenameExtension:@"ico"],
        [UTType typeWithFilenameExtension:@"bmp"],
        [UTType typeWithFilenameExtension:@"tiff"],
    ];
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:types asCopy:YES];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (results.count == 0) return;

    PHPickerResult *result = results.firstObject;
    NSItemProvider *provider = result.itemProvider;
    NSString *name = provider.suggestedName ?: @"Cursor";

    if ([provider hasItemConformingToTypeIdentifier:UTTypeGIF.identifier]) {
        [provider loadFileRepresentationForTypeIdentifier:UTTypeGIF.identifier completionHandler:^(NSURL *url, NSError *error) {
            if (error || !url) return;
            [self finishImportAtURL:url name:name];
        }];
        return;
    }

    [provider loadObjectOfClass:UIImage.class completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
        if (error || !object) return;
        UIImage *image = (UIImage *)object;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishImportImage:image name:name];
        });
    }];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count == 0) return;
    NSURL *url = urls.firstObject;
    NSString *name = url.lastPathComponent.stringByDeletingPathExtension ?: @"Cursor";
    [self finishImportAtURL:url name:name];
}

- (void)finishImportAtURL:(NSURL *)url name:(NSString *)name {
    BOOL access = [url startAccessingSecurityScopedResource];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSString *cursor = [CursorManager importCursorFromURL:url
                                             withName:name
                                               error:&error];
        if (access) [url stopAccessingSecurityScopedResource];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isImporting = YES;
            [self handleImportResult:cursor error:error];
        });
    });
}

- (void)finishImportImage:(UIImage *)image name:(NSString *)name {
    NSError *error = nil;
    NSString *cursor = [CursorManager importCursorFromImage:image
                                               withName:name
                                                 error:&error];
    [self handleImportResult:cursor error:error];
}

- (void)handleImportResult:(NSString *)cursor error:(NSError *)error {
    self.isImporting = NO;
    if (!cursor) {
        showDialog(@"Import Failed", error ? error.localizedDescription : @"Unsupported image format");
        return;
    }
    [self reloadCursors];
    [self openHitboxEditorForCursor:cursor];
}

#pragma mark - Hitbox editor

- (void)openHitboxEditorForCursor:(NSString *)cursorName {
    CursorHitboxEditorViewController *editor = [[CursorHitboxEditorViewController alloc] init];
    editor.cursorName = cursorName;
    [self.navigationController pushViewController:editor animated:YES];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; // CHIA LÀM 2 PHẦN
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 5; // 5 loại cursor
    }
    return _cursorNames.count; // Danh sách ảnh đã import
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 50; // Chiều cao hàng của loại cursor
    }
    return 72; // Chiều cao hàng của danh sách ảnh
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Cursor Types";
    return @"Imported Cursors";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // ==========================================
    // PHẦN 1: CHỌN LOẠI CURSOR (Ở TRÊN)
    // ==========================================
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TypeCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"TypeCell"];
            cell.backgroundColor = ThemeManager.shared.cardBackgroundColor;
            cell.textLabel.textColor = ThemeManager.shared.primaryTextColor;
        }
        
        CursorManageType rowType = (CursorManageType)indexPath.row;
        
        // Tên loại (Ví dụ: Hand, IBeam...)
        cell.textLabel.text = [self nameForType:rowType];
        
        // Tên ảnh đang gán cho loại đó hiện ở bên phải
        NSString *assignedName = [self assignedCursorForType:rowType];
        cell.detailTextLabel.text = [CursorManager isDefaultCursor:assignedName] ? @"Default" : assignedName;
        
        // Đổi màu / Thêm checkmark nếu loại đó đang được chọn để chỉnh sửa
        if (self.currentSelectedType == rowType) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
            cell.detailTextLabel.textColor = ThemeManager.shared.accentColor;
            cell.tintColor = ThemeManager.shared.accentColor; // Màu checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.font = [UIFont systemFontOfSize:16];
            cell.detailTextLabel.textColor = ThemeManager.shared.secondaryTextColor;
        }
        
        return cell;
    }
    
    // ==========================================
    // PHẦN 2: CHỌN ẢNH ĐÃ IMPORT (Ở DƯỚI)
    // ==========================================
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CursorCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CursorCell"];
        cell.backgroundColor = ThemeManager.shared.cardBackgroundColor;
        cell.textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        cell.textLabel.textColor = ThemeManager.shared.primaryTextColor;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.detailTextLabel.textColor = ThemeManager.shared.secondaryTextColor;

        UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        icon.contentMode = UIViewContentModeScaleAspectFit;
        icon.tag = 100;
        icon.backgroundColor = UIColor.blackColor;
        icon.layer.cornerRadius = 6;
        icon.clipsToBounds = YES;
        cell.accessoryView = icon;
    }

    NSString *name = _cursorNames[indexPath.row];
    BOOL isDefault = [CursorManager isDefaultCursor:name];
    
    // Lấy tên ảnh đang gán cho LOẠI ĐANG CHỌN (Ví dụ: đang chọn Hand, xem nó là ảnh nào)
    NSString *currentAssignedForSelectedType = [self assignedCursorForType:self.currentSelectedType];
    BOOL isSelectedForCurrentType = [currentAssignedForSelectedType isEqualToString:name];

    cell.textLabel.text = isDefault ? @"Default (built-in)" : name;
    cell.textLabel.textColor = ThemeManager.shared.primaryTextColor;

    CGPoint hitbox = [CursorManager hitboxForCursor:name];
    
    // Báo hiệu xem ảnh này có đang làm đại diện cho loại được chọn không
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Hitbox: (%.0f, %.0f)%@",
                                 hitbox.x, hitbox.y,
                                 isSelectedForCurrentType ? [NSString stringWithFormat:@"  •  Selected for %@", [self nameForType:self.currentSelectedType]] : @""];
                                 
    cell.detailTextLabel.textColor = isSelectedForCurrentType ? ThemeManager.shared.accentColor : ThemeManager.shared.secondaryTextColor;

    UIImageView *icon = (UIImageView *)cell.accessoryView;
    icon.image = [CursorManager imageForCursor:name];
    icon.layer.borderWidth = isSelectedForCurrentType ? 2 : 0;
    icon.layer.borderColor = ThemeManager.shared.accentColor.CGColor;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [HapticManager.shared play:HapticTypeLight];

    if (indexPath.section == 0) {
        // Nếu người dùng click vào phần trên, đổi loại cursor đang được chọn để thiết lập
        self.currentSelectedType = (CursorManageType)indexPath.row;
        [tableView reloadData];
    } else {
        // Nếu người dùng click vào ảnh ở dưới, GÁN ảnh đó vào loại cursor đang được chọn
        NSString *name = _cursorNames[indexPath.row];
        [self setSelectedCursorName:name];
        [tableView reloadData];
    }
}

// Logic vuốt để xoá / sửa hitbox (chỉ cho phép ở Section chứa ảnh dưới cùng)
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Không cho vuốt xoá đối với các Hàng của Section 0
    if (indexPath.section == 0) return nil; 
    
    NSString *name = _cursorNames[indexPath.row];
    BOOL isDefault = [CursorManager isDefaultCursor:name];

    UIContextualAction *editHitbox = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                            title:@"Hitbox"
                                                                            handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        completionHandler(YES);
        [self openHitboxEditorForCursor:name];
    }];
    editHitbox.backgroundColor = ThemeManager.shared.accentColor;

    NSMutableArray *actions = [NSMutableArray arrayWithObject:editHitbox];

    if (!isDefault) {
        UIContextualAction *delete = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                             title:@"Delete"
                                                                             handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
            completionHandler(YES);
            [self confirmDeleteCursor:name];
        }];
        [actions addObject:delete];
    }

    return [UISwipeActionsConfiguration configurationWithActions:actions];
}

- (void)confirmDeleteCursor:(NSString *)name {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Cursor"
                                                                   message:[NSString stringWithFormat:@"Delete cursor \"%@\"?", name]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        BOOL ok = [CursorManager deleteCursor:name];
        if (!ok) {
            showDialog(@"Error", @"Failed to delete cursor.");
            return;
        }
        
        // Trả về default nếu ảnh bị xoá đang được gán cho loại hiện tại
        if ([[self assignedCursorForType:self.currentSelectedType] isEqualToString:name]) {
            [self setSelectedCursorName:[CursorManager defaultCursorName]];
        }
        
        [self reloadCursors];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
