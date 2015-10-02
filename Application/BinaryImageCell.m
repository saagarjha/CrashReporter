/**
 * Name: CrashReporter
 * Type: iOS application
 * Desc: iOS app for viewing the details of a crash, determining the possible
 *       cause of said crash, and reporting this information to the developer(s)
 *       responsible.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: GPL v3 (See LICENSE file for details)
 */

#import "BinaryImageCell.h"

#import <libcrashreport/libcrashreport.h>
#import <libpackageinfo/libpackageinfo.h>
#import "TableViewCellLine.h"
#import "UIImage+CrashReporter.h"
#include "font-awesome.h"

#define kColorInstallDate          [UIColor grayColor]
#define kColorNewer                [UIColor lightGrayColor]
#define kColorRecent               [UIColor redColor]
#define kColorFromUnofficialSource [UIColor colorWithRed:0.8 green:0.2 blue:0.3 alpha:1.0]

static const CGSize kLineImageSize = (CGSize){11.0, 15.0};

static UIImage *appleImage$ = nil;
static UIImage *debianImage$ = nil;
static UIImage *installDateImage$ = nil;

@implementation BinaryImageCell {
    TableViewCellLine *packageNameLine_;
    TableViewCellLine *packageIdentifierLine_;
    TableViewCellLine *packageInstallDateLine_;
}

@synthesize newer = newer_;
@synthesize recent = recent_;
@synthesize fromUnofficialSource = fromUnofficialSource_;
@synthesize packageType = packageType_;

@dynamic showsTopSeparator;

#pragma mark - Creation & Destruction

+ (void)initialize {
    if (self == [BinaryImageCell self]) {
        // Create and cache icon font images.
        UIFont *imageFont = [UIFont fontWithName:@"FontAwesome" size:11.0];
        UIColor *imageColor = [UIColor blackColor];

        appleImage$ = [[UIImage imageWithText:@kFontAwesomeApple font:imageFont color:imageColor imageSize:kLineImageSize] retain];
        debianImage$ = [[UIImage imageWithText:@kFontAwesomeDropbox font:imageFont color:imageColor imageSize:kLineImageSize] retain];
        installDateImage$ = [[UIImage imageWithText:@kFontAwesomeClockO font:imageFont color:imageColor imageSize:kLineImageSize] retain];
    }
}

+ (CGFloat)heightForPackageRowCount:(NSUInteger)rowCount {
    // FIXME: The (+ x.0) values added to the font sizes are only valid for the
    //        current font sizes (18.0 and 12.0). Determine proper calculation.
    return [super cellHeight] + [TableViewCellLine defaultHeight] * rowCount;
}

#pragma mark - Overrides (TableViewCell)

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self != nil) {
        packageNameLine_ = [[self addLine] retain];
        packageIdentifierLine_ = [[self addLine] retain];
        packageInstallDateLine_ = [[self addLine] retain];
        packageInstallDateLine_.imageView.image = installDateImage$;
    }
    return self;
}

- (void)dealloc {
    [packageNameLine_ release];
    [packageIdentifierLine_ release];
    [packageInstallDateLine_ release];
    [super dealloc];
}

- (void)configureWithObject:(id)object {
    NSAssert([object isKindOfClass:[CRBinaryImage class]], @"ERROR: Incorrect class type: Expected CRBinaryImage, received %@.", [object class]);

    CRBinaryImage *binaryImage = object;
    NSString *text = [[binaryImage path] lastPathComponent];
    [self setName:text];

    PIPackage *package = [binaryImage package];
    if (package != nil) {
        NSString *string = nil;
        BOOL isRecent = NO;
        NSDate *installDate = [package installDate];
        const NSTimeInterval interval = [[self referenceDate] timeIntervalSinceDate:installDate];
        if (interval < 86400.0) {
            if (interval < 3600.0) {
                string = NSLocalizedString(@"LESS_THAN_HOUR", nil);
            } else {
                string = [NSString stringWithFormat:NSLocalizedString(@"LESS_THAN_HOURS", nil), (unsigned)ceil(interval / 3600.0)];
            }
            isRecent = YES;
        } else {
            string = [[[self class] dateFormatter] stringFromDate:installDate];
        }
        [self setPackageInstallDate:string];
        [self setRecent:isRecent];

        [self setPackageName:[NSString stringWithFormat:@"%@ (v%@)", [package name] , [package version]]];
        [self setPackageIdentifier:[package identifier]];
        [self setPackageType:([package isKindOfClass:[PIApplePackage class]] ?
                BinaryImageCellPackageTypeApple : BinaryImageCellPackageTypeDebian)];
    } else {
        [self setPackageName:nil];
        [self setPackageIdentifier:nil];
        [self setPackageInstallDate:nil];
        [self setPackageType:BinaryImageCellPackageTypeUnknown];
    }
}

#pragma mark - Properties

- (void)setPackageName:(NSString *)packageName {
    [self setText:packageName forLabel:packageNameLine_.label];
}

- (void)setPackageIdentifier:(NSString *)packageIdentifier {
    [self setText:packageIdentifier forLabel:packageIdentifierLine_.label];
}

- (void)setPackageInstallDate:(NSString *)packageInstallDate {
    if ([packageInstallDate length] != 0) {
        packageInstallDate = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"PACKAGE_INSTALL_DATE_PREFIX", nil), packageInstallDate];
    }
    [self setText:packageInstallDate forLabel:packageInstallDateLine_.label];
}

- (void)setPackageType:(BinaryImageCellPackageType)packageType {
    if (packageType_ != packageType) {
        packageType_ = packageType;

        UIImage *image = nil;
        switch (packageType_) {
            case BinaryImageCellPackageTypeApple: image = appleImage$; break;
            case BinaryImageCellPackageTypeDebian: image = debianImage$; break;
            default: break;
        }
        [packageIdentifierLine_.imageView setImage:image];
        [self setNeedsLayout];
    }
}

- (void)setNewer:(BOOL)newer {
    if (newer_ != newer) {
        newer_ = newer;
        [packageInstallDateLine_.label setTextColor:(newer_ ? kColorNewer : kColorInstallDate)];
    }
}

- (void)setRecent:(BOOL)recent {
    if (recent_ != recent) {
        recent_ = recent;
        [packageInstallDateLine_.label setTextColor:(recent_ ? kColorRecent : kColorInstallDate)];
    }
}

- (void)setFromUnofficialSource:(BOOL)fromUnofficialSource {
    if (fromUnofficialSource_ != fromUnofficialSource) {
        fromUnofficialSource_ = fromUnofficialSource;
        [[self contentView] setBackgroundColor:(fromUnofficialSource_ ? kColorFromUnofficialSource : [UIColor whiteColor])];
    }
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
