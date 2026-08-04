#import <UIKit/UIKit.h>

@interface MarkdownRenderer : NSObject

+ (NSString *)htmlFromMarkdown:(NSString *)markdown
                     textColor:(UIColor *)textColor
               secondaryColor:(UIColor *)secondaryColor
                  accentColor:(UIColor *)accentColor
                  codeBgColor:(UIColor *)codeBgColor
                       isDark:(BOOL)isDark;

@end
