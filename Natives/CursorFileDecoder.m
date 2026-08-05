#import "CursorFileDecoder.h"
#include <stdint.h>

static inline uint16_t cursorReadU16(const uint8_t *b) { return (uint16_t)(b[0] | (b[1] << 8)); }
static inline uint32_t cursorReadU32(const uint8_t *b) {
    return (uint32_t)(b[0] | (b[1] << 8) | (b[2] << 16) | ((uint32_t)b[3] << 24));
}
static inline int32_t cursorReadI32(const uint8_t *b) { return (int32_t)cursorReadU32(b); }
static inline CGFloat cursorClamp(CGFloat x, CGFloat lo, CGFloat hi) {
    return x < lo ? lo : (x > hi ? hi : x);
}

static const int kMaxCursorDim = 1024;

static inline uint8_t extractChannel(uint32_t v, uint32_t mask);

@implementation CursorFileDecoder

+ (UIImage *)decodeFileAtPath:(NSString *)path hotspot:(CGPoint *)hotspot {
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data.length < 16) {
        return nil;
    }
    const uint8_t *b = data.bytes;

    // .ani: RIFF container with ACON form
    if (b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F' &&
        data.length >= 12 && memcmp(b + 8, "ACON", 4) == 0) {
        return [self decodeAni:data hotspot:hotspot];
    }

    // .cur: reserved=0, type=2, count>0
    if (cursorReadU16(b) == 0 && cursorReadU16(b + 2) == 2 && cursorReadU16(b + 4) > 0) {
        return [self decodeCur:data hotspot:hotspot];
    }

    // Anything else: let UIImage try (png, jpg, gif, bmp, tiff, webp...)
    UIImage *img = [UIImage imageWithData:data];
    if (!img) {
        img = [UIImage imageWithContentsOfFile:path];
    }
    if (img && hotspot) {
        *hotspot = CGPointMake(0.5, 0.5);
    }
    return img;
}

#pragma mark - .cur (ICO-style header)

+ (UIImage *)decodeCur:(NSData *)data hotspot:(CGPoint *)hotspot {
    const uint8_t *b = data.bytes;
    NSUInteger count = cursorReadU16(b + 4);
    if (count == 0 || data.length < 6 + count * 16) {
        return nil;
    }
    int best = -1;
    long bestArea = -1;
    for (NSUInteger i = 0; i < count; i++) {
        const uint8_t *e = b + 6 + i * 16;
        int w = e[0] == 0 ? 256 : e[0];
        int h = e[1] == 0 ? 256 : e[1];
        long area = (long)w * h;
        if (area > bestArea) {
            bestArea = area;
            best = (int)i;
        }
    }
    if (best < 0) {
        return nil;
    }
    const uint8_t *e = b + 6 + best * 16;
    int w = e[0] == 0 ? 256 : e[0];
    int h = e[1] == 0 ? 256 : e[1];
    uint32_t size = cursorReadU32(e + 12);
    uint32_t offset = cursorReadU32(e + 16);
    // Hotspot is stored in the 0..255 virtual grid
    CGFloat hx = cursorClamp(cursorReadU16(e + 4) / 256.0, 0, 1);
    CGFloat hy = cursorClamp(cursorReadU16(e + 6) / 256.0, 0, 1);
    if (offset >= data.length) {
        return nil;
    }

    // PNG-compressed entries (Windows Vista+)
    if (offset + 8 <= data.length && memcmp(b + offset, "\x89PNG\r\n\x1a\n", 8) == 0) {
        uint32_t avail = (uint32_t)(data.length - offset);
        NSData *png = [data subdataWithRange:NSMakeRange(offset, MIN(size ?: avail, avail))];
        UIImage *img = [UIImage imageWithData:png];
        if (img && hotspot) {
            *hotspot = CGPointMake(hx, hy);
        }
        return img;
    }

    // Legacy BMP/DIB entry (XOR bitmap + 1bpp AND mask)
    UIImage *img = [self decodeDIB:data offset:offset width:w height:h];
    if (img && hotspot) {
        *hotspot = CGPointMake(hx, hy);
    }
    return img;
}

#pragma mark - .ani (RIFF ACON, first frame)

+ (UIImage *)decodeAni:(NSData *)data hotspot:(CGPoint *)hotspot {
    const uint8_t *b = data.bytes;
    NSUInteger len = data.length;
    int iw = 0, ih = 0;
    CGFloat hx = -1, hy = -1;
    NSData *frame = nil;

    NSUInteger pos = 12;
    while (pos + 8 <= len) {
        uint32_t chunkSize = cursorReadU32(b + pos + 4);
        if (memcmp(b + pos, "anih", 4) == 0 && pos + 8 + 20 <= len) {
            iw = (int)cursorReadU32(b + pos + 8 + 12);
            ih = (int)cursorReadU32(b + pos + 8 + 16);
            uint32_t cbSize = cursorReadU32(b + pos + 8);
            NSUInteger hotOff = cbSize >= 44 ? 40 : (cbSize >= 36 ? 36 : 0);
            if (hotOff && pos + 8 + hotOff + 8 <= len) {
                hx = cursorReadU32(b + pos + 8 + hotOff);
                hy = cursorReadU32(b + pos + 8 + hotOff + 4);
            }
        } else if (memcmp(b + pos, "LIST", 4) == 0 && pos + 12 <= len &&
                   memcmp(b + pos + 8, "fram", 4) == 0) {
            frame = [self firstIconFromFramList:data start:pos + 12 size:chunkSize - 4];
            break;
        }
        pos += 8 + chunkSize;
        if (chunkSize % 2) {
            pos += 1;
        }
    }
    if (!frame) {
        return nil;
    }
    const uint8_t *fb = frame.bytes;
    UIImage *img = nil;
    if (frame.length >= 8 && memcmp(fb, "\x89PNG\r\n\x1a\n", 8) == 0) {
        img = [UIImage imageWithData:frame];
    } else {
        img = [self decodeDIB:frame offset:0 width:iw height:ih];
    }
    if (img && hotspot) {
        CGFloat fx = (hx >= 0 && iw > 0) ? hx / iw : 0.5;
        CGFloat fy = (hy >= 0 && ih > 0) ? hy / ih : 0.5;
        *hotspot = CGPointMake(cursorClamp(fx, 0, 1), cursorClamp(fy, 0, 1));
    }
    return img;
}

+ (NSData *)firstIconFromFramList:(NSData *)data start:(NSUInteger)start size:(NSUInteger)size {
    const uint8_t *b = data.bytes;
    NSUInteger end = start + size;
    if (end > data.length) {
        end = data.length;
    }
    NSUInteger pos = start;
    while (pos + 12 <= end) {
        uint32_t chunkSize = cursorReadU32(b + pos + 4);
        if (memcmp(b + pos, "LIST", 4) == 0 && memcmp(b + pos + 8, "icon", 4) == 0) {
            NSUInteger iconEnd = pos + 12 + chunkSize - 4;
            if (iconEnd > end) {
                iconEnd = end;
            }
            NSUInteger p = pos + 12;
            while (p + 8 <= iconEnd) {
                uint32_t csize = cursorReadU32(b + p + 4);
                if (memcmp(b + p, "icon", 4) == 0 && p + 8 + csize <= iconEnd) {
                    return [data subdataWithRange:NSMakeRange(p + 8, csize)];
                }
                p += 8 + csize;
                if (csize % 2) {
                    p += 1;
                }
            }
        }
        pos += 8 + chunkSize;
        if (chunkSize % 2) {
            pos += 1;
        }
    }
    return nil;
}

#pragma mark - DIB/BMP pixel decode

+ (UIImage *)decodeDIB:(NSData *)data offset:(NSUInteger)off width:(int)w height:(int)h {
    if (w <= 0 || h <= 0 || w > kMaxCursorDim || h > kMaxCursorDim) {
        return nil;
    }
    const uint8_t *b = data.bytes;
    NSUInteger len = data.length;
    if (off + 40 > len) {
        return nil;
    }
    uint32_t biSize = cursorReadU32(b + off);
    if (biSize < 40 || off + biSize > len) {
        return nil;
    }
    int32_t biHeight = cursorReadI32(b + off + 8);
    uint16_t bpp = cursorReadU16(b + off + 14);
    uint32_t compression = cursorReadU32(b + off + 16);
    uint32_t colorsUsed = cursorReadU32(b + off + 32);
    if (compression != 0 && compression != 3) {
        return nil;
    }
    if (bpp != 1 && bpp != 4 && bpp != 8 && bpp != 16 && bpp != 24 && bpp != 32) {
        return nil;
    }
    BOOL topDown = biHeight < 0;

    NSUInteger paletteCount = 0;
    if (bpp <= 8) {
        paletteCount = colorsUsed ? colorsUsed : (1 << bpp);
        if (paletteCount > 256 || off + biSize + paletteCount * 4 > len) {
            return nil;
        }
    }

    NSUInteger xorRowSize = ((NSUInteger)w * bpp + 31) / 32 * 4;
    NSUInteger maskRowSize = ((NSUInteger)w + 31) / 32 * 4;
    NSUInteger xorStart = off + biSize + paletteCount * 4;
    NSUInteger maskStart = xorStart + (NSUInteger)h * xorRowSize;
    if (xorStart + (NSUInteger)h * xorRowSize > len) {
        return nil;
    }

    uint32_t rm = 0, gm = 0, bm = 0;
    if (compression == 3) {
        if (off + biSize + 12 > len) {
            return nil;
        }
        rm = cursorReadU32(b + off + biSize);
        gm = cursorReadU32(b + off + biSize + 4);
        bm = cursorReadU32(b + off + biSize + 8);
    }

    NSMutableData *px = [NSMutableData dataWithLength:(NSUInteger)w * h * 4];
    uint8_t *out = px.mutableBytes;

    for (int y = 0; y < h; y++) {
        int srcRow = topDown ? y : (h - 1 - y);
        NSUInteger rowStart = xorStart + (NSUInteger)srcRow * xorRowSize;
        uint8_t *dst = out + (NSUInteger)y * w * 4;
        for (int x = 0; x < w; x++) {
            NSUInteger bitOff = rowStart + (NSUInteger)x * bpp / 8;
            if (bitOff + ((bpp + 7) / 8) > len) {
                dst[x * 4 + 3] = 0;
                continue;
            }
            uint32_t r = 0, g = 0, bl = 0;
            uint8_t a = 255;
            switch (bpp) {
                case 32: {
                    uint32_t v = cursorReadU32(b + bitOff);
                    if (compression == 3) {
                        r = extractChannel(v, rm);
                        g = extractChannel(v, gm);
                        bl = extractChannel(v, bm);
                        a = 255;
                    } else {
                        bl = b[bitOff];
                        g = b[bitOff + 1];
                        r = b[bitOff + 2];
                        a = b[bitOff + 3];
                    }
                    break;
                }
                case 24:
                    bl = b[bitOff];
                    g = b[bitOff + 1];
                    r = b[bitOff + 2];
                    break;
                case 16: {
                    uint16_t v = cursorReadU16(b + bitOff);
                    r = ((v >> 10) & 0x1F) * 255 / 31;
                    g = ((v >> 5) & 0x1F) * 255 / 31;
                    bl = (v & 0x1F) * 255 / 31;
                    break;
                }
                case 8: {
                    uint32_t pi = b[bitOff];
                    if (pi >= paletteCount) { dst[x * 4 + 3] = 0; continue; }
                    NSUInteger pOff = off + biSize + pi * 4;
                    bl = b[pOff];
                    g = b[pOff + 1];
                    r = b[pOff + 2];
                    break;
                }
                case 4: {
                    uint8_t byte = b[bitOff];
                    uint32_t pi = (x % 2 == 0) ? (byte >> 4) : (byte & 0x0F);
                    if (pi >= paletteCount) { dst[x * 4 + 3] = 0; continue; }
                    NSUInteger pOff = off + biSize + pi * 4;
                    bl = b[pOff];
                    g = b[pOff + 1];
                    r = b[pOff + 2];
                    break;
                }
                case 1: {
                    uint8_t byte = b[bitOff];
                    uint32_t pi = (byte >> (7 - (x % 8))) & 1;
                    NSUInteger pOff = off + biSize + pi * 4;
                    bl = b[pOff];
                    g = b[pOff + 1];
                    r = b[pOff + 2];
                    break;
                }
            }

            // AND mask: 1 bit per pixel, set bit = transparent
            NSUInteger maskBitOff = maskStart + (NSUInteger)y * maskRowSize + (NSUInteger)x / 8;
            if (maskBitOff < len) {
                uint8_t mb = b[maskBitOff];
                if ((mb >> (7 - (x % 8))) & 1) {
                    a = 0;
                }
            }

            NSUInteger o = (NSUInteger)x * 4;
            dst[o] = (uint8_t)(r * a / 255);
            dst[o + 1] = (uint8_t)(g * a / 255);
            dst[o + 2] = (uint8_t)(bl * a / 255);
            dst[o + 3] = a;
        }
    }

    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(out, w, h, 8, (size_t)w * 4, cs,
                                             kCGImageAlphaPremultipliedLast);
    if (!ctx) {
        CGColorSpaceRelease(cs);
        return nil;
    }
    CGImageRef cg = CGBitmapContextCreateImage(ctx);
    UIImage *img = cg ? [UIImage imageWithCGImage:cg] : nil;
    CGImageRelease(cg);
    CGContextRelease(ctx);
    CGColorSpaceRelease(cs);
    return img;
}

static inline uint8_t extractChannel(uint32_t v, uint32_t mask) {
    if (!mask) {
        return 0;
    }
    int shift = 0;
    while (shift < 32 && !(mask & (1u << shift))) {
        shift++;
    }
    uint32_t m = mask >> shift;
    int width = 0;
    while ((m & 1) && width < 32) {
        width++;
        m >>= 1;
    }
    uint32_t t = (v & mask) >> shift;
    if (width >= 8) {
        return (uint8_t)(t >> (width - 8));
    }
    uint32_t max = (1u << width) - 1;
    return (uint8_t)((t * 255 + max / 2) / max);
}

@end
