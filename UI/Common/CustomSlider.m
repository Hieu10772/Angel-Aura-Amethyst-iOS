#import "CustomSlider.h"
#import "ThemeManager.h"

@implementation CustomSlider

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.minimumTrackTintColor = ThemeManager.shared.accentColor;
    self.maximumTrackTintColor = ThemeManager.shared.separatorColor;
    self.thumbTintColor = ThemeManager.shared.accentColor;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColors) name:ThemeDidChangeNotification object:nil];
}

- (void)updateColors {
    self.minimumTrackTintColor = ThemeManager.shared.accentColor;
    self.maximumTrackTintColor = ThemeManager.shared.separatorColor;
    self.thumbTintColor = ThemeManager.shared.accentColor;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
