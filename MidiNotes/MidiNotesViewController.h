//
//  MidiNotesViewController.h
//  MidiNotes
//
//  Created by john goodstadt on 17/05/2011.
//  Copyright 2011 John Goodstadt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "midi.h"

@interface MidiNotesViewController : UIViewController <MidiDelegate,UITableViewDelegate> {
    Midi *midi;
    
    IBOutlet UITableView *midiTableView;
}
@property (nonatomic,assign) Midi *midi;
@property (nonatomic,retain) IBOutlet UITableView *midiTableView;

- (void) midiSendNoteInForeground:(UInt8)n;

@end
