//
//  JewledBotAppDelegate.m
//  JewledBot
//
//  Created by HotSix on 04.06.2011
//  
//  Version 0.9.1

#import "MacStarjewelBotAppDelegate.h"

@implementation AppDelegate

@synthesize window;



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSRightMouseDownMask handler:^(NSEvent *event){
        
        if([loopTimer isValid]) {
            NSLog(@"Stopping loopTimer...");
            [loopTimer invalidate];
            loopTimer = nil;
        }
    }];
    
    NSLog(@"JeweledBot started...");
    
}



- (void) TakeScreenshot
{

    // Search WindowList for StarCraft II window
    CGWindowID winID = 0;
    CFArrayRef windowList = CGWindowListCopyWindowInfo( kCGWindowListExcludeDesktopElements, kCGNullWindowID );
 
    for (NSMutableDictionary *entry in (NSArray *)windowList) {
        NSString *currentWindow = [entry objectForKey:(id)kCGWindowName];
        if ((currentWindow != NULL) && ([currentWindow isEqualToString:@"StarCraft II"])) {
            // Get windowID and window origins
            winID = [[entry objectForKey:(id)kCGWindowNumber] intValue];
            CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[entry objectForKey:(id)kCGWindowBounds], &bounds);
            NSLog(@"StarCraft II window ID: %i",winID);
            break;

        } 
    }

    CFRelease(windowList);

    if(!winID) {
        NSLog(@"StarCraft II window not found!");
        return;
    }

    CGRect rect = CGRectMake(bounds.origin.x+600,bounds.origin.y+92,400,400);
    
    // grab StarJewel playfield part of sc2 window
    CGImageRef image = CGWindowListCreateImage(rect, 8, winID, kCGWindowImageBoundsIgnoreFraming);
    if(image == NULL) {
        NSLog(@"ERROR: Couldn't create display image");
        goto Error;
    }

    
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(image));
    
    UInt8 *bitmap = (UInt8 *)CFDataGetBytePtr(data);
  

    imageWidth =  CGImageGetWidth(image);
    imageHeight = CGImageGetHeight(image);
       
    NSLog(@"window size: %zu x %zu", imageWidth, imageHeight);
  
    if (bitmap != NULL) {
        
        if(offset == 0) {
            offset = [self FindPlayfield:bitmap];
/*
            // just for testing....save screen shot of the area and save to desktop - disabled here
            if(screenDone == 0) {
                NSString* path = [@"~/Desktop/sc-screen.png" stringByExpandingTildeInPath];
                NSURL *outURL = [[NSURL alloc] initFileURLWithPath:path];

                CGImageDestinationRef dr = CGImageDestinationCreateWithURL ((CFURLRef)outURL, kUTTypePNG , 1, NULL);
                CGImageDestinationAddImage(dr, image, NULL);
                CGImageDestinationFinalize(dr);
                screenDone = 1;
            }
*/
        }
        if(offset == 0)
            NSLog(@"No playfield found!");
        else {
            //NSLog(@"Playfield found!");
            [self GetJewels:bitmap];
            [self FindCombo];
            
        }
        
    }    
   
Error:    
	CGImageRelease(image);
    CFRelease(data);
    
}



-(UInt) FindPlayfield:(UInt8 *)bitmap
{
    UInt z, toffset;
    short r, g, b, grey;
    unsigned short numCheck = 0;
                
    toffset = imageWidth*3*4+8;

    for(z = 0; z < 8; z++) {
        
        r = bitmap[toffset+2];
        g = bitmap[toffset+1];
        b = bitmap[toffset+0];
        
        grey = (r+g+b)/3;
        //NSLog(@"grey: 0x%02x",grey);
        // find grey pattern background of gem playfield
        if( (z&1) == 0) {
            if(grey < 0x25 || grey > 0x30)
                break;
            else 
                numCheck++;
        } else {
            if(grey < 0x15 || grey > 0x20)
                break;
            else
                numCheck++;                    
        }
        
        // Size of one juwelfield in bytes
        toffset += 50*4;
        
    }
    
    if(numCheck == 8) {
        
        arFieldPos[0] = 1;
        arFieldPos[1] = 1;
        return 4;
        
    } else
        return 0;
            

}

-(void) GetJewels:(UInt8 *)bitmap
{
    unsigned char row, col, z;
    int r, g, b;
    float rf,gf,bf;
    
    UInt toffset, toffset2;
    
    for(row = 0; row < 8; row++) {
        
        toffset2 = (row*imageWidth*50*4);
        
        for(col = 0; col < 8; col++) {
            // Get approximate center of current jewel            
            toffset = offset+(25*imageWidth*4)+(col*50*4)+toffset2;
           
            r = 0;
            g = 0;
            b = 0;
            
            // read center line of jewel and sum r,g,b values
            for(z=0; z < 50; z++) {
                r += bitmap[toffset+2];
                g += bitmap[toffset+1];
                b += bitmap[toffset+0];
                toffset += 4;
            }
            
            //get r,g,b average and convert RGB to HVS color 
            r = r/25;
            g = g/25;
            b = b/25;
            
            rf = r/255.0f;
            gf = g/255.0f;
            bf = b/255.0f;
            
            //printf("Jewel %i-%i: ",(row+1),(col+1));
            arField[row][col] = [self RGBtoHSV:rf:gf:bf];
           
            // NSLog(@"Jewel %i-%i: %02x %02x %02x",(row+1),(col+1),r,g,b);
            
        }
        
    }
    
}


// IMPROVE ME! Need to check for 4er, 5er gems and cross matches
-(void) FindCombo
{
    short x,y;
    unsigned char s1,s2,s3,s4;
    
    
    for(y = 7; y >= 0; y--) {
        
        for(x = 0; x <= 7; x++) {
            
            s1 = arField[y+0][x+0];
            
            // ####################################### x-checks
            
            if(x <= 5) {
                s2 = arField[y+0][x+1];
                s3 = arField[y+0][x+2];
                //NSLog(@"y,x: %i,%i - s1: %i, s2: %i, s3: %i",y,x,s1,s2,s3);
                if(x < 5) {
                    s4 = arField[y+0][x+3];
                    if(s1 == s3 && s1 == s4) {
                        // oxoo
                        //NSLog(@"Found combo 1 at %i,%i",y,x);
                        [self SwapTiles:y:x:y:x+1];
                        return;
                    }
                    if(s1 == s2 && s1 == s4) {
                        // ooxo
                        //NSLog(@"Found combo 2 at %i,%i",y,x);
                        [self SwapTiles:y:x+2:y:x+3];
                        return;
                    }    
                }
                
                if(y >= 1) {
                    s4 = arField[y-1][x+0];
                    if(s2 == s3 && s2 == s4) {
                        // o
                        // xoo
                        //NSLog(@"Found combo 3 at %i,%i",y,x);
                        [self SwapTiles:y:x:y-1:x];
                        return;
                    }
                    s4 = arField[y-1][x+1];
                    if(s1 == s3 && s1 == s4) {
                        //  o
                        // oxo
                        //NSLog(@"Found combo 4 at %i,%i",y,x);
                        [self SwapTiles:y:x+1:y-1:x+1];
                        return;
                    }
                    s4 = arField[y-1][x+2];
                    if(s1 == s2 && s2 == s4) {
                        //   o
                        // oox
                        //NSLog(@"Found combo 5 at %i,%i",y,x);
                        [self SwapTiles:y:x+2:y-1:x+2];
                        return;
                    }        
                }
                
                if(y <= 6) {
                    s4 = arField[y+1][x+0];
                    if(s2 == s3 && s2 == s4) {
                        // xoo
                        // o
                        //NSLog(@"Found combo 6 at %i,%i",y,x);
                        [self SwapTiles:y:x:y+1:x];
                        return;
                    }
                    s4 = arField[y+1][x+1];
                    if(s1 == s3 && s1 == s4) {
                        // oxo
                        //  o
                        //NSLog(@"Found combo 7 at %i,%i",y,x);
                        [self SwapTiles:y:x+1:y+1:x+1];
                        return;
                    }
                    s4 = arField[y+1][x+2];
                    if(s1 == s2 && s2 == s4) {
                        // oox
                        //   o
                        //NSLog(@"Found combo 8 at %i,%i",y,x);
                        [self SwapTiles:y:x+2:y+1:x+2];
                        return;
                    } 
                }
            }
            
            // ################################ y checks
            
            if( y >= 2) {
                s2 = arField[y-1][x+0];
                s3 = arField[y-2][x+0];
                
                if(y >= 3) {
                    s4 = arField[y-3][x+0];
                    if(s1 == s3 && s1 == s4) {
                        // o
                        // o
                        // x
                        // o
                        //NSLog(@"Found combo 9 at %i,%i",y,x);
                        [self SwapTiles:y:x:y-1:x];
                        return;
                    }
                    if(s1 == s2 && s1 == s4) {
                        // o
                        // x
                        // o
                        // o
                        //NSLog(@"Found combo 10 at %i,%i",y,x);
                        [self SwapTiles:y-2:x:y-3:x];
                        return;
                    }
                }
                
                
                if(x >= 1) {
                    s4 = arField[y+0][x-1];
                    if(s2 == s3 && s2 == s4) {
                        //  o
                        //  o
                        // ox
                        //NSLog(@"Found combo 11 at %i,%i",y,x);
                        [self SwapTiles:y:x:y:x-1];
                        return;
                    }
                    s4 = arField[y-1][x-1];
                    if(s1 == s3 && s1 == s4) {
                        //  o
                        // ox
                        //  o
                        //NSLog(@"Found combo 12 at %i,%i",y,x);
                        [self SwapTiles:y-1:x:y-1:x-1];
                        return;
                    }
                    s4 = arField[y-2][x-1];
                    if(s1 == s2 && s2 == s4) {
                        // ox
                        //  o
                        //  o
                        //NSLog(@"Found combo 13 at %i,%i",y,x);
                        [self SwapTiles:y-2:x:y-2:x-1];
                        return;
                    }        
                }
                
                if(x <= 6) {
                    s4 = arField[y+0][x+1];
                    if(s2 == s3 && s2 == s4) {
                        // o
                        // o
                        // xo
                        //NSLog(@"Found combo 14 at %i,%i",y,x);
                        [self SwapTiles:y:x:y:x+1];
                        return;
                    }
                    s4 = arField[y-1][x+1];
                    if(s1 == s3 && s1 == s4) {
                        // o
                        // xo
                        // o
                        //NSLog(@"Found combo 15 at %i,%i",y,x);
                        [self SwapTiles:y-1:x:y-1:x+1];
                        return;
                    }
                    s4 = arField[y-2][x+1];
                    if(s1 == s2 && s2 == s4) {
                        // xo
                        // o
                        // o
                        //NSLog(@"Found combo 16 at %i,%i",y,x);
                        [self SwapTiles:y-2:x:y-2:x+1];
                        return;
                    } 
                }
                
                
            }
            // ########## end y-checks
        }
    }
    
    NSLog(@"Combos checked");
    
    
}

-(void) SwapTiles:(short)y1:(short)x1:(short)y2:(short)x2
{
    CGEventRef newEvent;
    int posX1, posY1, posX2, posY2;
    
    posX1 = bounds.origin.x+600+arFieldPos[0]+(x1*50)+25;
    posY1 = bounds.origin.y+92+arFieldPos[1]+(y1*50)+25;
    posX2 = bounds.origin.x+600+arFieldPos[0]+(x2*50)+25;
    posY2 = bounds.origin.y+92+arFieldPos[1]+(y2*50)+25;
    
    CGPoint newPos1 = CGPointMake(posX1, posY1);
    CGPoint newPos2 = CGPointMake(posX2, posY2);
    
    NSLog(@"swap tiles: %i,%i - %i,%i",y1,x1,y2,x2);
    
    
    newEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, newPos1, kCGMouseButtonLeft);
    CGEventPost(kCGHIDEventTap, newEvent);
    usleep(10000);
    newEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, newPos1, kCGMouseButtonLeft);
    CGEventPost(kCGHIDEventTap, newEvent);
    
    usleep(100000);
    
    newEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, newPos2, kCGMouseButtonLeft);
    CGEventPost(kCGHIDEventTap, newEvent);
    usleep(10000);
    newEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, newPos2, kCGMouseButtonLeft);
    CGEventPost(kCGHIDEventTap, newEvent);
//    NSLog(@"Event posted");

    return;
}


-(char) RGBtoHSV:(float)r:(float)g:(float)b
{
	float min, max, delta;
    float h,s,v;
    char c = 0;
	min = MIN( r, MIN(g, b) );
	max = MAX( r, MAX(g, b) );
	v = max;				// v
	delta = max - min;
    
	if( max != 0 )
		s = delta / max;		// s
	else {
		// r = g = b = 0		// s = 0, v is undefined
		s = 0;
		h = -1;
        goto Done;
        
	}
	if( r == max )
		h = ( g - b ) / delta;		// between yellow & magenta
	else if( g == max )
		h = 2 + ( b - r ) / delta;	// between cyan & yellow
	else
		h = 4 + ( r - g ) / delta;	// between magenta & cyan
	h *= 60;				// degrees
	if( h < 0 )
		h += 360;
Done:
    if(s < 0.1) {
        //printf("GREY\n");
        c = 1;
    } else if(h > 280 && h < 290) {
        //printf("PURPLE\n");
        c = 2;
    } else if(h > 100 && h < 110) {
        //printf("GREEN\n");
        c = 3;
    } else if(h > 60 && h < 80) {
        //printf("YELLOW\n");
        c = 4;
    } else if(h > 190 && h < 210) {
        //printf("BLUE\n");
        c = 5;
    } else if(h < 20) {
        //printf("RED\n");
        c = 6;
    }
//    if(c == 0) {
//        printf("UNKNOWN\n");
//        printf("H: %f, S: %f, V: %f\n",h,s,v);
//    }
    
    return c;
}

-(IBAction) StartCheck:(id)sender
{
    
    
    loopTimer = [NSTimer scheduledTimerWithTimeInterval: 0.6 
                                                 target: self 
                                               selector:@selector(TakeScreenshot) 
                                               userInfo: nil 
                                                repeats: YES];
 
}
@end
