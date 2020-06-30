MBAnimationView
===============

Animation with `UIImageView` is super simple and for basic animations it is just what you need. Just throw an array of images at your image view and tell it to go, and it will go. For animations of more than a few frames though its simplicity is also its failing–an array of `UIImage`s is handy to put together but if you want large images or a reasonable number of frames then that array could take up a serious chunk of memory. If you've tried any large animations with `UIImageView` you'll know things get crashy very quickly.

There are also a few features, like being able to know what frame is currently being displayed and setting a completion block that you regularly find yourself wanting when dealing with animations, so I've created `MBAnimationView` to provide those, and to overcome the crash inducing memory problems. 

My work was informed by the excellent [Mo DeJong](http://www.modejong.com) and you should check out his [PNGAnimatorDemo](http://www.modejong.com/iOS/#ex2) which I've borrowed from for my class.

## How It Works

The premise for the memory improvements is the fact that image data is compressed, and loading it into a `UIImage` decompresses it. So, instead of having an array of `UIImage` objects (the decompressed image data), we're going to work with an array of `NSData` objects (the compressed image data). Of course, in order to ever see the image, it will have to be decompressed at some point, but what we're going to do is create a `UIImage` on demand for the frame we want to display next, and let it go away when we're done displaying it.

So the `MBAniamtionView` has a `UIImageView`, it creates an array of `NSData` objects and then on a timer creates the frame images from the data, and sets the image view's image to it.

## Comparison

As expected crashes using the animationImages approach disappeared with `MBAnimationView`, but to understand why, I tested the following 2 pieces of code, for different numbers of frames recording memory usage, CPU utilisation and load time.

```objective-c
MBAnimationView *av = [[MBAnimationView alloc] initWithFrame:CGRectMake(0, 0, 350, 285)];
    
[av playAnimation: @"animationFrame"
                       withRange : NSMakeRange(0, 80)
                  numberPadding  : 2
                          ofType : @"png"
                             fps : 25
                          repeat : kMBAnimationViewOptionRepeatForever
                      completion : nil];
    
[self.view addSubview:av];
```

```objective-c
UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 350, 285)];
    iv.animationImages = @[[UIImage imageNamed:@"animationFrame00"],
                           [UIImage imageNamed:@"animationFrame01"],
                           
                           ... 

                           [UIImage imageNamed:@"animationFrame79"]];
    
[self.view addSubview:iv];
[iv startAnimating];
```

## Results

Starting off with small numbers of frames it's not looking too good for our new class, `UIImageView` is using less memory and significantly less CPU.

<table class="tftable" border="1"><tr><th>10 Frames</th><th>Memory Average / Peak</th><th>CPU Average / Peak</th></tr><tr><td>UIImageView</td><td>4.1MB / 4.1MB    </td><td>0% / 1% </td></tr><tr><td>MBAnimationView</td><td>4.6MB / 4.6MB</td><td>11% / 11%</td></tr></table><table class="tftable" border="1"><tr><th>20 Frames</th><th>Memory Average / Peak</th><th>CPU Average / Peak</th></tr><tr><td>UIImageView</td><td>4.4MB / 4.4MB    </td><td>0% / 1% </td></tr><tr><td>MBAnimationView</td><td>4.9MB / 4.9MB</td><td>11% / 11%</td></tr></table>


But things start looking up for us as more frames are added. _MBAnimationView_ continues to use the same amount of CPU–memory usage is creeping up, but there are no spikes. `UIImageView` however is seeing some very large spikes during setup. 

<table class="tftable" border="1"><tr><th>40 Frames</th><th>Memory Average / Peak</th><th>CPU Average / Peak</th></tr><tr><td>UIImageView</td><td>4.1MB / <span style="color:red">65MB</span>    </td><td>0% / 8% </td></tr><tr><td>MBAnimationView</td><td>5.7MB / 5.7MB</td><td>11% / 11%</td></tr></table><table class="tftable" border="1"><tr><th>80 Frames</th><th>Memory Average / Peak</th><th>CPU Average / Peak</th></tr><tr><td>UIImageView</td><td>4.5MB / <span style="color:red">119MB</span>    </td><td>0% / <span style="color:red">72%</span> </td></tr><tr><td>MBAnimationView</td><td>8.4MB / 8.4MB</td><td>11% / 11%</td></tr></table>

Those `UIImageView` memory numbers are big enough to start crashing in a lot of situations, and remember this is for a single animation.

## The Trade Off

There has to be one of course, but it turns out not to be a deal breaker. Decompressing the image data takes time, we're doing it during the animation rather than up front but it's not preventing us playing animations up to 30 fps and even higher. On the lower end devices I've tested on (iPad 2, iPhone 4) there doesn't seem to be any negative impact, in light of that I'm surprised the default animation mechanism provided by `UIImageView` doesn't take the same approach as `MBAnimationView`.
