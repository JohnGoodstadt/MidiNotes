//
//  MidiNotesAppDelegate.h
//  MidiNotes
//
//  Created by john goodstadt on 17/05/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MidiNotesViewController;

@interface MidiNotesAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet MidiNotesViewController *viewController;

@end
