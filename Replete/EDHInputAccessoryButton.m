//
//  EDHInputAccessoryButton.m
//  EDHInputAccessoryView
//
//  Created by Tatsuya Tobioka on 10/12/14.
//  Copyright (c) 2014 tnantoka. All rights reserved.
//

#import "EDHInputAccessoryButton.h"

#import "EDHInputAccessoryView.h"
#import "EDHUtility.h"

#import <AudioToolbox/AudioToolbox.h>
#import <FontAwesomeKit/FontAwesomeKit.h>

@implementation EDHInputAccessoryButton

+ (EDHInputAccessoryButton *)buttonWithString:(NSString *)string {
    return [self buttonWithString:string icon:nil tapHandler:nil];
}

+ (EDHInputAccessoryButton *)buttonWithIcon:(FAKIcon *)icon tapHandler:(void (^)(EDHInputAccessoryButton *))tapHandler {
    return [self buttonWithString:nil icon:icon tapHandler:tapHandler];
}

+ (EDHInputAccessoryButton *)buttonWithString:(NSString *)string icon:(FAKIcon *)icon tapHandler:(void (^)(EDHInputAccessoryButton *))tapHandler {

    EDHInputAccessoryButton *button = [EDHInputAccessoryButton buttonWithType:UIButtonTypeCustom];

    button.string = string;
    button.icon = icon;
    button.tapHandler = tapHandler;

    return button;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addTarget:self action:@selector(buttonDidTap:) forControlEvents:UIControlEventTouchUpInside];
        [self updateBackgroundColor];
    }
    return self;
}

                               
- (void)setInputAccessoryView:(EDHInputAccessoryView *)inputAccessoryView {
    _inputAccessoryView = inputAccessoryView;
    [self updateTitle];
}

- (void)buttonDidTap:(id)sender {
    if (self.tapHandler) {
        self.tapHandler(self);
    } else if (self.string) {
        [self.inputAccessoryView.textView insertText:self.string];
        AudioServicesPlaySystemSound(1104);
    }
}

# pragma mark - Utilities

- (void)updateBackgroundColor {
    // #f7f7f7
    UIColor *bgColor = self.backgroundColor ?: [UIColor colorWithRed:247.0f / 255.0f green:247.0f / 255.0f blue:247.0f / 255.0f alpha:1.0f];
    [self setBackgroundImage:[EDHUtility imageWithColor:bgColor size:CGSizeMake(1.0f, 1.0f)] forState:UIControlStateNormal];

    // #d7d7d7
    UIColor *hBgColor = self.highlightedBackgroundColor ?: [UIColor colorWithRed:215.0f / 255.0f green:215.0f / 255.0f blue:215.0f / 255.0f alpha:1.0f];
    [self setBackgroundImage:[EDHUtility imageWithColor:hBgColor size:CGSizeMake(1.0f, 1.0f)] forState:UIControlStateHighlighted];
}

- (void)updateTitle {
    CGFloat height = CGRectGetHeight(self.inputAccessoryView.bounds);
    
    // #1f1f21
    UIColor *titleColor = self.titleColor ?: [UIColor colorWithRed:31.0f / 255.0f green:31.0f / 255.0f blue:33.0f / 255.0f alpha:1.0f];
    UIColor *hTitleColor = self.highlightedTitleColor ?: titleColor;
    
    if (self.string) {
        [self setTitle:[NSString stringWithFormat:@" %@ ", self.string] forState:UIControlStateNormal];
        [self setTitleColor:titleColor forState:UIControlStateNormal];
        [self setTitleColor:hTitleColor forState:UIControlStateHighlighted];
        self.titleLabel.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:22.0f];
    } else {
        [self.icon addAttribute:NSForegroundColorAttributeName value:titleColor];
        [self setImage:[self.icon imageWithSize:CGSizeMake(height, height)] forState:UIControlStateNormal];
        [self.icon addAttribute:NSForegroundColorAttributeName value:hTitleColor];
        [self setImage:[self.icon imageWithSize:CGSizeMake(height, height)] forState:UIControlStateHighlighted];
    }
    [self sizeToFit];
    
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

# pragma mark - Appearance

- (void)setTitleColor:(UIColor *)titleColor {
    _titleColor = titleColor;
    [self updateTitle];
}

- (void)setHighlightedTitleColor:(UIColor *)highlightedTitleColor {
    _highlightedTitleColor = highlightedTitleColor;
    [self updateTitle];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    [self updateBackgroundColor];
}

- (void)setHighlightedBackgroundColor:(UIColor *)highlightedBackgroundColor {
    _highlightedBackgroundColor = highlightedBackgroundColor;
    [self updateBackgroundColor];
}

@end
