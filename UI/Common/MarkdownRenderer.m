#import "MarkdownRenderer.h"

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

    NSMutableArray *blocks = [self blockify:markdown];

    NSMutableString *body = [NSMutableString string];
    BOOL inList = NO;
    NSString *listTag = nil;

    for (NSString *block in blocks) {
        // Fenced code block
        if ([block hasPrefix:@"```"]) {
            NSString *code = [block substringFromIndex:3];
            // Strip optional language identifier on the first line (```swift)
            NSRange firstLineRange = [code rangeOfString:@"\n"];
            if (firstLineRange.location != NSNotFound && firstLineRange.location < 20) {
                NSString *firstLine = [code substringToIndex:firstLineRange.location];
                if ([firstLine stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet].length > 0) {
                    code = [code substringFromIndex:NSMaxRange(firstLineRange)];
                }
            }
            if ([code hasSuffix:@"```"]) {
                code = [code substringToIndex:code.length - 3];
            }
            if ([code hasSuffix:@"\n"]) code = [code substringToIndex:code.length - 1];
            [body appendFormat:@"<pre style='background:%@;border-radius:8px;padding:12px;margin:8px 0;overflow-x:auto'><code style='font-family:Menlo,monospace;font-size:12px;color:%@;white-space:pre-wrap'>%@</code></pre>",
             codeBgHex, codeTextHex, [self escapeHTML:code]];
            continue;
        }

        // Horizontal rule
        if ([self isHorizontalRule:block]) {
            [body appendFormat:@"<hr style='border:none;border-top:1px solid %@;margin:16px 0'>", ruleHex];
            continue;
        }

        // Blockquote
        if ([block hasPrefix:@">"]) {
            NSString *quoteText = [block substringFromIndex:1];
            [body appendFormat:@"<blockquote style='background:%@;border-left:3px solid %@;border-radius:6px;padding:10px 12px;margin:8px 0;color:%@'><p style='margin:0'>%@</p></blockquote>",
             blockBgHex, accentHex, secondaryHex, [self inlineFormat:quoteText textColor:textHex accentColor:accentHex]];
            continue;
        }

        // Headings
        NSRegularExpression *headingRegex = [NSRegularExpression regularExpressionWithPattern:@"^(#{1,6})\\s+(.*)$" options:0 error:nil];
        NSTextCheckingResult *hMatch = [headingRegex firstMatchInString:block options:0 range:NSMakeRange(0, block.length)];
        if (hMatch) {
            NSInteger level = [[block substringWithRange:[hMatch rangeAtIndex:1]] length];
            NSString *content = [block substringWithRange:[hMatch rangeAtIndex:2]];
            [body appendFormat:@"<h%ld style='color:%@;font-weight:600;margin:16px 0 8px 0'>%@</h%ld>",
             (long)level, (level <= 2 ? accentHex : textHex), [self inlineFormat:content textColor:textHex accentColor:accentHex], (long)level];
            continue;
        }

        // Unordered list
        if ([self isUnorderedListItem:block]) {
            if (inList) {
                [body appendFormat:@"</%@>", listTag];
                inList = NO;
                listTag = nil;
            }
            [body appendString:@"<ul style='margin:8px 0;padding-left:20px'>"];
            inList = YES;
            listTag = @"ul";
            NSArray *lines = [block componentsSeparatedByString:@"\n"];
            for (NSString *line in lines) {
                if (![self isUnorderedListItem:line]) continue;
                NSString *itemContent = [self unorderedItemContent:line];
                [body appendFormat:@"<li style='margin:4px 0'>%@</li>", [self inlineFormat:itemContent textColor:textHex accentColor:accentHex]];
            }
            continue;
        }

        // Ordered list
        if ([self isOrderedListItem:block]) {
            if (inList) {
                [body appendFormat:@"</%@>", listTag];
                inList = NO;
                listTag = nil;
            }
            [body appendString:@"<ol style='margin:8px 0;padding-left:20px'>"];
            inList = YES;
            listTag = @"ol";
            NSArray *lines = [block componentsSeparatedByString:@"\n"];
            for (NSString *line in lines) {
                NSRegularExpression *orderedRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*\\d+[\\.\\)]\\s+(.*)$" options:0 error:nil];
                NSTextCheckingResult *oMatch = [orderedRegex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
                if (!oMatch) continue;
                NSString *itemContent = [line substringWithRange:[oMatch rangeAtIndex:1]];
                [body appendFormat:@"<li style='margin:4px 0'>%@</li>", [self inlineFormat:itemContent textColor:textHex accentColor:accentHex]];
            }
            continue;
        }

        // Plain paragraph
        if (inList) {
            [body appendFormat:@"</%@>", listTag];
            inList = NO;
            listTag = nil;
        }
        [body appendFormat:@"<p style='margin:8px 0;line-height:1.5;color:%@'>%@</p>",
         textHex, [self inlineFormat:block textColor:textHex accentColor:accentHex]];
    }

    if (inList) {
        [body appendFormat:@"</%@>", listTag];
    }
    NSString *linkColor = linkHex;
    NSString *template = [NSString stringWithFormat:
        @"<html><head><meta name='viewport' content='width=device-width, initial-scale=1.0'>"
        "<style>"
        "body{font-family:-apple-system,'SF Pro Text',Helvetica,Arial,sans-serif;padding:8px 4px;color:%@;background:transparent;font-size:14px;"
        "-webkit-text-size-adjust:100%%;-webkit-font-smoothing:antialiased}"
        "a{color:%@;text-decoration:none}"
        "a:hover{text-decoration:underline}"
        "img{max-width:100%%;border-radius:8px}"
        "h1{font-size:20px}h2{font-size:18px}h3{font-size:16px}h4{font-size:15px}h5,h6{font-size:14px}"
        "code{font-family:Menlo,monospace;font-size:12px;background:%@;padding:2px 5px;border-radius:4px;color:%@}"
        "pre code{background:transparent;padding:0}"
        "li::marker{color:%@}"
        "</style></head><body>%@</body></html>",
        textHex, linkColor, codeBgHex, codeTextHex, accentHex, body];

    return template;
}

// Split markdown into logical blocks (code fences stay as one block)
+ (NSMutableArray *)blockify:(NSString *)markdown {
    NSArray *lines = [markdown componentsSeparatedByString:@"\n"];
    NSMutableArray *blocks = [NSMutableArray array];
    NSMutableString *current = [NSMutableString string];
    BOOL inFence = NO;

    void (^flush)(void) = ^{
        NSString *trimmed = [current stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (trimmed.length > 0) {
            [blocks addObject:trimmed];
        }
        [current setString:@""];
    };

    for (NSString *line in lines) {
        if ([line hasPrefix:@"```"]) {
            if (inFence) {
                [current appendFormat:@"\n%@", line];
                flush();
                inFence = NO;
            } else {
                if (current.length > 0) flush();
                [current appendString:@"```"];
                inFence = YES;
            }
            continue;
        }
        if (inFence) {
            [current appendFormat:@"\n%@", line];
            continue;
        }
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if (trimmedLine.length == 0) {
            flush();
        } else {
            if (current.length > 0) [current appendString:@"\n"];
            [current appendString:line];
        }
    }
    if (inFence) {
        [current appendString:@"\n```"];
    }
    flush();

    return blocks;
}

+ (BOOL)isHorizontalRule:(NSString *)block {
    NSString *trimmed = [block stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (trimmed.length < 3) return NO;
    unichar first = [trimmed characterAtIndex:0];
    if (first != '-' && first != '*' && first != '_') return NO;
    for (NSUInteger i = 0; i < trimmed.length; i++) {
        unichar c = [trimmed characterAtIndex:i];
        if (c != first && ![[NSCharacterSet whitespaceCharacterSet] characterIsMember:c]) return NO;
    }
    return YES;
}

+ (BOOL)isUnorderedListItem:(NSString *)block {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*[-*+]\\s+" options:0 error:nil];
    return [regex numberOfMatchesInString:block options:0 range:NSMakeRange(0, block.length)] > 0;
}

+ (BOOL)isOrderedListItem:(NSString *)block {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*\\d+[\\.\\)]\\s+" options:0 error:nil];
    return [regex numberOfMatchesInString:block options:0 range:NSMakeRange(0, block.length)] > 0;
}

+ (NSString *)unorderedItemContent:(NSString *)block {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*[-*+]\\s+" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:block options:0 range:NSMakeRange(0, block.length)];
    if (match) {
        return [block substringFromIndex:match.range.length];
    }
    return block;
}

// Inline formatting: **bold**, *italic*, `code`, [link](url), ![image](url)
+ (NSString *)inlineFormat:(NSString *)text textColor:(NSString *)textColorHex accentColor:(NSString *)accentHex {
    NSMutableString *result = [NSMutableString stringWithString:[self escapeHTML:text]];

    // Inline code first (so ** inside code isn't processed)
    result = [self replaceInlineCode:result];
    // Links and images
    result = [self replaceLinks:result accentHex:accentHex];
    // Bold
    result = [self replacePattern:@"\\*\\*(.+?)\\*\\*" inString:result with:@"<strong>$1</strong>"];
    // Italic
    result = [self replacePattern:@"\\*([^*]+)\\*" inString:result with:@"<em>$1</em>"];
    // Strikethrough
    result = [self replacePattern:@"~~(.+?)~~" inString:result with:@"<del>$1</del>"];

    return result;
}

+ (NSMutableString *)replaceInlineCode:(NSMutableString *)string {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"`([^`]+)`" options:0 error:nil];
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    if (matches.count == 0) return string;

    NSMutableString *result = [NSMutableString string];
    NSUInteger pos = 0;
    for (NSTextCheckingResult *m in matches) {
        [result appendString:[string substringWithRange:NSMakeRange(pos, m.range.location - pos)]];
        [result appendFormat:@"<code>%@</code>", [string substringWithRange:[m rangeAtIndex:1]]];
        pos = NSMaxRange(m.range);
    }
    [result appendString:[string substringFromIndex:pos]];
    return result;
}

+ (NSMutableString *)replaceLinks:(NSMutableString *)string accentHex:(NSString *)accentHex {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(!?)\\[([^\\]]*)\\]\\(([^)\\s]+)(?:\\s+\"[^\"]*\")?\\)" options:0 error:nil];
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    if (matches.count == 0) return string;

    NSMutableString *result = [NSMutableString string];
    NSUInteger pos = 0;
    for (NSTextCheckingResult *m in matches) {
        [result appendString:[string substringWithRange:NSMakeRange(pos, m.range.location - pos)]];
        BOOL isImage = [[string substringWithRange:[m rangeAtIndex:1]] isEqualToString:@"!"];
        NSString *label = [string substringWithRange:[m rangeAtIndex:2]];
        NSString *url = [string substringWithRange:[m rangeAtIndex:3]];
        if (isImage) {
            [result appendFormat:@"<img src='%@' alt='%@'>", url, label];
        } else {
            [result appendFormat:@"<a href='%@' style='color:%@'>%@</a>", url, accentHex, label];
        }
        pos = NSMaxRange(m.range);
    }
    [result appendString:[string substringFromIndex:pos]];
    return result;
}

+ (NSMutableString *)replacePattern:(NSString *)pattern inString:(NSMutableString *)string with:(NSString *)replacement {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    if (matches.count == 0) return string;

    NSMutableString *result = [NSMutableString string];
    NSUInteger pos = 0;
    for (NSTextCheckingResult *m in matches) {
        [result appendString:[string substringWithRange:NSMakeRange(pos, m.range.location - pos)]];
        NSString *matchStr = [string substringWithRange:m.range];
        NSMutableString *replaced = [replacement mutableCopy];
        // Substitute $1..$9 groups
        for (NSUInteger g = 1; g < m.numberOfRanges; g++) {
            NSRange gRange = [m rangeAtIndex:g];
            NSString *groupStr = gRange.location != NSNotFound ? [string substringWithRange:gRange] : @"";
            [replaced replaceOccurrencesOfString:[NSString stringWithFormat:@"$%lu", (unsigned long)g]
                                      withString:groupStr options:0 range:NSMakeRange(0, replaced.length)];
        }
        [result appendString:replaced];
        pos = NSMaxRange(m.range);
    }
    [result appendString:[string substringFromIndex:pos]];
    return result;
}

+ (NSString *)escapeHTML:(NSString *)string {
    if (string.length == 0) return @"";
    NSMutableString *escaped = [string mutableCopy];
    [escaped replaceOccurrencesOfString:@"&" withString:@"&amp;" options:0 range:NSMakeRange(0, escaped.length)];
    [escaped replaceOccurrencesOfString:@"<" withString:@"&lt;" options:0 range:NSMakeRange(0, escaped.length)];
    [escaped replaceOccurrencesOfString:@">" withString:@"&gt;" options:0 range:NSMakeRange(0, escaped.length)];
    [escaped replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:0 range:NSMakeRange(0, escaped.length)];
    return escaped;
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
