//
//  MBAnimationView.m
//  AnimationTest
//
//  Created by Michael Behan on 02/03/2014.
//  Copyright (c) 2014 Michael Behan. All rights reserved.
//

#import "MBAnimationView.h"
#import <QuartzCore/QuartzCore.h>

@interface MBAnimationView()
{
	NSInteger currentFrame;
    NSTimeInterval timeSinceLastAnimationFrame;
    
    CADisplayLink *displayLink;
    
	NSTimeInterval animationFrameDuration;
	
	NSInteger animationRepeatCount;
    void (^complete)();
    
    BOOL retina;
}

@end

@implementation MBAnimationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        [self setup];
    }
    
    return self;
}

-(UIImage *)currentFrameImage
{
    return imageView.image;
}

-(NSInteger)currentFrameNumber
{
    return currentFrame;
}

-(void)setup
{
    complete = nil;
    self.backgroundColor = [UIColor clearColor];
    
    imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.backgroundColor = [UIColor clearColor];
    [self addSubview:imageView];
    
    retina = ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2.0);
}

-(void)setImage:(UIImage *)image
{
    imageView.image = image;
}

-(void)playAnimation:(NSString *)animationName withRange:(NSRange)range numberPadding:(int)padding ofType:(NSString *)ext fps:(NSInteger)fps repeat:(int)repeat completion:(void (^)())completionBlock
{
    //set options
    animationRepeatCount = repeat;
    animationFrameDuration = 1.0 / (fps * 1.0);
    animationNumFrames = range.length - range.location;
    complete = completionBlock;
    
    //create array of urls for frames
    NSMutableArray *URLs = [[NSMutableArray alloc] initWithCapacity:range.length - range.location];
	NSBundle* bundle = [NSBundle mainBundle];
    
	for (int i = range.location; i < range.length; i++)
    {
        NSString *paddingFormat = [NSString stringWithFormat:@"%%0%dd", padding];
        NSString *suffix = [NSString stringWithFormat:paddingFormat, i];
		NSString *filename = [NSString stringWithFormat:@"%@%@", animationName, suffix];
        NSString *path = [bundle pathForResource:filename ofType:ext];
        
        NSString *retinaFilename = [NSString stringWithFormat:@"%@@2x.%@",filename,ext];
        NSString *retinaPath = nil;
        
        //see if we have a retina version if we're on a retina device
        if(retina && [[NSFileManager defaultManager] fileExistsAtPath:[[bundle resourcePath] stringByAppendingPathComponent:retinaFilename]])
        {
            retinaPath = [bundle pathForResource:retinaFilename ofType:nil];
        }
        
        if(retina && retinaPath)
        {
            [URLs addObject:[NSURL fileURLWithPath:retinaPath]];
        }
        else
        {
            [URLs addObject:[NSURL fileURLWithPath:path]];
        }
	}
    
	//create data array
    NSMutableArray *mutableDataArray = [NSMutableArray arrayWithCapacity:[URLs count]];
    for (NSURL *url in URLs)
    {
        NSData *frameData = [NSData dataWithContentsOfURL:url];
        [mutableDataArray addObject:frameData];
    }
    
    animationData = [NSArray arrayWithArray:mutableDataArray];
    
    //show first frame
    currentFrame = 0;
    [self animationShowFrame: currentFrame];
    currentFrame = currentFrame + 1;
    
	[self startAnimating];
}

- (void) startAnimating
{
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update:)];
    displayLink.frameInterval = 1;
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	currentFrame = 0;
}

-(void)update:(CADisplayLink *)dl
{
    timeSinceLastAnimationFrame += displayLink.duration;
    
    if(timeSinceLastAnimationFrame >= animationFrameDuration)
    {
        timeSinceLastAnimationFrame = 0;
        NSUInteger frameNow;
        
        currentFrame += 1;
        frameNow = currentFrame;
        
        
        // don't go too far
        if (frameNow >= animationNumFrames)
        {
            frameNow = animationNumFrames - 1;
        }
        
        [self animationShowFrame: frameNow];
        
        if (currentFrame >= animationNumFrames)
        {
            [self stopAnimating];
            
            // continue to loop animation until loop counter reaches 0
            if (animationRepeatCount > 0)
            {
                animationRepeatCount = animationRepeatCount - 1;
                [self startAnimating];
            }
        }
    }
}

- (void) stopAnimating
{
	if (![self isAnimating])
		return;
    
    if(complete != nil)
    {
        complete();
    }
    
    [displayLink invalidate];
    displayLink = nil;
    
    //rest on final frame
	currentFrame = animationNumFrames - 1;
	[self animationShowFrame: currentFrame];
}

- (BOOL) isAnimating
{
	return (displayLink != nil);
}

- (void) animationShowFrame: (NSInteger) frame
{
	if ((frame >= animationNumFrames) || (frame < 0))
		return;
    
    NSData *imageData = animationData[frame];
    imageView.image = [UIImage imageWithData:imageData];
}

@end
