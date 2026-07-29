#import "ModpackListViewController.h"
#import "ThemeManager.h"
#import "MainCoordinator.h"
#import "ModrinthService.h"
#import "ModDetailViewController.h"
#import "AmethystProjectCell.h"
#import "HapticManager.h"
#import "DownloadProgressOverlay.h"
#import "ios_uikit_bridge.h"

@interface ModpackListViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UISearchBar *searchBar;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSMutableArray *modpacks;
@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) UILabel *emptyLabel;

@property (nonatomic) NSMutableDictionary *pageCache;
@property (nonatomic) NSMutableArray *pageOffsets;
@property (nonatomic) BOOL hasMore;
@property (nonatomic) BOOL isLoadingMore;
@property (nonatomic) NSString *currentQuery;
@property (nonatomic) NSInteger pageSize;
@end

@implementation ModpackListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _pageCache = [NSMutableDictionary dictionary];
    _pageOffsets = [NSMutableArray array];
    _hasMore = YES;
    _isLoadingMore = NO;
    _modpacks = [NSMutableArray array];
    _pageSize = 20;
    [self setup];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColors) name:ThemeDidChangeNotification object:nil];
    [self updateColors];
    [self loadModpacksWithQuery:@"" offset:0];
}

- (void)setup {
    self.view.clipsToBounds = YES;

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    _titleLabel.text = @"Modpacks";
    [self.view addSubview:_titleLabel];

    _searchBar = [[UISearchBar alloc] init];
    _searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    _searchBar.delegate = self;
    _searchBar.placeholder = @"Search modpacks...";
    _searchBar.searchBarStyle = UISearchBarStyleMinimal;
    [self.view addSubview:_searchBar];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _spinner.translatesAutoresizingMaskIntoConstraints = NO;
    _spinner.hidesWhenStopped = YES;
    [self.view addSubview:_spinner];

    _emptyLabel = [[UILabel alloc] init];
    _emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _emptyLabel.text = @"No modpacks found.\nTry a different search.";
    _emptyLabel.numberOfLines = 0;
    _emptyLabel.textAlignment = NSTextAlignmentCenter;
    _emptyLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    _emptyLabel.hidden = YES;
    [self.view addSubview:_emptyLabel];

    _tableView = [[UITableView alloc] init];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.rowHeight = 64;
    _tableView.separatorInset = UIEdgeInsetsZero;
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
    _tableView.refreshControl = refresh;
    [self.view addSubview:_tableView];

    [_tableView registerClass:[AmethystProjectCell class] forCellReuseIdentifier:@"ModpackCell"];

    [NSLayoutConstraint activateConstraints:@[
        [_titleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:16],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],

        [_searchBar.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:8],
        [_searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [_searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],

        [_spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_spinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],

        [_emptyLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_emptyLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_emptyLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
        [_emptyLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],

        [_tableView.topAnchor constraintEqualToAnchor:_searchBar.bottomAnchor constant:4],
        [_tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)updateColors {
    ThemeManager *theme = ThemeManager.shared;
    self.view.backgroundColor = theme.backgroundColor;
    _titleLabel.textColor = theme.primaryTextColor;
    _searchBar.searchTextField.textColor = theme.primaryTextColor;
    _searchBar.tintColor = theme.accentColor;
    _emptyLabel.textColor = theme.secondaryTextColor;
}

- (void)loadModpacksWithQuery:(NSString *)query offset:(NSInteger)offset {
    if (offset == 0) {
        _hasMore = YES;
        _currentQuery = query;
        [_pageCache removeAllObjects];
        [_pageOffsets removeAllObjects];
        [_spinner startAnimating];
        _tableView.hidden = YES;
        _emptyLabel.hidden = YES;
    } else {
        _isLoadingMore = YES;
    }

    [ModrinthService.shared searchProjectsWithType:@"modpack" query:query offset:offset limit:50 categoryFilter:nil loaderFilter:nil gameVersionFilter:nil completion:^(NSArray<NSDictionary *> *results, NSError *error) {
        [self.spinner stopAnimating];
        [self.tableView.refreshControl endRefreshing];
        self.isLoadingMore = NO;
        if (results) {
            self.hasMore = results.count >= 50;
            self.pageCache[@(offset)] = results;
            if (![self.pageOffsets containsObject:@(offset)]) {
                [self.pageOffsets addObject:@(offset)];
                [self.pageOffsets sortUsingSelector:@selector(compare:)];
            }
            if (offset == 0) {
                self.modpacks = [results mutableCopy];
            } else {
                [self.modpacks addObjectsFromArray:results];
            }
            self.tableView.hidden = NO;
            self.emptyLabel.hidden = self.modpacks.count > 0;
            [self.tableView reloadData];
            [self trimModpacksIfNeeded];
        }
    }];
}

- (void)trimModpacksIfNeeded {
    NSInteger maxVisible = 60;
    if (self.modpacks.count <= maxVisible) return;

    NSInteger pagesToRemove = (self.modpacks.count - maxVisible) / self.pageSize;
    if (pagesToRemove <= 0) return;

    NSInteger removeCount = pagesToRemove * self.pageSize;
    [self.modpacks removeObjectsInRange:NSMakeRange(0, removeCount)];

    CGFloat offsetY = self.tableView.contentOffset.y;
    CGFloat adjustedOffset = offsetY - removeCount * 64;
    if (adjustedOffset < 0) adjustedOffset = 0;

    while (self.pageOffsets.count > 0) {
        NSNumber *firstOffset = self.pageOffsets.firstObject;
        NSArray *page = self.pageCache[firstOffset];
        if (!page) { [self.pageOffsets removeObjectAtIndex:0]; continue; }
        if (page.count <= removeCount) {
            removeCount -= page.count;
            [self.pageOffsets removeObjectAtIndex:0];
        } else {
            break;
        }
    }

    self.tableView.contentOffset = CGPointMake(0, adjustedOffset);
}

- (void)loadMoreModpacks {
    if (_isLoadingMore || !_hasMore) return;
    NSInteger nextOffset = _pageOffsets.count > 0 ? [_pageOffsets.lastObject integerValue] + 50 : 50;
    [self loadModpacksWithQuery:_currentQuery ?: @"" offset:nextOffset];
}

- (void)restorePreviousModpackPage {
    if (_pageOffsets.count == 0) return;
    NSNumber *firstOffset = _pageOffsets.firstObject;
    if ([firstOffset integerValue] <= 0) return;
    NSNumber *prevOffset = @([firstOffset integerValue] - 50);
    NSArray *cachedPage = _pageCache[prevOffset];
    if (!cachedPage) return;

    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, cachedPage.count)];
    [self.modpacks insertObjects:cachedPage atIndexes:indexes];
    [_pageOffsets insertObject:prevOffset atIndex:0];

    CGFloat offsetY = self.tableView.contentOffset.y;
    [self.tableView reloadData];
    self.tableView.contentOffset = CGPointMake(0, offsetY + cachedPage.count * 64);
}

#pragma mark - Scroll (pagination)

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != _tableView) return;
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat frameHeight = scrollView.frame.size.height;

    if (offsetY > contentHeight - frameHeight - 150 && _hasMore && !_isLoadingMore && _modpacks.count > 0) {
        [self loadMoreModpacks];
    }
    if (offsetY < 80 && !_isLoadingMore && _pageOffsets.count > 0) {
        if ([_pageOffsets.firstObject integerValue] > 0) {
            [self restorePreviousModpackPage];
        }
    }
}

#pragma mark - Search

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self loadModpacksWithQuery:searchBar.text ?: @"" offset:0];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        [self loadModpacksWithQuery:@"" offset:0];
    }
}

- (void)pullToRefresh {
    [self loadModpacksWithQuery:_searchBar.text ?: @"" offset:0];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _modpacks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AmethystProjectCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ModpackCell" forIndexPath:indexPath];

    NSDictionary *mp = _modpacks[indexPath.row];
    NSNumber *downloads = mp[@"downloads"];
    NSString *dlStr = downloads ? [NSString stringWithFormat:@"\u2191 %@", [self formatNumber:downloads]] : @"";
    NSString *subtitle = [NSString stringWithFormat:@"%@  |  %@", dlStr, mp[@"author"] ?: @""];

    [cell configureWithTitle:mp[@"title"] subtitle:subtitle iconURL:mp[@"icon_url"] placeholder:@"square.stack.3d.up"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [HapticManager.shared play:HapticTypeLight];
    NSDictionary *mp = _modpacks[indexPath.row];
    ModDetailViewController *detail = [[ModDetailViewController alloc] initWithMod:mp];
    detail.coordinator = self.coordinator;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:detail];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nav animated:YES completion:nil];
}

- (NSString *)formatNumber:(NSNumber *)num {
    long long n = num.longLongValue;
    if (n >= 1000000) return [NSString stringWithFormat:@"%.1fM", n / 1000000.0];
    if (n >= 1000) return [NSString stringWithFormat:@"%.1fK", n / 1000.0];
    return [NSString stringWithFormat:@"%lld", n];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
