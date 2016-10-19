// The MIT License (MIT)
//
// Copyright (c) 2015 FPT Software
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AutoResizeTextView.h"
#import "MDTextField.h"


@interface AutoResizeTextView ()
@property(nonatomic) NSMutableArray<NSLayoutConstraint*> *placeholderConstraints;
@property(nonatomic) UIEdgeInsets lastComputedLayoutInsets;
@property(nonatomic) CGFloat lastComputedWidth;
@end


@implementation AutoResizeTextView {
    int numLines;
    BOOL settingText;
}


- (instancetype)init {
  self = [super init];
  if (self) {

    _placeholderLabel = [[UILabel alloc] init];
    [_placeholderLabel setTextColor:[UIColor grayColor]];
      [_placeholderLabel setTranslatesAutoresizingMaskIntoConstraints:false];
    [self addSubview:_placeholderLabel];

    self.textContainerInset = UIEdgeInsetsZero;
    self.textContainer.lineFragmentPadding = 0;
    [self setScrollEnabled:NO];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(textViewDidChangeWithNotification:)
               name:UITextViewTextDidChangeNotification
             object:self];
    numLines = -1;
    [self computePlaceholderConstraints];
  }
  return self;
}

#pragma mark setters

- (void)setTintColor:(UIColor *)tintColor {
  [super setTintColor:tintColor];

  if ([self isFirstResponder]) {
    [self resignFirstResponder];
    [self becomeFirstResponder];
  }
}

- (CGRect)caretRectForPosition:(UITextPosition *)position {
  CGRect caretRect = [super caretRectForPosition:position];
  caretRect.size.width = 1;
  return caretRect;
}

- (void)setPlaceholder:(NSString *)placeholder {
  _placeholder = placeholder;
  [_placeholderLabel setText:_placeholder];
}

- (void)setFont:(UIFont *)font {
  [super setFont:font];
  [_placeholderLabel setFont:font];
  [self calculateTextViewHeight];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self computePlaceholderConstraints];
}


- (void)setTextContainerInset:(UIEdgeInsets)textContainerInset {
    [super setTextContainerInset:textContainerInset];
    [self computePlaceholderConstraints];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
  _placeholderColor = placeholderColor;
  [_placeholderLabel setTextColor:_placeholderColor];
}

- (void)setMinVisibleLines:(NSInteger)minVisibleLines {
  _minVisibleLines = minVisibleLines;
  [self calculateTextViewHeight];
}

- (void)setMaxVisibleLines:(NSInteger)maxVisibleLines {
  _maxVisibleLines = maxVisibleLines;
  [self calculateTextViewHeight];
}

- (void)setMaxHeight:(float)maxHeight {
  if (_maxHeight != maxHeight) {
    _maxHeight = maxHeight;
    [self calculateTextViewHeight];
  }
}

#pragma mark private methods

- (void)layoutSubviews {
    [self computePlaceholderConstraints];

  [super layoutSubviews];
}

- (void)textViewDidChangeWithNotification:(NSNotification *)notification {
  if (notification.object == self && !settingText) {
    if (self.text.length >= 1) {
      _placeholderLabel.hidden = YES;
    } else {
      _placeholderLabel.hidden = NO;
    }
    [self calculateTextViewHeight];
  }
}

- (void)setText:(NSString *)text {
  settingText = YES;
  [super setText:text];
  settingText = NO;
  if (self.text.length >= 1) {
    _placeholderLabel.hidden = YES;
  } else {
    _placeholderLabel.hidden = NO;
  }
  [self calculateTextViewHeight];
}

- (CGFloat)computeMaxContentWidth {
    CGRect frame = self.bounds;
    UIEdgeInsets textContainerInsets = self.textContainerInset;
    UIEdgeInsets contentInsets = self.contentInset;
    
    CGFloat leftRightPadding = textContainerInsets.left +
    textContainerInsets.right +
    self.textContainer.lineFragmentPadding * 2 +
    contentInsets.left + contentInsets.right;
    
    frame.size.width -= leftRightPadding;
    
    return CGRectGetWidth(frame);
}

- (CGSize)computeDesiredContentSize {
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        
        CGRect frame = self.bounds;
        UIEdgeInsets textContainerInsets = self.textContainerInset;
        UIEdgeInsets contentInsets = self.contentInset;
        
        CGFloat leftRightPadding = textContainerInsets.left +
        textContainerInsets.right +
        self.textContainer.lineFragmentPadding * 2 +
        contentInsets.left + contentInsets.right;
        CGFloat topBottomPadding = textContainerInsets.top +
        textContainerInsets.bottom + contentInsets.top +
        contentInsets.bottom;
        
        frame.size.width -= leftRightPadding;
        frame.size.height -= topBottomPadding;
        
        NSString *textToMeasure = self.text;
        if ([textToMeasure hasSuffix:@"\n"]) {
            textToMeasure = [NSString stringWithFormat:@"%@-", self.text];
        }
        NSMutableParagraphStyle *paragraphStyle =
        [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
        UIFont * font = self.font;
        if (font == nil) {
            font = [UIFont systemFontOfSize:17]; // default UILabel font
        }
        NSDictionary *attributes = @{
                                     NSFontAttributeName : font,
                                     NSParagraphStyleAttributeName : paragraphStyle
                                     };
        CGRect size = [textToMeasure
                       boundingRectWithSize:CGSizeMake(CGRectGetWidth(frame), MAXFLOAT)
                       options:NSStringDrawingUsesLineFragmentOrigin
                       attributes:attributes
                       context:nil];
        
        CGFloat measuredHeight = ceilf(CGRectGetHeight(size) + topBottomPadding);
        return CGSizeMake(frame.size.width,measuredHeight);
    } else {
        return self.contentSize;
    }
}


- (CGFloat)intrinsicContentHeight {
    CGSize size = [self computeDesiredContentSize];
    return size.height;
 }

- (void)calculateTextViewHeight {
  CGFloat contentHeight = [self intrinsicContentHeight];
  int lastNumLine = numLines;
  numLines = contentHeight / self.font.lineHeight;
  float minHeight = _minVisibleLines * self.font.lineHeight;

  float visibleHeight = minHeight > contentHeight ? minHeight : contentHeight;
  self.contentSize = CGSizeMake(self.contentSize.width, contentHeight);

  if (_maxVisibleLines <= 0 && _maxHeight <= 0) {
    if (visibleHeight != self.frame.size.height) {
      _holder.textViewHeightConstraint.constant = visibleHeight;
    }
  } else if (_maxHeight <= 0) { // _maxVisibleLines > 0
    if ((lastNumLine <= _maxVisibleLines) && (numLines > _maxVisibleLines)) {
      self.scrollEnabled = YES;
      [self scrollToCaret];
    } else if ((lastNumLine > _maxVisibleLines) &&
               (numLines <= _maxVisibleLines)) {
      [self setScrollEnabled:NO];
      _holder.textViewHeightConstraint.constant = visibleHeight;
    } else if (numLines > _maxVisibleLines) {
      [self scrollToCaret];
    } else if (visibleHeight != self.frame.size.height) {
      _holder.textViewHeightConstraint.constant = visibleHeight;
    }
  } else {
    float maxHeight = _maxHeight;
    if (_maxVisibleLines > 0) {
      float maxVisibleHeight = _maxVisibleLines * self.font.lineHeight;
      if (maxVisibleHeight < maxHeight)
        maxHeight = maxVisibleHeight;
    }
    if (maxHeight < self.font.lineHeight)
      maxHeight = self.font.lineHeight;

    if (minHeight > maxHeight)
      minHeight = maxHeight;
    visibleHeight = minHeight > contentHeight ? minHeight : contentHeight;
    if (maxHeight < visibleHeight) {
      self.scrollEnabled = YES;
      _holder.textViewHeightConstraint.constant = maxHeight;
      [self scrollToCaret];
    } else {
      self.scrollEnabled = NO;

      _holder.textViewHeightConstraint.constant = visibleHeight;
    }
  }
  [self computePlaceholderConstraints];
}


- (void)computePlaceholderConstraints {
    if (self.placeholderLabel == nil) {
        return;
    }
    
    UIEdgeInsets insets = self.textContainerInset;
    
    CGSize size = [self computeDesiredContentSize];
    
    if (self.placeholderConstraints != nil) {
        if (UIEdgeInsetsEqualToEdgeInsets(self.lastComputedLayoutInsets, insets) && self.lastComputedWidth == size.width) {
            return;
        }
        [self removeConstraints:self.placeholderConstraints];
    }
    
    
    
    NSDictionary<NSString*,id> * views = @{ @"placeholderLabel": self.placeholderLabel };
    NSDictionary<NSString*,id> * metrics = @{ @"top" : @(insets.top),
                                              @"left" : @(insets.left),
                                              @"bottom" : @(insets.bottom),
                                              @"right" : @(insets.right)};
    
    NSArray * constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-left-[placeholderLabel]-right-|"
                                                                    options:0 metrics:metrics views:views];
    
    self.placeholderConstraints = [constraints mutableCopy];
    
    NSArray * constraints2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[placeholderLabel]-bottom-|"
                                                                     options:0 metrics:metrics views:views];
    
    [self.placeholderConstraints addObjectsFromArray:constraints2];
    
    if (size.width > 0) {
        NSLayoutConstraint * widthConstraint = [NSLayoutConstraint constraintWithItem:self.placeholderLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:size.width];
        [self.placeholderConstraints addObject:widthConstraint];
    }
    
    [self addConstraints:self.placeholderConstraints];
    
    self.lastComputedLayoutInsets = insets;
    self.lastComputedWidth = size.width;
    
    [self setNeedsLayout];
    
}

- (void)scrollToCaret {
  CGPoint bottomOffset =
      CGPointMake(0, self.contentSize.height - self.bounds.size.height);
  [self setContentOffset:bottomOffset animated:NO];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
