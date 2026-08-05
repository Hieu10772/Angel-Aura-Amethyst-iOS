#import "MarkdownRenderer.h"
#import "MMMarkdown.h"

@implementation MarkdownRenderer

+ (NSString *)htmlFromMarkdown:(NSString *)markdown
                     textColor:(UIColor *)textColor
               secondaryColor:(UIColor *)secondaryColor
                  accentColor:(UIColor *)accentColor
                  codeBgColor:(UIColor *)codeBgColor
                       isDark:(BOOL)isDark {
    if (markdown.length == 0) {
        return @"";
    }

    NSString *textHex = [self hexStringFromColor:textColor] ?: @"#FFFFFF";
    NSString *secondaryHex = [self hexStringFromColor:secondaryColor] ?: @"#999999";
    NSString *accentHex = [self hexStringFromColor:accentColor] ?: @"#5E5CE6";
    NSString *codeBgHex = [self hexStringFromColor:codeBgColor] ?: (isDark ? @"#222222" : @"#EEEEEE");
    NSString *blockBgHex = isDark ? @"rgba(255,255,255,0.06)" : @"rgba(0,0,0,0.05)";
    NSString *ruleHex = isDark ? @"rgba(255,255,255,0.15)" : @"rgba(0,0,0,0.15)";
    NSString *linkHex = accentHex;
    NSString *codeTextHex = isDark ? @"#7DD3FC" : @"#0C4A6E";

    NSError *error = nil;
    NSString *body = [MMMarkdown HTMLStringWithMarkdown:markdown
                                             extensions:MMMarkdownExtensionsGitHubFlavored
                                                  error:&error];
    if (!body) {
        body = @"";
    }

    NSString *template = [NSString stringWithFormat:
        @"<html><head><meta name='viewport' content='width=device-width, initial-scale=1.0'><meta charset='utf-8'>"
        "<style>"
        "body{font-family:-apple-system,'SF Pro Text',Helvetica,Arial,sans-serif;padding:8px 4px;color:%@;background:transparent;font-size:14px;"
        "-webkit-text-size-adjust:100%%;-webkit-font-smoothing:antialiased;line-height:1.55;overflow-wrap:break-word;word-break:break-word}"
        "a{color:%@;text-decoration:none}"
        "a:hover{text-decoration:underline}"
        "img{max-width:100%%;border-radius:8px}"
        "h1{font-size:20px}h2{font-size:18px}h3{font-size:16px}h4{font-size:15px}h5,h6{font-size:14px}"
        "h1,h2,h3,h4,h5,h6{color:%@;font-weight:700;margin:18px 0 8px 0;line-height:1.3}"
        "h1:first-child,h2:first-child,h3:first-child{margin-top:0}"
        "code{font-family:Menlo,monospace;font-size:12px;background:%@;padding:2px 5px;border-radius:4px;color:%@}"
        "pre{background:%@;border-radius:8px;padding:12px;margin:8px 0;overflow-x:auto}"
        "pre code{background:transparent;padding:0;font-size:12px;color:%@;white-space:pre-wrap}"
        "pre[class]{padding-left:0}"
        "blockquote{background:%@;border-left:3px solid %@;border-radius:6px;padding:10px 12px;margin:8px 0;color:%@}"
        "blockquote p{margin:0}"
        "ul,ol{margin:8px 0;padding-left:22px}"
        "li{margin:4px 0}"
        "li::marker{color:%@}"
        "hr{border:none;border-top:1px solid %@;margin:16px 0}"
        "table{border-collapse:collapse;margin:8px 0;width:100%%}"
        "th,td{border:1px solid %@;padding:6px 10px;text-align:left}"
        "th{background:%@;color:%@}"
        "del{opacity:0.6}"
        "</style></head><body>%@</body></html>",
        textHex, linkHex, accentHex, codeBgHex, codeTextHex,
        codeBgHex, codeTextHex, blockBgHex, accentHex, secondaryHex,
        accentHex, ruleHex, ruleHex, blockBgHex, textHex,
        body];

    return template;
}

+ (NSString *)hexStringFromColor:(UIColor *)color {
    CGFloat r, g, b, a;
    if (![color getRed:&r green:&g blue:&b alpha:&a]) {
        return nil;
    }
    return [NSString stringWithFormat:@"#%02X%02X%02X",
            (int)(r * 255), (int)(g * 255), (int)(b * 255)];
}

@end