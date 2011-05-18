//
//  MidiNotesViewController.m
//  MidiNotes
//
//  Created by john goodstadt on 14/05/2011.
//  Copyright 2011 John Goodstadt. All rights reserved.
//

#import "MidiNotesViewController.h"

@implementation MidiNotesViewController
@synthesize midi,midiTableView;



- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
        
    IF_IOS_HAS_COREMIDI
    {
        
        midi = [[Midi alloc] init];
        midi.delegate = self;
        
        /* properties on the source */
        NSLog(@"%@",[midi sourceSessionName]);  // show the Apple sesion name
        NSLog(@"%@",[midi sourceDNSName]);      // show the DNS name
        NSLog(@"%@",[midi sourceDescription]);  // show all properties
        
        
        NSLog(@"%@",[midi destinationSessionName]);  // show the Apple sesion name
        NSLog(@"%@",[midi destinationDNSName]);      // show the DNS name
        NSLog(@"%@",[midi destinationDescription]);  // show all properties
        
    }
    
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark Table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int iCount = 0;
    
    IF_IOS_HAS_COREMIDI
    {
        iCount = midi.notes.count; // section 2;
        
        if (section == 0)
            iCount = 4;    
        
    }
    else
    {
        if (section == 0)
            iCount = 1; // No coreMidi message    
    }
    
    return iCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MyIdentifier = @"ApplicationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
	
    
    NSString *s = @"";
    
    IF_IOS_HAS_COREMIDI
    {
        
        
        if (indexPath.section==0) // header section
        {
            if (indexPath.row==0)
                s = [NSString stringWithFormat:@"session:%@",[midi sourceSessionName]];
            else if (indexPath.row==1)
                s = [NSString stringWithFormat:@"source:%@",[midi sourceDNSName]];
            else if (indexPath.row==2)
            {
                s = [NSString stringWithFormat:@"%@",[midi sourceAddress]];
                if (s==nil)
                    s = @"not connected";
            }
            else if (indexPath.row==3)
            {
                if ([midi.notes count] > 0)
                    s = [NSString stringWithFormat:@"Click to clear screen"];
            }
        }
        else // note section
        {
            
            MidiNote *note = [midi.notes objectAtIndex:indexPath.row];   
            s = [note description];
        }
        
    } //coreMidi
    else
    {
        s = @"No coreMidi in this IOS version.";
    }
    
    cell.textLabel.text  = s;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section==1)
    {
        MidiNote *note = [midi.notes objectAtIndex:indexPath.row];        
        
        [self midiSendNoteInForeground:[note number]];
        
        /*
         it is possible to send midi in background: try:
         
         [self performSelectorInBackground:@selector(sendMidiDataInForeGround).......];
         
         */
        
    }
    else if (indexPath.section==0)
    {
        if (indexPath.row==3)// clicked 'Clear' button
        {
            [midi.notes removeAllObjects];
            [midiTableView reloadData];
        }
    }
    
    
}
/* MIDI send routines 
 input:note number - 60 is middle C
 */
- (void) midiSendNoteInForeground:(UInt8)n
{
    
    
    const UInt8 note      = n;
    const UInt8 noteOn[]  = { 0x90, note, 127 };
    const UInt8 noteOff[] = { 0x80, note, 0   };    
    
    [midi sendBytes:noteOn size:sizeof(noteOn)];       
    
    [NSThread sleepForTimeInterval:0.25];
    [midi sendBytes:noteOff size:sizeof(noteOff)];
    
    
    
    
}


#pragma mark -
#pragma mark Delegate Calls
- (void) midiNoteReceived
{
    
    
    
    MidiNote *note = [midi.notes lastObject];
    NSLog(@"%@",[note description]);
    
    [self.midiTableView reloadData];
    
    
    [self.midiTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[midi.notes count] - 1 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    
    
}
- (void) midiNoteReceivedWithNote:(MidiNote *)note
{
    
    
    NSLog(@"%@",[note description]);
    
    const MIDIPacket *packet = note.packet;
    
    if (packet->length >= 3)
    { 
        const UInt8 status = packet->data[0];
        const UInt8 data1 =  packet->data[1];
        const UInt8 data2 =  packet->data[2];
        
        NSLog(@"raw bytes:%02X %02X %02X",status,data1,data2);
        
    }
    
    
    NSLog(@"%@",[MidiNote stringFromMIDIPacket:packet]);
    
    
    /* Translate Midi events*/
    
    UInt8 noteNumber = [MidiNote noteNumberFromMIDIPacket:packet];
    
    
    NSLog(@"Note Name:%@",[MidiNote noteNumberToNoteName:noteNumber]);
    NSLog(@"Octave:%i",[MidiNote noteNumberToOctave:noteNumber]);
    
    NSLog(@"Name and Octave:%@",[MidiNote noteNumberToString:noteNumber]);
    NSLog(@"Channel:%i",[MidiNote packetToChannelNumber:packet]);
    
    
    
    NSLog(@"Status Byte:%@",note.statusTypeDescription);
    
}
// NOT MAIN T
- (void) midiNotificationReceived
{
    NSLog(@"Midi Notification received");
    // maybe setup changes - so reload top section
    [self.midiTableView reloadData];
    
    [self.midiTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
}
// NOT MAIN T
- (void) midiNotificationReceivedWithNotification:(NSValue *)message
{
    
    // unpack C struct
    const MIDINotification *notification = [message pointerValue];
    
    switch (notification->messageID)
    {
        case kMIDIMsgObjectAdded:NSLog(@"Add Object");break;
        case kMIDIMsgObjectRemoved:NSLog(@"Remove Object");break;
        case kMIDIMsgThruConnectionsChanged:NSLog(@"Thru Connections Change");break;
        case kMIDIMsgSerialPortOwnerChanged:NSLog(@"Serial Port Owner Changed");break;
        case kMIDIMsgPropertyChanged: NSLog(@"Property Changed");break;
        case kMIDIMsgSetupChanged:NSLog(@"Setup Changed");break;
        case kMIDIMsgIOError:NSLog(@"IO Error");break;
        default: NSLog(@"midiNotify state changed %ld",notification->messageID);break;
    }
    
    
    
}



@end
