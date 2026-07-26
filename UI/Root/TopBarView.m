#import "TopBarView.h"
#import "ThemeManager.h"
#import "utils.h"
#import "LauncherPreferences.h"
#import "UIView+LiquidGlass.h"

@interface TopBarView ()
@property (nonatomic) UILabel *jitStatusLabel;
@property (nonatomic) UILabel *timeLabel;
@property (nonatomic) UIButton *fileManagerButton;
@property (nonatomic) UIButton *settingsButton;
@property (nonatomic) NSTimer *timeTimer;
@property (nonatomic) NSTimer *jitTimer;
@end

@implementation TopBarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _jitStatusLabel = [[UILabel alloc] init];
    _jitStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _jitStatusLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    _jitStatusLabel.text = @"JIT: ...";
    [self addSubview:_jitStatusLabel];

    _timeLabel = [[UILabel alloc] init];
    _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _timeLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    _timeLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_timeLabel];

    _fileManagerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _fileManagerButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_fileManagerButton setImage:[UIImage systemImageNamed:@"folder"] forState:UIControlStateNormal];
    [_fileManagerButton addTarget:self action:@selector(fileTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_fileManagerButton];

    _settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_settingsButton setImage:[UIImage systemImageNamed:@"gearshape"] forState:UIControlStateNormal];
    [_settingsButton addTarget:self action:@selector(settingsTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_settingsButton];

    [NSLayoutConstraint activateConstraints:@[
        [_jitStatusLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:14],
        [_jitStatusLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

        [_timeLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_timeLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

        [_settingsButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10],
        [_settingsButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_settingsButton.widthAnchor constraintEqualToConstant:28],
        [_settingsButton.heightAnchor constraintEqualToConstant:28],

        [_fileManagerButton.trailingAnchor constraintEqualToAnchor:_settingsButton.leadingAnchor constant:-6],
        [_fileManagerButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_fileManagerButton.widthAnchor constraintEqualToConstant:28],
        [_fileManagerButton.heightAnchor constraintEqualToConstant:28],
    ]];

    [self updateTime];
    _timeTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];

    // Check JIT status immediately and every 5 seconds
    [self checkJITStatus];
    _jitTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkJITStatus) userInfo:nil repeats:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColors) name:ThemeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLiquidGlass) name:@"LiquidGlassDidChangeNotification" object:nil];
    [self updateColors];
    [self updateLiquidGlass];
}

- (void)fileTapped {
    if (self.delegate) [self.delegate topBarDidTapFileManager];
}

- (void)settingsTapped {
    if (self.delegate) [self.delegate topBarDidTapSettings];
}

- (void)updateColors {
    ThemeManager *theme = ThemeManager.shared;
    self.backgroundColor = theme.topBarBackgroundColor;
    _jitStatusLabel.textColor = theme.secondaryTextColor;
    _timeLabel.textColor = theme.primaryTextColor;
    _fileManagerButton.tintColor = theme.accentColor;
    _settingsButton.tintColor = theme.accentColor;
}

- (void)updateLiquidGlass {
    if (getPrefBool(@"general.liquid_glass")) {
        [self lg_addGlassEffectWithTint:[UIColor colorWithWhite:1 alpha:0.08] cornerRadius:0];
    } else {
        [self lg_removeGlassEffect];
    }
}

- (void)updateJITStatus:(BOOL)enabled {
    _jitStatusLabel.text = enabled ? @"JIT: ✓" : @"JIT: ✗";
    _jitStatusLabel.textColor = enabled ? ThemeManager.shared.successColor : ThemeManager.shared.warningColor;
}

- (void)updateTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm";
    _timeLabel.text = [formatter stringFromDate:[NSDate date]];
}

- (void)checkJITStatus {
    BOOL enabled = isJITEnabled(false);
    [self updateJITStatus:enabled];
}

- (void)dealloc {
    [_timeTimer invalidate];
    [_jitTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
