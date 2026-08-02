#import "AccountViewController.h"
#import "ThemeManager.h"
#import "CustomButton.h"
#import "authenticator/BaseAuthenticator.h"
#import "LauncherPreferences.h"
#import "ios_uikit_bridge.h"
#import "utils.h"
#import "HapticManager.h"
#import "DownloadProgressOverlay.h"
#import <WebKit/WebKit.h>
#import "UIImageView+AFNetworking.h"

@interface AccountViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic) NSDictionary *editingAccount;
@end

@interface MicrosoftAuthenticator (Keychain)
+ (NSDictionary *)tokenDataOfProfile:(NSString *)profile;
@end

@interface AccountCell : UITableViewCell
@property (nonatomic) UIImageView *avatarView;
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UILabel *typeLabel;
@property (nonatomic) UIButton *editBtn;
@property (nonatomic) UIButton *deleteBtn;
@end

@implementation AccountCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = ThemeManager.shared.cardBackgroundColor;
        self.layer.cornerRadius = 10;
        self.clipsToBounds = YES;

        _avatarView = [[UIImageView alloc] init];
        _avatarView.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarView.contentMode = UIViewContentModeScaleAspectFill;
        _avatarView.clipsToBounds = YES;
        _avatarView.layer.cornerRadius = 20;
        _avatarView.tintColor = ThemeManager.shared.secondaryTextColor;
        [self.contentView addSubview:_avatarView];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        _nameLabel.textColor = ThemeManager.shared.primaryTextColor;
        [self.contentView addSubview:_nameLabel];

        _typeLabel = [[UILabel alloc] init];
        _typeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _typeLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        _typeLabel.textColor = UIColor.whiteColor;
        _typeLabel.textAlignment = NSTextAlignmentCenter;
        _typeLabel.layer.cornerRadius = 4;
        _typeLabel.clipsToBounds = YES;
        [self.contentView addSubview:_typeLabel];

        _editBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _editBtn.translatesAutoresizingMaskIntoConstraints = NO;
        [_editBtn setTitle:@"Edit" forState:UIControlStateNormal];
        _editBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [_editBtn setTitleColor:ThemeManager.shared.accentColor forState:UIControlStateNormal];
        _editBtn.hidden = YES;
        [self.contentView addSubview:_editBtn];

        _deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _deleteBtn.translatesAutoresizingMaskIntoConstraints = NO;
        [_deleteBtn setTitle:@"Delete" forState:UIControlStateNormal];
        _deleteBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [_deleteBtn setTitleColor:ThemeManager.shared.errorColor forState:UIControlStateNormal];
        [self.contentView addSubview:_deleteBtn];

        [NSLayoutConstraint activateConstraints:@[
            [_avatarView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
            [_avatarView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_avatarView.widthAnchor constraintEqualToConstant:40],
            [_avatarView.heightAnchor constraintEqualToConstant:40],

            [_nameLabel.leadingAnchor constraintEqualToAnchor:_avatarView.trailingAnchor constant:12],
            [_nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],

            [_typeLabel.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
            [_typeLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor constant:4],
            [_typeLabel.heightAnchor constraintEqualToConstant:18],
            [_typeLabel.widthAnchor constraintGreaterThanOrEqualToConstant:60],

            [_deleteBtn.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],
            [_deleteBtn.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_deleteBtn.widthAnchor constraintEqualToConstant:50],

            [_editBtn.trailingAnchor constraintEqualToAnchor:_deleteBtn.leadingAnchor constant:-4],
            [_editBtn.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_editBtn.widthAnchor constraintEqualToConstant:40],
        ]];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTheme) name:ThemeDidChangeNotification object:nil];
    }
    return self;
}

- (void)updateTheme {
    self.backgroundColor = ThemeManager.shared.cardBackgroundColor;
    _nameLabel.textColor = ThemeManager.shared.primaryTextColor;
    _avatarView.tintColor = ThemeManager.shared.secondaryTextColor;
}

- (void)configureWithAccount:(NSDictionary *)account isSelected:(BOOL)isSelected {
    _nameLabel.text = account[@"username"] ?: @"Unknown";
    BOOL isPremium = [account[@"xboxGamertag"] length] > 0;
    BOOL isDemo = isPremium && [account[@"profileId"] isEqualToString:@"00000000-0000-0000-0000-000000000000"];

    if (isDemo) {
        _typeLabel.text = @"Demo";
        _typeLabel.backgroundColor = [UIColor colorWithRed:0.95 green:0.60 blue:0.20 alpha:1];
    } else if (isPremium) {
        _typeLabel.text = @"Premium";
        _typeLabel.backgroundColor = [UIColor colorWithRed:0.20 green:0.60 blue:0.86 alpha:1];
    } else {
        _typeLabel.text = @"Local";
        _typeLabel.backgroundColor = ThemeManager.shared.secondaryTextColor;
    }

    _editBtn.hidden = !isPremium || isDemo;

    UIImage *placeholder = [UIImage systemImageNamed:isDemo ? @"exclamationmark.triangle.fill" : (isPremium ? @"person.fill.checkmark" : @"person.circle.fill")];
    _avatarView.image = placeholder;
    _avatarView.tintColor = ThemeManager.shared.secondaryTextColor;

    NSString *profileId = account[@"profileId"];
    if (isPremium && profileId.length > 0 && !isDemo) {
        NSString *skinURL = [NSString stringWithFormat:@"https://mc-heads.net/head/%@/40", profileId];
        __weak typeof(self) weakSelf = self;
        [_avatarView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:skinURL]]
                          placeholderImage:placeholder
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       weakSelf.avatarView.image = image;
                                       weakSelf.avatarView.tintColor = [UIColor clearColor];
                                   } failure:nil];
    }

    if (isSelected) {
        self.layer.borderWidth = 2;
        self.layer.borderColor = ThemeManager.shared.accentColor.CGColor;
    } else {
        self.layer.borderWidth = 0;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _avatarView.image = nil;
    _avatarView.tintColor = ThemeManager.shared.secondaryTextColor;
    _nameLabel.text = nil;
    _typeLabel.text = nil;
    self.layer.borderWidth = 0;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

@interface AccountViewController () <UITableViewDelegate, UITableViewDataSource, WKNavigationDelegate>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSMutableArray *accountsArray;
@property (nonatomic) UISegmentedControl *addTypeControl;
@property (nonatomic) UITextField *usernameField;
@property (nonatomic) UIButton *addActionBtn;
@property (nonatomic) UIView *addFormView;
@property (nonatomic) NSLayoutConstraint *formBottomConstraint;
@property (nonatomic) WKWebView *loginWebView;
@end

@implementation AccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColors) name:ThemeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self updateColors];
    [self loadAccounts];
}

- (void)setup {
    self.view.clipsToBounds = YES;

    // Tap to dismiss keyboard
    UITapGestureRecognizer *tapDismiss = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tapDismiss.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapDismiss];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"  Accounts";
    titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    titleLabel.textColor = ThemeManager.shared.primaryTextColor;
    [self.view addSubview:titleLabel];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = 64;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 200, 0);
    [_tableView registerClass:[AccountCell class] forCellReuseIdentifier:@"AccountCell"];
    [self.view addSubview:_tableView];

    _addFormView = [[UIView alloc] init];
    _addFormView.translatesAutoresizingMaskIntoConstraints = NO;
    _addFormView.backgroundColor = ThemeManager.shared.cardBackgroundColor;
    _addFormView.layer.cornerRadius = 12;
    _addFormView.layer.borderWidth = 1;
    _addFormView.layer.borderColor = ThemeManager.shared.separatorColor.CGColor;
    [self.view addSubview:_addFormView];

    UILabel *addTitle = [[UILabel alloc] init];
    addTitle.translatesAutoresizingMaskIntoConstraints = NO;
    addTitle.text = @"Add Account";
    addTitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    addTitle.textColor = ThemeManager.shared.primaryTextColor;
    [_addFormView addSubview:addTitle];

    _addTypeControl = [[UISegmentedControl alloc] initWithItems:@[@"Premium (Microsoft)", @"Local (Offline)"]];
    _addTypeControl.translatesAutoresizingMaskIntoConstraints = NO;
    _addTypeControl.selectedSegmentIndex = 1;
    [_addTypeControl addTarget:self action:@selector(addTypeChanged) forControlEvents:UIControlEventValueChanged];
    [_addFormView addSubview:_addTypeControl];

    _usernameField = [[UITextField alloc] init];
    _usernameField.translatesAutoresizingMaskIntoConstraints = NO;
    _usernameField.placeholder = @"Username";
    _usernameField.text = @"Player";
    _usernameField.borderStyle = UITextBorderStyleRoundedRect;
    _usernameField.font = [UIFont systemFontOfSize:14];
    _usernameField.hidden = YES;
    _usernameField.returnKeyType = UIReturnKeyDone;
    [_usernameField addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventEditingDidEndOnExit];

    UIToolbar *kbToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissKeyboard)];
    kbToolbar.items = @[flexSpace, doneBtn];
    _usernameField.inputAccessoryView = kbToolbar;

    [_addFormView addSubview:_usernameField];

    _addActionBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _addActionBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_addActionBtn setTitle:@"Login with Microsoft  →" forState:UIControlStateNormal];
    [_addActionBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _addActionBtn.backgroundColor = ThemeManager.shared.accentColor;
    _addActionBtn.layer.cornerRadius = 8;
    _addActionBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [_addActionBtn addTarget:self action:@selector(addAccountTapped) forControlEvents:UIControlEventTouchUpInside];
    _addActionBtn.hidden = YES;
    [_addFormView addSubview:_addActionBtn];

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:16],
        [titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],

        [_tableView.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:12],
        [_tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [_addFormView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_addFormView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        self.formBottomConstraint = [_addFormView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:0],

        [addTitle.topAnchor constraintEqualToAnchor:_addFormView.topAnchor constant:12],
        [addTitle.centerXAnchor constraintEqualToAnchor:_addFormView.centerXAnchor],

        [_addTypeControl.topAnchor constraintEqualToAnchor:addTitle.bottomAnchor constant:10],
        [_addTypeControl.leadingAnchor constraintEqualToAnchor:_addFormView.leadingAnchor constant:12],
        [_addTypeControl.trailingAnchor constraintEqualToAnchor:_addFormView.trailingAnchor constant:-12],

        [_usernameField.topAnchor constraintEqualToAnchor:_addTypeControl.bottomAnchor constant:10],
        [_usernameField.leadingAnchor constraintEqualToAnchor:_addFormView.leadingAnchor constant:12],
        [_usernameField.trailingAnchor constraintEqualToAnchor:_addFormView.trailingAnchor constant:-12],
        [_usernameField.heightAnchor constraintEqualToConstant:36],

        [_addActionBtn.topAnchor constraintEqualToAnchor:_usernameField.bottomAnchor constant:10],
        [_addActionBtn.leadingAnchor constraintEqualToAnchor:_addFormView.leadingAnchor constant:12],
        [_addActionBtn.trailingAnchor constraintEqualToAnchor:_addFormView.trailingAnchor constant:-12],
        [_addActionBtn.heightAnchor constraintEqualToConstant:40],
        [_addActionBtn.bottomAnchor constraintEqualToAnchor:_addFormView.bottomAnchor constant:-12],
    ]];

    [self addTypeChanged];
}

- (void)addTypeChanged {
    BOOL isLocal = _addTypeControl.selectedSegmentIndex == 1;
    _usernameField.hidden = !isLocal;
    _addActionBtn.hidden = NO;
    if (isLocal) {
        [_addActionBtn setTitle:@"Add Local Account" forState:UIControlStateNormal];
        _usernameField.placeholder = @"Username";
    } else {
        [_addActionBtn setTitle:@"Login with Microsoft  →" forState:UIControlStateNormal];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        CGFloat bottomInset = self.view.safeAreaInsets.bottom;
        self.formBottomConstraint.constant = -12 - bottomInset;
    });
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect kbFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect converted = [self.view convertRect:kbFrame fromView:self.view.window];
    CGFloat overlap = self.view.frame.size.height - converted.origin.y;
    if (overlap <= 0) return;

    self.formBottomConstraint.constant = -12 - overlap;

    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0 options:curve << 16 animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    CGFloat bottomInset = self.view.safeAreaInsets.bottom;
    self.formBottomConstraint.constant = -12 - bottomInset;

    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0 options:curve << 16 animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)updateColors {
    ThemeManager *theme = ThemeManager.shared;
    self.view.backgroundColor = theme.contentBackgroundColor;
    _tableView.backgroundColor = theme.contentBackgroundColor;
    _addFormView.backgroundColor = theme.cardBackgroundColor;
    _addFormView.layer.borderColor = theme.separatorColor.CGColor;
}

- (void)loadAccounts {
    _accountsArray = [NSMutableArray array];
    NSString *gameDir = [NSString stringWithUTF8String:getenv("POJAV_HOME")];
    if (gameDir.length == 0) gameDir = NSTemporaryDirectory();
    NSString *accountDir = [gameDir stringByAppendingPathComponent:@"accounts"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *files = [fm contentsOfDirectoryAtPath:accountDir error:nil];
    for (NSString *file in files) {
        if ([file hasSuffix:@".json"]) {
            NSString *path = [accountDir stringByAppendingPathComponent:file];
            NSMutableDictionary *data = parseJSONFromFile(path);
            if (data && ![data isKindOfClass:[NSError class]]) {
                [_accountsArray addObject:data];
            }
        }
    }
    [_tableView reloadData];
}

- (void)selectAndSaveAccount:(BaseAuthenticator *)auth {
    BaseAuthenticator.current = auth;
    setPrefObject(@"internal.selected_account", auth.authData[@"username"] ?: @"");
    [self loadAccounts];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AccountDidChangeNotification" object:nil];
}

- (void)addMicrosoftAccount {
    NSString *authURL = @"https://login.live.com/oauth20_authorize.srf?client_id=00000000402b5328&response_type=code&redirect_uri=https://login.live.com/oauth20_desktop.srf&scope=service::user.auth.xboxlive.com::MBI_SSL";

    UIView *webContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    webContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webContainer.backgroundColor = UIColor.whiteColor;

    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, webContainer.bounds.size.width, 44)];
    topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    topBar.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1];
    [webContainer addSubview:topBar];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(8, 0, 60, 44);
    [closeBtn setTitle:@"Cancel" forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(dismissWebView) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:closeBtn];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, topBar.bounds.size.width, 44)];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    titleLabel.text = @"Microsoft Login";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [topBar addSubview:titleLabel];

    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 44, webContainer.bounds.size.width, webContainer.bounds.size.height - 44)];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.navigationDelegate = self;
    self.loginWebView = webView;
    [webContainer addSubview:webView];

    [self.view addSubview:webContainer];

    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:authURL]]];
}

- (void)dismissWebView {
    [self.loginWebView.superview removeFromSuperview];
    self.loginWebView = nil;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    NSString *urlStr = url.absoluteString;
    if ([urlStr hasPrefix:@"https://login.live.com/oauth20_desktop.srf"]) {
        [self dismissWebView];
        NSString *query = url.query;
        if (query) {
            NSString *authCode = nil;
            NSString *errorDesc = nil;
            for (NSString *pair in [query componentsSeparatedByString:@"&"]) {
                NSArray *kv = [pair componentsSeparatedByString:@"="];
                if (kv.count != 2) continue;
                if ([kv[0] isEqualToString:@"code"]) {
                    authCode = [kv[1] stringByRemovingPercentEncoding];
                } else if ([kv[0] isEqualToString:@"error"]) {
                    errorDesc = [kv[1] stringByRemovingPercentEncoding];
                }
            }
            if (authCode) {
                MicrosoftAuthenticator *auth = [[MicrosoftAuthenticator alloc] initWithInput:authCode];
                [auth loginWithCallback:^(id status, BOOL success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!success) {
                            NSString *errMsg = [status isKindOfClass:NSError.class] ? [(NSError *)status localizedDescription] : ([status isKindOfClass:NSString.class] ? status : @"Login failed");
                            showDialog(localize(@"Error", nil), errMsg);
                            return;
                        }
                        if (status == nil || [status isEqualToString:@"Done"]) {
                            [self selectAndSaveAccount:auth];
                            showDialog(@"Success", [NSString stringWithFormat:@"Logged in as %@", auth.authData[@"username"] ?: @"Unknown"]);
                        } else if ([status isEqualToString:@"DEMO"]) {
                            [self selectAndSaveAccount:auth];
                            showDialog(@"Demo Account", @"Your Microsoft account has not purchased Minecraft. You will not be able to play the full game.");
                        }
                    });
                }];
            } else if (errorDesc) {
                showDialog(localize(@"Error", nil), errorDesc);
            }
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)addLocalAccount {
    NSString *name = _usernameField.text;
    if (name.length == 0) name = @"Player";
    LocalAuthenticator *auth = [[LocalAuthenticator alloc] initWithInput:name];
    [auth loginWithCallback:^(NSString *status, BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self selectAndSaveAccount:auth];
                showDialog(@"Success", [NSString stringWithFormat:@"Local account '%@' added.", name]);
            }
        });
    }];
}

- (void)addAccountTapped {
    if (_addTypeControl.selectedSegmentIndex == 0) {
        [self addMicrosoftAccount];
    } else {
        [self addLocalAccount];
    }
}

- (void)deleteAccountAtIndex:(NSInteger)index {
    NSDictionary *account = _accountsArray[index];
    NSString *gameDir2 = [NSString stringWithUTF8String:getenv("POJAV_HOME")];
    if (gameDir2.length == 0) gameDir2 = NSTemporaryDirectory();
    NSString *path = [gameDir2 stringByAppendingPathComponent:[NSString stringWithFormat:@"accounts/%@.json", account[@"username"]]];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];

    if ([account[@"username"] isEqualToString:getPrefObject(@"internal.selected_account")]) {
        BaseAuthenticator.current = nil;
        setPrefObject(@"internal.selected_account", @"");
    }

    NSString *xuid = account[@"xuid"];
    if (xuid) {
        [MicrosoftAuthenticator clearTokenDataOfProfile:xuid];
    }

    [self loadAccounts];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AccountDidChangeNotification" object:nil];
}

- (void)editAccount:(NSDictionary *)account {
    BOOL isPremium = [account[@"xboxGamertag"] length] > 0;
    if (!isPremium) return;
    _editingAccount = account;

    UIViewController *editVC = [[UIViewController alloc] init];
    editVC.title = [NSString stringWithFormat:@"Edit Account - %@", account[@"username"]];
    editVC.view.backgroundColor = ThemeManager.shared.backgroundColor;

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [editVC.view addSubview:scroll];

    UIImageView *skinPreview = [[UIImageView alloc] init];
    skinPreview.translatesAutoresizingMaskIntoConstraints = NO;
    skinPreview.contentMode = UIViewContentModeScaleAspectFit;
    skinPreview.backgroundColor = ThemeManager.shared.cardBackgroundColor;
    skinPreview.layer.cornerRadius = 12;
    skinPreview.clipsToBounds = YES;
    skinPreview.image = [UIImage systemImageNamed:@"person.circle.fill"];
    skinPreview.tintColor = ThemeManager.shared.secondaryTextColor;
    [scroll addSubview:skinPreview];

    UIImageView *headView = [[UIImageView alloc] init];
    headView.translatesAutoresizingMaskIntoConstraints = NO;
    headView.contentMode = UIViewContentModeScaleAspectFit;
    headView.backgroundColor = ThemeManager.shared.cardBackgroundColor;
    headView.layer.cornerRadius = 8;
    headView.clipsToBounds = YES;
    headView.image = [UIImage systemImageNamed:@"person.fill"];
    headView.tintColor = ThemeManager.shared.secondaryTextColor;
    [scroll addSubview:headView];

    NSString *profileId = account[@"profileId"];
    if (profileId.length > 0 && ![profileId isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
        NSString *skinURL = [NSString stringWithFormat:@"https://mc-heads.net/body/%@/200", profileId];
        [skinPreview setImageWithURL:[NSURL URLWithString:skinURL]];
        NSString *headURL = [NSString stringWithFormat:@"https://mc-heads.net/avatar/%@/80", profileId];
        [headView setImageWithURL:[NSURL URLWithString:headURL]];
    }

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    nameLabel.textColor = ThemeManager.shared.primaryTextColor;
    nameLabel.text = account[@"username"] ?: @"";
    [scroll addSubview:nameLabel];

    UILabel *uuidLabel = [[UILabel alloc] init];
    uuidLabel.translatesAutoresizingMaskIntoConstraints = NO;
    uuidLabel.font = [UIFont systemFontOfSize:12];
    uuidLabel.textColor = ThemeManager.shared.secondaryTextColor;
    uuidLabel.numberOfLines = 2;
    NSString *uuid = account[@"profileId"] ?: @"N/A";
    NSString *maskedUuid = (uuid.length > 4) ? [NSString stringWithFormat:@"%@***%@", [uuid substringToIndex:2], [uuid substringFromIndex:uuid.length - 2]] : uuid;
    uuidLabel.text = [NSString stringWithFormat:@"UUID: %@", maskedUuid];
    [scroll addSubview:uuidLabel];

    UIButton *copyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    copyBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [copyBtn setTitle:@"Copy" forState:UIControlStateNormal];
    copyBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [copyBtn addTarget:self action:@selector(copyUUID) forControlEvents:UIControlEventTouchUpInside];
    [scroll addSubview:copyBtn];

    UIButton *changeSkinBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    changeSkinBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [changeSkinBtn setTitle:@"Change Skin" forState:UIControlStateNormal];
    [changeSkinBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    changeSkinBtn.backgroundColor = ThemeManager.shared.accentColor;
    changeSkinBtn.layer.cornerRadius = 8;
    changeSkinBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [changeSkinBtn addTarget:self action:@selector(changeSkinTapped:) forControlEvents:UIControlEventTouchUpInside];
    [scroll addSubview:changeSkinBtn];

    UIButton *changeCapeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    changeCapeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [changeCapeBtn setTitle:@"Change Cape" forState:UIControlStateNormal];
    [changeCapeBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    changeCapeBtn.backgroundColor = ThemeManager.shared.accentColor;
    changeCapeBtn.layer.cornerRadius = 8;
    changeCapeBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [changeCapeBtn addTarget:self action:@selector(changeCapeTapped:) forControlEvents:UIControlEventTouchUpInside];
    [scroll addSubview:changeCapeBtn];

    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:editVC.view.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:editVC.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:editVC.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:editVC.view.bottomAnchor],

        [skinPreview.topAnchor constraintEqualToAnchor:scroll.topAnchor constant:20],
        [skinPreview.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor constant:20],
        [skinPreview.widthAnchor constraintEqualToConstant:140],
        [skinPreview.heightAnchor constraintEqualToConstant:200],

        [headView.topAnchor constraintEqualToAnchor:skinPreview.topAnchor],
        [headView.leadingAnchor constraintEqualToAnchor:skinPreview.trailingAnchor constant:16],
        [headView.widthAnchor constraintEqualToConstant:80],
        [headView.heightAnchor constraintEqualToConstant:80],

        [nameLabel.topAnchor constraintEqualToAnchor:headView.bottomAnchor constant:12],
        [nameLabel.leadingAnchor constraintEqualToAnchor:headView.leadingAnchor],

        [uuidLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:4],
        [uuidLabel.leadingAnchor constraintEqualToAnchor:headView.leadingAnchor],
        [uuidLabel.trailingAnchor constraintEqualToAnchor:editVC.view.trailingAnchor constant:-20],

        [copyBtn.centerYAnchor constraintEqualToAnchor:uuidLabel.centerYAnchor],
        [copyBtn.leadingAnchor constraintEqualToAnchor:uuidLabel.trailingAnchor constant:-50],

        [changeSkinBtn.topAnchor constraintEqualToAnchor:skinPreview.bottomAnchor constant:20],
        [changeSkinBtn.leadingAnchor constraintEqualToAnchor:editVC.view.leadingAnchor constant:20],
        [changeSkinBtn.trailingAnchor constraintEqualToAnchor:editVC.view.trailingAnchor constant:-20],
        [changeSkinBtn.heightAnchor constraintEqualToConstant:44],

        [changeCapeBtn.topAnchor constraintEqualToAnchor:changeSkinBtn.bottomAnchor constant:10],
        [changeCapeBtn.leadingAnchor constraintEqualToAnchor:editVC.view.leadingAnchor constant:20],
        [changeCapeBtn.trailingAnchor constraintEqualToAnchor:editVC.view.trailingAnchor constant:-20],
        [changeCapeBtn.heightAnchor constraintEqualToConstant:44],
        [changeCapeBtn.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor constant:-30],
    ]];

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editVC];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)copyUUID {
    NSDictionary *account = [self selectedAccount];
    NSString *uuid = account[@"profileId"] ?: @"";
    [UIPasteboard generalPasteboard].string = uuid;
    showDialog(@"Copied", @"UUID copied to clipboard.");
}

- (NSDictionary *)selectedAccount {
    NSString *selected = getPrefObject(@"internal.selected_account");
    for (NSDictionary *acc in _accountsArray) {
        if ([acc[@"username"] isEqualToString:selected]) return acc;
    }
    return _accountsArray.firstObject;
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _accountsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AccountCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AccountCell" forIndexPath:indexPath];
    NSDictionary *account = _accountsArray[indexPath.row];
    NSString *selected = getPrefObject(@"internal.selected_account");
    BOOL isSelected = [account[@"username"] isEqualToString:selected];
    [cell configureWithAccount:account isSelected:isSelected];

    cell.deleteBtn.tag = indexPath.row;
    [cell.deleteBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [cell.deleteBtn addTarget:self action:@selector(confirmDelete:) forControlEvents:UIControlEventTouchUpInside];

    cell.editBtn.tag = indexPath.row;
    [cell.editBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [cell.editBtn addTarget:self action:@selector(editTapped:) forControlEvents:UIControlEventTouchUpInside];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *account = _accountsArray[indexPath.row];
    NSString *username = account[@"username"];
    BaseAuthenticator *auth = [BaseAuthenticator loadSavedName:username];

    BOOL isPremium = [account[@"xboxGamertag"] length] > 0;
    if (!isPremium) {
        [HapticManager.shared play:HapticTypeLight];
        AccountCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [UIView animateWithDuration:0.3 animations:^{
            cell.transform = CGAffineTransformMakeScale(1.05, 1.05);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                cell.transform = CGAffineTransformIdentity;
            }];
        }];
        UIView *flash = [[UIView alloc] initWithFrame:cell.bounds];
        flash.backgroundColor = ThemeManager.shared.accentColor;
        flash.alpha = 0.3;
        flash.userInteractionEnabled = NO;
        [cell addSubview:flash];
        [UIView animateWithDuration:0.5 animations:^{
            flash.alpha = 0;
        } completion:^(BOOL finished) {
            [flash removeFromSuperview];
        }];
    }

    if (auth) {
        [self selectAndSaveAccount:auth];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteAccountAtIndex:indexPath.row];
    }
}

#pragma mark - Actions

- (void)confirmDelete:(UIButton *)sender {
    NSInteger index = sender.tag;
    NSDictionary *account = _accountsArray[index];
    UIAlertController *confirm = [UIAlertController alertControllerWithTitle:@"Delete Account"
                                                                     message:[NSString stringWithFormat:@"Delete '%@'?", account[@"username"]]
                                                              preferredStyle:UIAlertControllerStyleAlert];
    [confirm addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [confirm addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self deleteAccountAtIndex:index];
    }]];
    [self presentViewController:confirm animated:YES completion:nil];
}

- (void)editTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    NSDictionary *account = _accountsArray[index];
    [self editAccount:account];
}

#pragma mark - Change Skin / Cape

- (void)changeSkinTapped:(UIButton *)sender {
    [self presentImagePickerForCape:NO];
}

- (void)changeCapeTapped:(UIButton *)sender {
    showDialog(@"Not Available", @"Cape upload is not currently supported through the Minecraft API.");
}

- (void)presentImagePickerForCape:(BOOL)forCape {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];

    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (!image) return;

    NSString *uuid = _editingAccount[@"profileId"];
    NSString *xuid = _editingAccount[@"xuid"];
    if (!uuid || !xuid) {
        showDialog(@"Error", @"Missing account profile information.");
        return;
    }
    NSString *plainUUID = [[uuid componentsSeparatedByString:@"-"] componentsJoinedByString:@""];

    NSDictionary *tokenData = [MicrosoftAuthenticator tokenDataOfProfile:xuid];
    NSString *accessToken = tokenData[@"accessToken"];
    if (!accessToken) {
        showDialog(@"Error", @"Failed to retrieve access token. Please re-login.");
        return;
    }

    NSData *imageData = UIImagePNGRepresentation(image);
    if (!imageData) {
        showDialog(@"Error", @"Failed to process image.");
        return;
    }

    DownloadProgressOverlay *overlay = [DownloadProgressOverlay showInView:self.view title:@"Uploading Skin"];
    [overlay updateProgress:0 message:@"Uploading..."];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.minecraftservices.com/minecraft/profile/skins"]];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];

    NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];

    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"variant\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"CLASSIC\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"skin.png\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    request.HTTPBody = body;

    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [overlay dismiss];
                showDialog(@"Upload Failed", error.localizedDescription);
                return;
            }
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            if (httpResp.statusCode == 200 || httpResp.statusCode == 204) {
                [overlay finishWithMessage:@"Skin updated!"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [overlay dismiss];
                    showDialog(@"Success", @"Your skin has been updated. It may take a few minutes to appear in-game.");
                });
            } else {
                [overlay dismiss];
                NSString *errMsg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"Unknown error";
                showDialog(@"Upload Failed", [NSString stringWithFormat:@"HTTP %ld: %@", (long)httpResp.statusCode, errMsg]);
            }
        });
    }] resume];
}


- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
