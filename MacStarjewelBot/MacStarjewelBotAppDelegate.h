//
//  MacStarjewledBotAppDelegate.h
//  MacStarjewledBot
//
//  Created by HotSix on 04.06.2011
//  
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import <AppKit/NSApplication.h>


@interface AppDelegate : NSObject <NSApplicationDelegate> {
    
    
    
@private 
    NSWindow *window;
    
    
@public
    UInt offset;
    size_t screenWidth;
    size_t screenHeight;
    unsigned char arField[8][8];
    int arFieldPos[2];
    NSTimer *loopTimer;
}
@property (assign) IBOutlet NSWindow *window;



-(IBAction)StartCheck:(id)sender;

-(void) TakeScreenshot;
+(CGContextRef) CreateARGBBitmapContext:(CGImageRef)inImage;
-(UInt) FindPlayfield:(UInt8 *)bitmap;
-(void) GetJewels:(UInt8 *)bitmap;
-(void) FindCombo;
-(void) SwapTiles:(short)y1:(short)x1:(short)y2:(short)x2;
-(char) RGBtoHSV:(float)r:(float)g:(float)b;
@end
