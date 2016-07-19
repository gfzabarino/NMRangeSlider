//
//  RangeSlider.m
//  RangeSlider
//
//  Created by Murray Hughes on 04/08/2012
//  Copyright 2011 Null Monkey Pty Ltd. All rights reserved.
//

#import "NMRangeSlider.h"


#define IS_PRE_IOS7() (DeviceSystemMajorVersion() < 7)

NSUInteger DeviceSystemMajorVersion() {
    static NSUInteger _deviceSystemMajorVersion = -1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _deviceSystemMajorVersion = [[[[[UIDevice currentDevice] systemVersion]
                                       componentsSeparatedByString:@"."] objectAtIndex:0] intValue];
    });
    return _deviceSystemMajorVersion;
}



@interface NMRangeSlider ()
{
    float _lowerTouchOffset;
    float _upperTouchOffset;
    float _stepValueInternal;
    BOOL _haveAddedSubviews;
}

@property (retain, nonatomic) UIImageView* lowerHandle;
@property (retain, nonatomic) UIImageView* upperHandle;
@property (retain, nonatomic) UIImageView* track;
@property (retain, nonatomic) UIImageView* trackBackground;

@end


@implementation NMRangeSlider

#pragma mark -
#pragma mark - Constructors

- (id)init
{
    self = [super init];
    if (self) {
        [self configureView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self configureView];
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self)
    {
        [self configureView];
    }
    
    return self;
}


- (void) configureView
{
    //Setup the default values
    _minimumValue = 0.0;
    _maximumValue = 1.0;
    _minimumRange = 0.0;
    _stepValue = 0.0;
    _stepValueInternal = 0.0;
    
    _continuous = YES;
    
    _lowerValue = _minimumValue;
    _upperValue = _maximumValue;
    
    _lowerMaximumValue = NAN;
    _upperMinimumValue = NAN;
    _upperHandleHidden = NO;
    _lowerHandleHidden = NO;
    
    _lowerHandleHiddenWidth = 2.0f;
    _upperHandleHiddenWidth = 2.0f;
    
    _lowerTouchEdgeInsets = UIEdgeInsetsMake(-5, -5, -5, -5);
    _upperTouchEdgeInsets = UIEdgeInsetsMake(-5, -5, -5, -5);
    
}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark - Properties

- (CGPoint) lowerCenter
{
    return _lowerHandle.center;
}

- (CGPoint) upperCenter
{
    return _upperHandle.center;
}

- (void) setLowerValue:(float)lowerValue
{
    float value = lowerValue;
    
    if(_stepValueInternal>0)
    {
        value = roundf(value / _stepValueInternal) * _stepValueInternal;
    }
    
    value = MIN(value, _maximumValue);
    value = MAX(value, _minimumValue);
    
    if (!isnan(_lowerMaximumValue)) {
        value = MIN(value, _lowerMaximumValue);
    }
    
    value = MIN(value, _upperValue - _minimumRange);
    
    _lowerValue = value;
    
    [self setNeedsLayout];
}

- (void) setUpperValue:(float)upperValue
{
    float value = upperValue;
    
    if(_stepValueInternal>0)
    {
        value = roundf(value / _stepValueInternal) * _stepValueInternal;
    }

    value = MAX(value, _minimumValue);
    value = MIN(value, _maximumValue);
    
    if (!isnan(_upperMinimumValue)) {
        value = MAX(value, _upperMinimumValue);
    }
    
    value = MAX(value, _lowerValue+_minimumRange);
    
    _upperValue = value;

    [self setNeedsLayout];
}


- (void) setLowerValue:(float) lowerValue upperValue:(float) upperValue animated:(BOOL)animated
{
    if((!animated) && (isnan(lowerValue) || lowerValue==_lowerValue) && (isnan(upperValue) || upperValue==_upperValue))
    {
        //nothing to set
        return;
    }
    
    __block void (^setValuesBlock)(void) = ^ {
        
        if(!isnan(lowerValue))
        {
            [self setLowerValue:lowerValue];
        }
        if(!isnan(upperValue))
        {
            [self setUpperValue:upperValue];
        }
        
    };
    
    if(animated)
    {
        [UIView animateWithDuration:0.25  delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             
                             setValuesBlock();
                             [self layoutSubviews];
                             
                         } completion:^(BOOL finished) {
                             
                         }];
        
    }
    else
    {
        setValuesBlock();
    }

}

- (void)setLowerValue:(float)lowerValue animated:(BOOL) animated
{
    [self setLowerValue:lowerValue upperValue:NAN animated:animated];
}

- (void)setUpperValue:(float)upperValue animated:(BOOL) animated
{
    [self setLowerValue:NAN upperValue:upperValue animated:animated];
}

- (void) setLowerHandleHidden:(BOOL)lowerHandleHidden
{
    _lowerHandleHidden = lowerHandleHidden;
    [self setNeedsLayout];
}

- (void) setUpperHandleHidden:(BOOL)upperHandleHidden
{
    _upperHandleHidden = upperHandleHidden;
    [self setNeedsLayout];
}

//ON-Demand images. If the images are not set, then the default values are loaded.

- (UIImage *)trackBackgroundImage
{
    if(_trackBackgroundImage==nil)
    {
        if(IS_PRE_IOS7())
        {
            UIImage* image = [UIImage imageNamed:@"slider-default-trackBackground"];
            image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0)];
            _trackBackgroundImage = image;
        }
        else
        {
            UIImage* image = [UIImage imageNamed:@"slider-default7-trackBackground"];
            image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 2.0, 0.0, 2.0)];
            _trackBackgroundImage = image;
        }
    }
    
    return _trackBackgroundImage;
}

- (UIImage *)trackImage
{
    if(_trackImage==nil)
    {
        if(IS_PRE_IOS7())
        {
            UIImage* image = [UIImage imageNamed:@"slider-default-track"];
            image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 7.0, 0.0, 7.0)];
            _trackImage = image;
        }
        else
        {
            
            UIImage* image = [UIImage imageNamed:@"slider-default7-track"];
            image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 2.0, 0.0, 2.0)];
            image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            _trackImage = image;
        }
    }
    
    return _trackImage;
}


- (UIImage *)trackCrossedOverImage
{
    if(_trackCrossedOverImage==nil)
    {
        if(IS_PRE_IOS7())
        {
            UIImage* image = [UIImage imageNamed:@"slider-default-trackCrossedOver"];
            image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 7.0, 0.0, 7.0)];
            _trackCrossedOverImage = image;
        }
        else
        {
            UIImage* image = [UIImage imageNamed:@"slider-default7-trackCrossedOver"];
            image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 2.0, 0.0, 2.0)];
            _trackCrossedOverImage = image;
        }
    }
    
    return _trackCrossedOverImage;
}

- (UIImage *)lowerHandleImageNormal
{
    if(_lowerHandleImageNormal==nil)
    {
        if(IS_PRE_IOS7())
        {
            UIImage* image = [UIImage imageNamed:@"slider-default-handle"];
            _lowerHandleImageNormal = [image imageWithAlignmentRectInsets:UIEdgeInsetsMake(0, 2, 0, 2)];
        }
        else
        {
            UIImage* image = [UIImage imageNamed:@"slider-default7-handle"];
            _lowerHandleImageNormal = [image imageWithAlignmentRectInsets:UIEdgeInsetsMake(-1, 8, 1, 8)];
        }

    }
    
    return _lowerHandleImageNormal;
}

- (UIImage *)lowerHandleImageHighlighted
{
    if(_lowerHandleImageHighlighted==nil)
    {
        if(IS_PRE_IOS7())
        {
            UIImage* image = [UIImage imageNamed:@"slider-default-handle-highlighted"];
            _lowerHandleImageHighlighted = image;
            _lowerHandleImageHighlighted = [image imageWithAlignmentRectInsets:UIEdgeInsetsMake(0, 2, 0, 2)];

        }
        else
        {
            UIImage* image = [UIImage imageNamed:@"slider-default7-handle"];
            _lowerHandleImageHighlighted = [image imageWithAlignmentRectInsets:UIEdgeInsetsMake(-1, 8, 1, 8)];
        }
    }
    
    return _lowerHandleImageHighlighted;
}

- (UIImage *)upperHandleImageNormal
{
    if(_upperHandleImageNormal==nil)
    {
        if(IS_PRE_IOS7())
        {
            UIImage* image = [UIImage imageNamed:@"slider-default-handle"];
            _upperHandleImageNormal = [image imageWithAlignmentRectInsets:UIEdgeInsetsMake(0, 2, 0, 2)];

        }
        else
        {
            UIImage* image = [UIImage imageNamed:@"slider-default7-handle"];
            _upperHandleImageNormal = [image imageWithAlignmentRectInsets:UIEdgeInsetsMake(-1, 8, 1, 8)];
        }
    }
    
    return _upperHandleImageNormal;
}

- (UIImage *)upperHandleImageHighlighted
{
    if(_upperHandleImageHighlighted==nil)
    {
        if(IS_PRE_IOS7())
        {
            UIImage* image = [UIImage imageNamed:@"slider-default-handle-highlighted"];
            _upperHandleImageHighlighted = [image imageWithAlignmentRectInsets:UIEdgeInsetsMake(0, 2, 0, 2)];
        }
        else
        {
            UIImage* image = [UIImage imageNamed:@"slider-default7-handle"];
            _upperHandleImageHighlighted = [image imageWithAlignmentRectInsets:UIEdgeInsetsMake(-1, 8, 1, 8)];
        }
    }
    
    return _upperHandleImageHighlighted;
}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Math Math Math

//Returns the lower value based on the X potion
//The return value is automatically adjust to fit inside the valid range
-(float) lowerValueForCenterX:(float)x
{
    float _padding = _lowerHandle.frame.size.width/2.0f;
    float value = _minimumValue + (x-_padding) / (self.frame.size.width-(_padding*2)) * (_maximumValue - _minimumValue);
    
    value = MAX(value, _minimumValue);
    value = MIN(value, _upperValue - _minimumRange);
    
    return value;
}

//Returns the upper value based on the X potion
//The return value is automatically adjust to fit inside the valid range
-(float) upperValueForCenterX:(float)x
{
    float _padding = _upperHandle.frame.size.width/2.0;
    
    float value = _minimumValue + (x-_padding) / (self.frame.size.width-(_padding*2)) * (_maximumValue - _minimumValue);
    
    value = MIN(value, _maximumValue);
    value = MAX(value, _lowerValue+_minimumRange);
    
    return value;
}

- (UIEdgeInsets) trackAlignmentInsets
{
    UIEdgeInsets lowerAlignmentInsets = self.lowerHandleImageNormal.alignmentRectInsets;
    UIEdgeInsets upperAlignmentInsets = self.upperHandleImageNormal.alignmentRectInsets;
    
    CGFloat lowerOffset = MAX(lowerAlignmentInsets.right, upperAlignmentInsets.left);
    CGFloat upperOffset = MAX(upperAlignmentInsets.right, lowerAlignmentInsets.left);
    
    CGFloat leftOffset = MAX(lowerOffset, upperOffset);
    CGFloat rightOffset = leftOffset;
    CGFloat topOffset = lowerAlignmentInsets.top;
    CGFloat bottomOffset = lowerAlignmentInsets.bottom;
    
    return UIEdgeInsetsMake(topOffset, leftOffset, bottomOffset, rightOffset);
}


//returns the rect for the track image between the lower and upper values based on the trackimage object
- (CGRect)trackRect
{
    CGRect retValue;
    
    UIImage* currentTrackImage = [self trackImageForCurrentValues];
    
    retValue.size = CGSizeMake(currentTrackImage.size.width, currentTrackImage.size.height);
    
    if(currentTrackImage.capInsets.top || currentTrackImage.capInsets.bottom)
    {
        retValue.size.height=self.bounds.size.height;
    }
    
    float lowerHandleWidth = _lowerHandleHidden ? _lowerHandleHiddenWidth : _lowerHandle.frame.size.width;
    float upperHandleWidth = _upperHandleHidden ? _upperHandleHiddenWidth : _upperHandle.frame.size.width;
    
    float xLowerValue = ((self.bounds.size.width - lowerHandleWidth) * (_lowerValue - _minimumValue) / (_maximumValue - _minimumValue))+(lowerHandleWidth/2.0f);
    float xUpperValue = ((self.bounds.size.width - upperHandleWidth) * (_upperValue - _minimumValue) / (_maximumValue - _minimumValue))+(upperHandleWidth/2.0f);
    
    retValue.origin = CGPointMake(xLowerValue, (self.bounds.size.height/2.0f) - (retValue.size.height/2.0f));
    retValue.size.width = xUpperValue-xLowerValue;

    UIEdgeInsets alignmentInsets = [self trackAlignmentInsets];
    retValue = UIEdgeInsetsInsetRect(retValue,alignmentInsets);
    
    return retValue;
}

- (UIImage*) trackImageForCurrentValues
{
    if(self.lowerValue <= self.upperValue)
    {
        return self.trackImage;
    }
    else
    {
        return self.trackCrossedOverImage;
    }
}

//returns the rect for the background image
 -(CGRect) trackBackgroundRect
{
    CGRect trackBackgroundRect;
    
    trackBackgroundRect.size = CGSizeMake(_trackBackgroundImage.size.width, _trackBackgroundImage.size.height);
    
    if(_trackBackgroundImage.capInsets.top || _trackBackgroundImage.capInsets.bottom)
    {
        trackBackgroundRect.size.height=self.bounds.size.height;
    }
    
    if(_trackBackgroundImage.capInsets.left || _trackBackgroundImage.capInsets.right)
    {
        trackBackgroundRect.size.width=self.bounds.size.width;
    }
    
    trackBackgroundRect.origin = CGPointMake(0, (self.bounds.size.height/2.0f) - (trackBackgroundRect.size.height/2.0f));
    
    // Adjust the track rect based on the image alignment rects
    
    UIEdgeInsets alignmentInsets = [self trackAlignmentInsets];
    trackBackgroundRect = UIEdgeInsetsInsetRect(trackBackgroundRect,alignmentInsets);
    
    return trackBackgroundRect;
}

//returms the rect of the tumb image for a given track rect and value
- (CGRect)thumbRectForValue:(float)value image:(UIImage*) thumbImage
{
    CGRect thumbRect;
    UIEdgeInsets insets = thumbImage.capInsets;

    thumbRect.size = CGSizeMake(thumbImage.size.width, thumbImage.size.height);
    
    if(insets.top || insets.bottom)
    {
        thumbRect.size.height=self.bounds.size.height;
    }
    
    float xValue = ((self.bounds.size.width-thumbRect.size.width)*((value - _minimumValue) / (_maximumValue - _minimumValue)));
    thumbRect.origin = CGPointMake(xValue, (self.bounds.size.height/2.0f) - (thumbRect.size.height/2.0f));

    thumbRect.origin.x = roundf(thumbRect.origin.x);
    thumbRect.origin.y = roundf(thumbRect.origin.y);
    thumbRect.size.width= roundf(thumbRect.size.width);
    thumbRect.size.height= roundf(thumbRect.size.height);

    return thumbRect;

}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark - Layout


- (void) addSubviews
{
    
    //------------------------------
    // Track
    self.track = [[UIImageView alloc] initWithImage:[self trackImageForCurrentValues]];
    self.track.frame = [self trackRect];
    
    //------------------------------
    // Lower Handle Handle
    self.lowerHandle = [[UIImageView alloc] initWithImage:self.lowerHandleImageNormal highlightedImage:self.lowerHandleImageHighlighted];
    self.lowerHandle.frame = [self thumbRectForValue:_lowerValue image:self.lowerHandleImageNormal];
    
    //------------------------------
    // Upper Handle Handle
    self.upperHandle = [[UIImageView alloc] initWithImage:self.upperHandleImageNormal highlightedImage:self.upperHandleImageHighlighted];
    self.upperHandle.frame = [self thumbRectForValue:_upperValue image:self.upperHandleImageNormal];
    
    //------------------------------
    // Track Brackground
    self.trackBackground = [[UIImageView alloc] initWithImage:self.trackBackgroundImage];
    self.trackBackground.frame = [self trackBackgroundRect];
    
    
    [self addSubview:self.trackBackground];
    [self addSubview:self.track];
    [self addSubview:self.lowerHandle];
    [self addSubview:self.upperHandle];
}


-(void)layoutSubviews
{
    if(_haveAddedSubviews==NO)
    {
        _haveAddedSubviews=YES;
        [self addSubviews];
    }
    
    if(_lowerHandleHidden)
    {
        _lowerValue = _minimumValue;
    }
    
    if(_upperHandleHidden)
    {
        _upperValue = _maximumValue;
    }

    self.trackBackground.frame = [self trackBackgroundRect];
    self.track.frame = [self trackRect];
    self.track.image = [self trackImageForCurrentValues];

    // Layout the lower handle
    self.lowerHandle.frame = [self thumbRectForValue:_lowerValue image:self.lowerHandleImageNormal];
    self.lowerHandle.image = self.lowerHandleImageNormal;
    self.lowerHandle.highlightedImage = self.lowerHandleImageHighlighted;
    self.lowerHandle.hidden = self.lowerHandleHidden;
    
    // Layoput the upper handle
    self.upperHandle.frame = [self thumbRectForValue:_upperValue image:self.upperHandleImageNormal];
    self.upperHandle.image = self.upperHandleImageNormal;
    self.upperHandle.highlightedImage = self.upperHandleImageHighlighted;
    self.upperHandle.hidden= self.upperHandleHidden;
    
}

- (CGSize)intrinsicContentSize
{
   return CGSizeMake(UIViewNoIntrinsicMetric, MAX(self.lowerHandleImageNormal.size.height, self.upperHandleImageNormal.size.height));
}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark - Touch handling

-(BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchPoint = [touch locationInView:self];
    
    
    //Check both buttons upper and lower thumb handles because
    //they could be on top of each other.
    
    if(CGRectContainsPoint(UIEdgeInsetsInsetRect(_lowerHandle.frame, self.lowerTouchEdgeInsets), touchPoint))
    {
        _lowerHandle.highlighted = YES;
        _lowerTouchOffset = touchPoint.x - _lowerHandle.center.x;
    }
    
    if(CGRectContainsPoint(UIEdgeInsetsInsetRect(_upperHandle.frame, self.upperTouchEdgeInsets), touchPoint))
    {
        _upperHandle.highlighted = YES;
        _upperTouchOffset = touchPoint.x - _upperHandle.center.x;
    }
    
    _stepValueInternal= _stepValueContinuously ? _stepValue : 0.0f;
    
    return YES;
}


-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if(!_lowerHandle.highlighted && !_upperHandle.highlighted ){
        return YES;
    }
    
    CGPoint touchPoint = [touch locationInView:self];
    
    if(_lowerHandle.highlighted)
    {
        //get new lower value based on the touch location.
        //This is automatically contained within a valid range.
        float newValue = [self lowerValueForCenterX:(touchPoint.x - _lowerTouchOffset)];
        
        //if both upper and lower is selected, then the new value must be LOWER
        //otherwise the touch event is ignored.
        if(!_upperHandle.highlighted || newValue<_lowerValue)
        {
            _upperHandle.highlighted=NO;
            [self bringSubviewToFront:_lowerHandle];
            
            [self setLowerValue:newValue animated:_stepValueContinuously ? YES : NO];
        }
        else
        {
            _lowerHandle.highlighted=NO;
        }
    }
    
    if(_upperHandle.highlighted )
    {
        float newValue = [self upperValueForCenterX:(touchPoint.x - _upperTouchOffset)];

        //if both upper and lower is selected, then the new value must be HIGHER
        //otherwise the touch event is ignored.
        if(!_lowerHandle.highlighted || newValue>_upperValue)
        {
            _lowerHandle.highlighted=NO;
            [self bringSubviewToFront:_upperHandle];
            [self setUpperValue:newValue animated:_stepValueContinuously ? YES : NO];
        }
        else
        {
            _upperHandle.highlighted=NO;
        }
    }
     
    
    //send the control event
    if(_continuous)
    {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
    //redraw
    [self setNeedsLayout];

    return YES;
}



-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    _lowerHandle.highlighted = NO;
    _upperHandle.highlighted = NO;
    
    if(_stepValue>0)
    {
        _stepValueInternal=_stepValue;
        
        [self setLowerValue:_lowerValue animated:YES];
        [self setUpperValue:_upperValue animated:YES];
    }
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end

@interface NMRangeSliderAutomaticMinimumRangeHelper()

- (void)onRangeSliderValueChange:(id)sender;
- (float)minimumUpperValueInPoints;
- (float)maximumLowerValueInPoints;
- (float)upperTotalWidth;
- (float)lowerTotalWidth;
- (void)updateRangeSliderMinimumRange;

@end

@implementation NMRangeSliderAutomaticMinimumRangeHelper

- (id)init {
    self = [super init];
    if (self) {
        // default transparency widths for bundled handle images (at least iOS 7)
        _lowerRightTransparencyWidth = 6.0f;
        _upperLeftTransparencyWidth = 6.0f;
    }
    return self;
}

- (void)setRangeSlider:(NMRangeSlider *)rangeSlider {
    if (_rangeSlider != rangeSlider) {
        NSArray *keypaths = @[@"minimumValue", @"maximumValue", @"frame"];
        if (_rangeSlider) {
            [_rangeSlider removeTarget:self
                                action:@selector(onRangeSliderValueChange:)
                      forControlEvents:UIControlEventValueChanged];
            for (NSString *keypath in keypaths) {
                [_rangeSlider removeObserver:self
                                  forKeyPath:keypath];
            }
        }
        _rangeSlider = rangeSlider;
        if (_rangeSlider) {
            if ([_rangeSlider superview]) {
                [[_rangeSlider superview] layoutIfNeeded];
            } else {
                [_rangeSlider layoutIfNeeded];
            }
            [_rangeSlider addTarget:self
                             action:@selector(onRangeSliderValueChange:)
                   forControlEvents:UIControlEventValueChanged];
            for (NSString *keypath in keypaths) {
                [_rangeSlider addObserver:self
                               forKeyPath:keypath
                                  options:NSKeyValueObservingOptionNew
                                  context:nil];
            }
            [self updateRangeSliderMinimumRange];
        }
    }
}

#pragma mark - Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self updateRangeSliderMinimumRange];
}

#pragma mark - Actions

- (void)onRangeSliderValueChange:(id)sender {
    float padding = self.rangeSlider.lowerHandleImageNormal.size.width / 2.0f;
    _lowerValue = (self.rangeSlider.lowerCenter.x - padding) / [self lowerTotalWidth] * (self.rangeSlider.maximumValue - self.rangeSlider.minimumValue);
    padding = [self minimumUpperValueInPoints];
    _upperValue = (self.rangeSlider.upperCenter.x - padding) / [self upperTotalWidth] * (self.rangeSlider.maximumValue - self.rangeSlider.minimumValue);
    if ([self.delegate respondsToSelector:@selector(rangeSliderAutomaticMinimumRangeHelper:onValuesChangeWithLowerValue:upperValue:)]) {
        [self.delegate rangeSliderAutomaticMinimumRangeHelper:self
                                 onValuesChangeWithLowerValue:self.lowerValue
                                                   upperValue:self.upperValue];
    }
}

#pragma mark - Public methods

- (void)setLowerValue:(float)lowerValue animated:(BOOL)animated {
    [self setLowerValue:lowerValue
             upperValue:NAN
               animated:animated];
}

- (void)setUpperValue:(float)upperValue animated:(BOOL)animated {
    [self setLowerValue:NAN
             upperValue:upperValue
               animated:animated];
}

- (void)setLowerValue:(float)lowerValue upperValue:(float)upperValue animated:(BOOL)animated {
    float translatedLowerValue = NAN;
    float translatedUpperValue = NAN;
    if (!isnan(upperValue)) {
        _upperValue = upperValue;
        float padding = [self minimumUpperValueInPoints];
        float centerX = _upperValue / (self.rangeSlider.maximumValue - self.rangeSlider.minimumValue) * [self upperTotalWidth] + padding;
        self.rangeSlider.upperValue = [self.rangeSlider upperValueForCenterX:centerX];
        translatedUpperValue = [self.rangeSlider upperValueForCenterX:centerX];
    }
    if (!isnan(lowerValue)) {
        _lowerValue = lowerValue;
        float padding = self.rangeSlider.lowerHandleImageNormal.size.width / 2.0f;
        float centerX = _lowerValue / (self.rangeSlider.maximumValue - self.rangeSlider.minimumValue) * [self lowerTotalWidth] + padding;
        translatedLowerValue = [self.rangeSlider lowerValueForCenterX:centerX];
    }
    [self.rangeSlider setLowerValue:translatedLowerValue
                         upperValue:translatedUpperValue
                           animated:animated];
    [self.rangeSlider layoutIfNeeded];
}

#pragma mark - Internal methods

- (float)minimumUpperValueInPoints {
    return self.rangeSlider.lowerHandleImageNormal.size.width -
            self.lowerRightTransparencyWidth +
            self.rangeSlider.upperHandleImageNormal.size.width / 2.0f -
            self.upperLeftTransparencyWidth;
}

- (float)maximumLowerValueInPoints {
    return self.rangeSlider.frame.size.width -
            self.rangeSlider.upperHandleImageNormal.size.width +
            self.upperLeftTransparencyWidth -
            self.rangeSlider.lowerHandleImageNormal.size.width / 2.0f +
            self.lowerRightTransparencyWidth;
}

// These two do probably the same in the end... oh well..

- (float)upperTotalWidth {
    return self.rangeSlider.frame.size.width -
            self.rangeSlider.upperHandleImageNormal.size.width / 2.0f -
            [self minimumUpperValueInPoints];
}

- (float)lowerTotalWidth {
    return [self maximumLowerValueInPoints] -
            self.rangeSlider.lowerHandleImageNormal.size.width / 2.0f;
}

- (void)updateRangeSliderMinimumRange {
    float totalWidth = (self.rangeSlider.frame.size.width -
            self.rangeSlider.lowerHandleImageNormal.size.width / 2.0f -
            self.rangeSlider.upperHandleImageNormal.size.width / 2.0f);
    if (totalWidth > 0.0f) {
        self.rangeSlider.minimumRange = ([self minimumUpperValueInPoints] - self.rangeSlider.lowerHandleImageNormal.size.width / 2.0f) / totalWidth * (self.rangeSlider.maximumValue - self.rangeSlider.minimumValue);
    }
}

#pragma mark - Override accessors

- (void)setLowerValue:(float)lowerValue {
    [self setLowerValue:lowerValue
               animated:NO];
}

- (void)setUpperValue:(float)upperValue {
    [self setUpperValue:upperValue
               animated:NO];
}

#pragma mark - Dealloc

- (void)dealloc {
    self.rangeSlider = nil;
}

@end
