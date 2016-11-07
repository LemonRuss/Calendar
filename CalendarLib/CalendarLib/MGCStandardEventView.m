//
//  MGCStandardEventView.m
//  Graphical Calendars Library for iOS
//
//  Distributed under the MIT License
//  Get the latest version from here:
//
//	https://github.com/jumartin/Calendar
//
//  Copyright (c) 2014-2015 Julien Martin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "MGCStandardEventView.h"

static CGFloat kSpace = 2;


@interface MGCStandardEventView ()

@property (nonatomic) UIView *leftBorderView;
@property (nonatomic) NSMutableAttributedString *attrString;

@end


@implementation MGCStandardEventView


- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
		self.contentMode = UIViewContentModeRedraw;
		
		_color = [UIColor blackColor];
		_style = MGCStandardEventViewStylePlain|MGCStandardEventViewStyleSubtitle;
		_font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
//		_leftBorderView = [[UIView alloc]initWithFrame:CGRectNull];
		[self addSubview:_leftBorderView];
	}
    return self;
}

- (void)redrawStringInRect:(CGRect)rect
{
	// attributed string can't be created with nil string
	NSMutableString *s = [NSMutableString stringWithString:@""];
	
	if (self.style & MGCStandardEventViewStyleDot) {
		[s appendString:@"\u2022 "]; // 25CF // 2219 // 30FB
	}
	
	if (self.title) {
		[s appendString:self.title];
	}
	
	UIFont *boldFont = [UIFont fontWithDescriptor:[[self.font fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:self.font.pointSize];
	NSMutableAttributedString *as = [[NSMutableAttributedString alloc]initWithString:s attributes:@{NSFontAttributeName: boldFont ?: self.font }];
	
	if (self.subtitle && self.subtitle.length > 0 && self.style & MGCStandardEventViewStyleSubtitle) {
		NSMutableString *s  = [NSMutableString stringWithFormat:@"\n\r%@", self.subtitle];
		NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc]initWithString:s attributes:@{NSFontAttributeName:self.font}];
		[as appendAttributedString:subtitle];
	}
  

  if (_subtitle != nil) {
    
    Boolean tks = [_subtitle rangeOfString: @"ТКС"].location != NSNotFound;
    Boolean vks = [_subtitle rangeOfString: @"ВКС"].location != NSNotFound;
    
    NSMutableArray* images = [NSMutableArray new];
    
    if (tks) {
      [images addObject:[UIImage imageNamed:@"call"]];
    }
    
    if (vks) {
      [images addObject:[UIImage imageNamed:@"cam"]];
    }
    if (tks || vks) {
      NSMutableAttributedString *imageString = [[NSMutableAttributedString alloc] initWithString:@"\n\r"];
      [as appendAttributedString:imageString];
    }
    for (UIImage* image in images) {
      NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithData:nil ofType:nil];
      
      attachment.image = image;
      
      NSAttributedString *image = [NSAttributedString attributedStringWithAttachment:attachment];
      [as appendAttributedString:image];
    }
  }
	
	NSTextTab *t = [[NSTextTab alloc]initWithTextAlignment:NSTextAlignmentRight location:rect.size.width options:[[NSDictionary alloc] init]];
	NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
	style.tabStops = @[t];
	//style.hyphenationFactor = .4;
	//style.lineBreakMode = NSLineBreakByTruncatingMiddle;
	[as addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, as.length)];

	UIColor *color = self.selected ? [UIColor whiteColor] : self.color;
	[as addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, as.length)];
	
	self.attrString = as;
}


- (void)layoutSubviews
{
	[super layoutSubviews];
	self.leftBorderView.frame = CGRectMake(2, 0, 2, self.bounds.size.height);
	[self setNeedsDisplay];
}

- (void)setColor:(UIColor*)color
{
	_color = color;
	[self resetColors];
}

- (void)setStyle:(MGCStandardEventViewStyle)style
{
	_style = style;
	self.leftBorderView.hidden = !(_style & MGCStandardEventViewStyleBorder);
	[self resetColors];
}

- (void)resetColors
{
	self.leftBorderView.backgroundColor = self.color;
	
	if (self.selected)
		self.backgroundColor = self.selected ? self.color : [self.color colorWithAlphaComponent:.3];
	else if (self.style & MGCStandardEventViewStylePlain)
		self.backgroundColor = [self.color colorWithAlphaComponent:.3];
	else
		self.backgroundColor = [UIColor clearColor];
	
	[self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected
{
	[super setSelected:selected];
	[self resetColors];
}

- (void)setVisibleHeight:(CGFloat)visibleHeight
{
	[super setVisibleHeight:visibleHeight];
	[self setNeedsDisplay];
}

- (void)prepareForReuse
{
	[super prepareForReuse];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGRect drawRect = CGRectInset(rect, kSpace, 0);
	if (self.style & MGCStandardEventViewStyleBorder) {
		drawRect.origin.x += kSpace;
		drawRect.size.width -= kSpace;
	}
	
	[self redrawStringInRect:drawRect];
	
	CGRect boundingRect = [self.attrString boundingRectWithSize:CGSizeMake(drawRect.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
	drawRect.size.height = fminf(drawRect.size.height, self.visibleHeight);
	
		[self.attrString.mutableString replaceOccurrencesOfString:@"\n" withString:@"  " options:NSCaseInsensitiveSearch range:NSMakeRange(0, self.attrString.length)];

	[self.attrString drawWithRect:drawRect options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin context:nil];
}

#pragma mark - NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
	MGCStandardEventView *cell = [super copyWithZone:zone];
	cell.title = self.title;
	cell.subtitle = self.subtitle;
	cell.detail = self.detail;
	cell.color = self.color;
	cell.style = self.style;
	
	return cell;
}

@end
