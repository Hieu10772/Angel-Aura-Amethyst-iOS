#import "MainMenuViewController.h"
#import "ThemeManager.h"

@interface MainMenuViewController () <WKNavigationDelegate>
@property (nonatomic) WKWebView *webView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *versionLabel;
@property (nonatomic) UIActivityIndicatorView *loadingIndicator;
@end

@implementation MainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColors) name:ThemeDidChangeNotification object:nil];
    [self updateColors];
}

- (void)setup {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    _titleLabel.text = @"Angel Aura";
    [self.view addSubview:_titleLabel];

    _versionLabel = [[UILabel alloc] init];
    _versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _versionLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    NSString *ver = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] ?: @"1.0";
    _versionLabel.text = [NSString stringWithFormat:@"v%@", ver];
    [self.view addSubview:_versionLabel];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    _webView.navigationDelegate = self;
    _webView.layer.cornerRadius = 8;
    _webView.layer.masksToBounds = YES;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    [self.view addSubview:_webView];

    _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    _loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:_loadingIndicator];

    [NSLayoutConstraint activateConstraints:@[
        [_titleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:16],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],

        [_versionLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:2],
        [_versionLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor constant:1],

        [_webView.topAnchor constraintEqualToAnchor:_versionLabel.bottomAnchor constant:12],
        [_webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [_webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [_webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-16],

        [_loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_loadingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];

    // MOCK DATA - thay bằng URL thật ở bước sau
    NSString *html = @"<html><head><style>body{font-family:-apple-system;padding:16px;color:#fff;background:transparent}h2{color:#5E5CE6}.news{background:rgba(255,255,255,0.05);border-radius:8px;padding:12px;margin:8px 0}</style></head><body><h2>Latest News</h2><div class='news'><strong>Welcome to Angel Aura!</strong><br>Your Minecraft launcher for iOS.</div><div class='news'><strong>Getting Started</strong><br>Select a version and press Launch to start playing.</div><div class='news'><strong>Mod Support</strong><br>Browse and install mods from Modrinth.</div></body></html>";
    [_webView loadHTMLString:html baseURL:nil];
}

- (void)updateColors {
    ThemeManager *theme = ThemeManager.shared;
    self.view.backgroundColor = theme.backgroundColor;
    _titleLabel.textColor = theme.primaryTextColor;
    _versionLabel.textColor = theme.secondaryTextColor;
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [_loadingIndicator startAnimating];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [_loadingIndicator stopAnimating];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [_loadingIndicator stopAnimating];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
