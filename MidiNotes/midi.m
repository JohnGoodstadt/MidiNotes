//
//  midi.m
//
//  Created by john goodstadt on 05/05/2011.
//  Copyright 2011 John Goodstadt. All rights reserved.
//  Use this file in your own projects as you see fit.
//  Please email me at john@goodstadt.me.uk for any problems, fixes, addition or thanks.
//

#import "midi.h"


/* avoid not found compile message without these C decalations*/
static void MIDINotifyMessageProc(const MIDINotification *message, void *refCon);
static void MIDIReadNoteProc(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon);
/// A helper that NSLogs an error message if "c" is an error code
#define NSLogError(c,str) do{if (c) NSLog(@"Error (%@): %lu:%@", str, c,[NSError errorWithDomain:NSMachErrorDomain code:c userInfo:nil]);}while(false)

#define MaxNotesToKeep 1000


NSString * const MidiType_toString[] = {
    @"Note Off",
    @"Note On",
    @"Active Sensing",
    @"After Touch",
    @"Control Change",
    @"Program Change",
    @"Channel Pressure",
    @"Pitch Wheel",
    @"Undefined"
};

// To convert enum to string:
//NSString *str = MidiType_toString[theEnumValue];
#pragma mark -
#pragma mark Single Midi Note Class
#pragma mark -
@implementation MidiNote
/*
 
 Represents a MIDI note
 1. Categorizes incoming notes (messages) in to 9 categories (subset of full MIDI specification)
 2. Useful conversion routines:
    A) Translate MIDI status byte into correct category (statusToType).
    B) Channel Number from packet
    C) e.g. 'C4' from 60, string from packet
    D) e.g. note 60 from packet - noteNumberFromnPacket
    E) octave from packet
    F) e.g. 'C4' from 60 - noteNumberToNoteName
 
 */
@synthesize packet,timeStamp,status,data1,data2,statusType,statusTypeDescription,channel;



- (id) initWithPacket:(const MIDIPacket *)p
{
    if ((self = [super init]))
    {
        
        
        packet   = p;
        timeStamp = p->timeStamp;
        
        statusType = [MidiNote statusToType:p]; // moved to here
        
        channel = [MidiNote packetToChannelNumber:p];	// only set for this category
        status=(p->length > 0) ? p->data[0] : 0;
        data1=(p->length > 1) ? p->data[1] : 0;
        data2=(p->length > 2) ? p->data[2] : 0;
            
        statusTypeDescription = MidiType_toString[statusType];
        
        
    }
    return self;
}
-(NSString *) name
{
    return [MidiNote noteNumberToNoteName:self.data1];
}
-(int) octave
{
    return [MidiNote noteNumberToOctave:self.data1];
}
-(UInt8) number
{
    return self.data1;
}

-(NSString *) description
{
    
    NSString *m = [NSString stringWithFormat:@"%02X %02X %02X %@%i %@",self.status,self.data1,self.data2,[MidiNote noteNumberToNoteName:self.data1] ,[MidiNote noteNumberToOctave:self.data1],statusTypeDescription];
    
    
    return m;

}
+(MidiType ) statusToType:(const MIDIPacket *)p
{
    MidiType statusToReturn = kUndefined;
    
    UInt8 status=(p->length > 0) ? p->data[0] : 0;
    
    UInt8 data2=(p->length > 2) ? p->data[2] : 0;
    
    UInt8 higherNibble = status >> 4;
    //UInt8 lowerNibble = status << 4; // zero out top nibble
    //lowerNibble = lowerNibble >> 4;  // place in lower part again with top 34 bits zero
    
    if (status >= 0x80 && status <= 0xEF )
    {
        
        if (higherNibble == 0x8)
            statusToReturn = kNoteOff;
        else if (higherNibble == 0x9)
        {
            if (data2 == 0x0)
                statusToReturn = kNoteOff;
            else
                statusToReturn = kNoteOn;
        }
        else if (higherNibble == 0xA)
            statusToReturn = kAfterTouch;
        else if (higherNibble == 0xB)
            statusToReturn = kControlChange;
        else if (higherNibble == 0xC)
            statusToReturn = kProgramChange;
        else if (higherNibble == 0xD)
            statusToReturn = kChannelPressure;
        else if (higherNibble == 0xE)
            statusToReturn = kPitchWheel;
        else
            statusToReturn = kUndefined;
        
    }
    else if (status == 0xFE)
    {       
        statusToReturn = kActiveSensing;
    }else
    {       
        statusToReturn = kUndefined;
    }
    
    return statusToReturn;
    
}

+(UInt8) packetToChannelNumber:(const MIDIPacket *) p
{
    UInt8 status=(p->length > 0) ? p->data[0] : 0;

    UInt8 lowerNibble = status << 4; // zero out top nibble
    lowerNibble = lowerNibble >> 4;  // place in lower part again with top 34 bits zero

    UInt8 channel = lowerNibble;	// only set for this category
    channel++;  // musicians count from 1 to 16 - not 0 to 15
    
    return channel; 
}
/*
 Translate note number 60 into octave 4
 MIDI spaec gives valid values as 0 to 127 - 0 is octave-1 127 is octave 9
 e.g.
 int noteNumber = [Midi noteNumberToOctave:60] ; // noteNumber will be 4
 */
+(int) noteNumberToOctave:(int)noteNumber
{
    // octaves start from -1 see :http://tomscarff.110mb.com/midi_analyser/midi_note_numbers_for_octaves.htm
    if (noteNumber <0)  // invalid
        noteNumber = 0;// lowest note
    
    if (noteNumber>127) // invalid
        noteNumber = 127; // highest octave
    
    int octave = (noteNumber / 12) - 1;
    
    return octave;
}
/*
 e.g. noteNumber 61 returns 'C#4' 
 */
+(NSString *)noteNumberToString:(int)noteNumber// noteVolume:(int)noteVolume
{   
    return [NSString stringWithFormat:@"%@%i",[MidiNote noteNumberToNoteName:noteNumber],
            [MidiNote noteNumberToOctave:noteNumber]];
    
}
/* derive note number from packet */
+(UInt8) noteNumberFromMIDIPacket:(const MIDIPacket *) packet
{
    return (packet->length > 1) ? packet->data[1] : 0;
}
/* derive octave number from packet */
+(UInt8) octaveFromMIDIPacket:(const MIDIPacket *) packet
{
    return (packet->length > 2) ? packet->data[2] : 0;
}
// TODO revise this:
/*
 return displyable string from packet
 e.g. Note Off middle C# on channel 16 would print
 8F 3C 00 C#4 Note Off
 
 */
+(NSString *) stringFromMIDIPacket:(const MIDIPacket *) packet
{
    
    
    NSString *m = @"";
    
    if (packet->length >= 3)
    {
        
        MidiType statusType = [MidiNote statusToType:packet];
        
       // NSString *str = MidiType_toString[statusType];
        
        const UInt8 status =  packet->data[0];
        const UInt8 data1 =  packet->data[1];
        const UInt8 data2 =  packet->data[2];
        
        m = [NSString stringWithFormat:@"%02X %02X %02X %@%i %@",
             status,data1,data2,
             [MidiNote noteNumberToNoteName:(int)data1],[MidiNote  noteNumberToOctave:(int)data1], MidiType_toString[statusType]];
        
    }
    
    return m;
    
}
/*
 Translate note number 60 into C
 MIDI spaec gives valid values as 0 to 127
 e.g. 
 NSString *note = [Midi noteNumberToNoteName:60];   // note will be @"C " - extra space at end ready for sharp sign
 
 
 */
+(NSString *) noteNumberToNoteName:(int) noteNumber
{
    NSString *note = @"";
    
    if (noteNumber<0) // invalid
        noteNumber = 0; // lowest note
    if (noteNumber>127) // invalid
        noteNumber = 127; // highest note
    
    int i = noteNumber % 12;
    
    switch (i) {
        case 0:note = @"C ";break;
        case 1:note = @"C#";break;
        case 2:note = @"D ";break;
        case 3:note = @"D#";break;
        case 4:note = @"E ";break;
        case 5:note = @"F ";break;
        case 6:note = @"F#";break;
        case 7:note = @"G ";break;
        case 8:note = @"G#";break;
        case 9:note = @"A ";break;
        case 10:note = @"A#";break;
        case 11:note = @"B ";break;
    }
    
    
    return note;
}

@end
#pragma mark -
#pragma mark Midi Interface
#pragma mark -
/*
 
 Main MIDI interface.
 1. Set up calls to coreMidi
 2. Receive Notifications, reading Notes and sending notes - on seperate thread
 3. Filter out certain messages not wanted - e.g. too many Active Sensing MIDI messages
 4. hold Set of all notes available for delegate to use (e.g. TableView)
 
 
 */

@implementation Midi

@synthesize delegate,notes,isOutputPaused,filteredNotes;

- (id) init
{
    if ((self = [super init]))
    {       

        
        
        OSStatus s = MIDIClientCreate((CFStringRef)@"MidiMonitor MIDI Client", MIDINotifyMessageProc, self, &client);
        NSLogError(s, @"Create MIDI client");
        
        s = MIDIOutputPortCreate(client, (CFStringRef)@"MidiMonitor Output Port", &outputPort);
        NSLogError(s, @"Create output MIDI port");
        
        
        // address of self?
        s = MIDIInputPortCreate(client, (CFStringRef)@"MidiMonitor Input Port", MIDIReadNoteProc, self, &inputPort);
        NSLogError(s, @"Create input MIDI port");
        
        MIDINetworkSession* session = [MIDINetworkSession defaultSession];
        session.enabled = YES;
        session.connectionPolicy = MIDINetworkConnectionPolicy_Anyone;
        
        const ItemCount numberOfSources      = MIDIGetNumberOfSources();
        NSLog(@"Number Of Sources %lu",numberOfSources);
        if (numberOfSources > 0)
        {
            MIDIEndpointRef endpoint = MIDIGetSource(0); 
            OSStatus s = MIDIPortConnectSource(inputPort, endpoint, self);
            NSLogError(s, @"Connecting to MIDI source");
            
        }

        const ItemCount numberOfDestinations = MIDIGetNumberOfDestinations();
         NSLog(@"Number Of Destinationss %lu",numberOfDestinations);
        
//        NSLog(@"%@",[self sourceSessionName]);
//        NSLog(@"%@",[self sourceDNSName]);
//        NSLog(@"%@",[self sourceDescription]);
        
        // structures used
        notes = [[NSMutableArray alloc] initWithCapacity:10];
        filteredNotes  = [[NSMutableSet alloc] initWithCapacity:10];
        isOutputPaused = NO;
    }
    
      
    
    
    
    
   
    
    return self;
}

- (void) dealloc
{
    if (outputPort)
    {
        OSStatus s = MIDIPortDispose(outputPort);
        NSLogError(s, @"Dispose MIDI port");
    }
    
    if (inputPort)
    {
        OSStatus s = MIDIPortDispose(inputPort);
        NSLogError(s, @"Dispose MIDI port");
    }
    
    if (client)
    {
        OSStatus s = MIDIClientDispose(client);
        NSLogError(s, @"Dispose MIDI client");
    }
    
        
    [super dealloc];
}
/* C routines */
#pragma mark C Midi Routines - Not Main Thread
/*
 NOT MAIN THREAD
 */
//A message describing a system state change
static void MIDINotifyMessageProc(const MIDINotification *message, void *refCon)
{
   
    
    
    Midi *self = (Midi*)refCon;   
    
    
    if ([self.delegate respondsToSelector:@selector(midiNotificationReceived)]) 
        [self.delegate performSelectorOnMainThread:@selector(midiNotificationReceived) withObject:nil  waitUntilDone:YES];

    NSValue *m = [NSValue valueWithPointer:message];
    
    
    if ([self.delegate respondsToSelector:@selector(midiNotificationReceivedWithNotification:)]) 
        [self.delegate performSelectorOnMainThread:@selector(midiNotificationReceivedWithNotification:) withObject:m  waitUntilDone:YES];// if NO memory might be released before the target has time to read.
    
    

}
/*
 NOT MAIN THREAD
 */
// entry point from coreMidi when note is pressed on keyboard
static void MIDIReadNoteProc(const MIDIPacketList *packetList, void *readProcRefCon, void *srcConnRefCon)
{
        
    //Midi *self = (Midi*)srcConnRefCon;
    [(Midi*)srcConnRefCon midiReadObjectiveC:packetList];     
           
    
}
// NOTE: Called on a separate high-priority thread, not the main runloop
- (void) midiReadObjectiveC:(const MIDIPacketList *)packetList
{
    BOOL tellDelegateNoteReceived = NO;
    
   
    if (!isOutputPaused)
    {
        
        const MIDIPacket *packet = &packetList->packet[0];
        for (int i = 0; i < packetList->numPackets; ++i)
        {  
                  
            if (![self isTypeFilteredOut:[MidiNote statusToType:packet]]) // only add if not filtered out
            {
                MidiNote *note = [[MidiNote alloc] initWithPacket:packet];             
                
                [notes  addObject:note];                
                [note release];
                
                if ([self.delegate respondsToSelector:@selector(midiNoteReceivedWithNote:)]) 
                    [self.delegate performSelectorOnMainThread:@selector(midiNoteReceivedWithNote:) withObject:note  waitUntilDone:YES];
                
                
                tellDelegateNoteReceived = YES; // at least one note not filtered out so send message after loop
            }
            
            packet = MIDIPacketNext(packet);
            
            
        }
        
        if (tellDelegateNoteReceived)
            if ([self.delegate respondsToSelector:@selector(midiNoteReceived)]) 
                [self.delegate performSelectorOnMainThread:@selector(midiNoteReceived) withObject:nil  waitUntilDone:YES]; //TODO NO can cause SIGABRT?
        
           

     }
    
}


#pragma mark Send Routines
- (void) sendBytes:(const UInt8*)bytes size:(UInt32)size
{
    //NSLog(@"sendBytes:%s(%u bytes to core MIDI)", __func__, unsigned(size));
    assert(size < 65536);
    Byte packetBuffer[size+100];
    MIDIPacketList *packetList = (MIDIPacketList*)packetBuffer;
    MIDIPacket     *packet     = MIDIPacketListInit(packetList);
    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, bytes);
 
    
    [self sendPacketList:packetList];
}

- (void) sendPacketList:(const MIDIPacketList *)packetList
{
    for (ItemCount index = 0; index < MIDIGetNumberOfDestinations(); ++index)
    {
        MIDIEndpointRef outputEndpoint = MIDIGetDestination(index);
        if (outputEndpoint)
        {
            // Send it
            OSStatus s = MIDISend(outputPort, outputEndpoint, packetList);
            NSLogError(s, @"Sending MIDI");
        }
    }
}
#pragma mark Filter Functions
- (void) addFilter:(MidiType)statusType
{
    
    NSNumber *NumberToStore = [NSNumber numberWithInt:statusType];
    
    [filteredNotes addObject:NumberToStore]; 
    
}
- (void) removeFilter:(MidiType)statusType
{
    NSNumber *NumberToStore = [NSNumber numberWithInt:statusType];
    [filteredNotes removeObject:NumberToStore]; 
    
}
// private (internal) to class
-(BOOL) isTypeFilteredOut:(MidiType)statusType
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSNumber *NumberToFind = [NSNumber numberWithInt:statusType] ;    
    
    return [filteredNotes containsObject:NumberToFind];
    
    [pool drain];
    
}
#pragma mark Souce and Destination
-(NSString *)sourceDNSName
{
    const ItemCount numberOfSources  = MIDIGetNumberOfSources();
    NSString *string = nil;
    
    
    if (numberOfSources > 0) // only show first
    {
        MIDIEndpointRef endpoint = MIDIGetSource(0); 
        
        
        
        MIDIEntityRef entity = 0;
        MIDIEndpointGetEntity(endpoint, &entity);
        
        CFPropertyListRef properties = nil;
        OSStatus s = MIDIObjectGetProperties(entity, &properties, true);
        if (s)
        {
            string = @"Unknown name";
        }
        else
        {

            NSDictionary *dictionary = (NSDictionary*)properties;
            string = [NSString stringWithFormat:@"%@", [dictionary valueForKey:@"name"]];
            
            NSDictionary *appleMidiRtpSession = [dictionary valueForKey:@"apple.midirtp.session"];
            string = [NSString stringWithFormat:@"%@", [appleMidiRtpSession valueForKey:@"dns-sd-name"]];
            
            CFRelease(properties);
        }
        
        
    }

     return string;
    
}

-(NSString *)sourceSessionName
{
    const ItemCount numberOfSources  = MIDIGetNumberOfSources();
    NSString *string = nil;
    
    
    if (numberOfSources > 0) // only show first
    {
        MIDIEndpointRef endpoint = MIDIGetSource(0);        
        
        
        MIDIEntityRef entity = 0;
        MIDIEndpointGetEntity(endpoint, &entity);
        
        CFPropertyListRef properties = nil;
        OSStatus s = MIDIObjectGetProperties(entity, &properties, true);
        if (s)
        {
            string = @"Unknown name";
        }
        else
        {
            
            NSDictionary *dictionary = (NSDictionary*)properties;
            string = [NSString stringWithFormat:@"%@", [dictionary valueForKey:@"name"]];
            CFRelease(properties);
        }
      

        
    }
    
    return string;
    
}
-(NSString *)sourceAddress
{
    const ItemCount numberOfSources  = MIDIGetNumberOfSources();
    NSString *string = @"";
    
    
    if (numberOfSources > 0) // only show first
    {
        MIDIEndpointRef endpoint = MIDIGetSource(0);        
        
        
        MIDIEntityRef entity = 0;
        MIDIEndpointGetEntity(endpoint, &entity);
        
        CFPropertyListRef properties = nil;
        OSStatus s = MIDIObjectGetProperties(entity, &properties, true);
        if (s)
        {
            string = @"Unknown name";
        }
        else
        {
            
            NSDictionary *dictionary = (NSDictionary*)properties;
            
            NSDictionary *appleMidiRtpSession = [dictionary valueForKey:@"apple.midirtp.session"];
           // string = [NSString stringWithFormat:@"%@", [appleMidiRtpSession valueForKey:@"dns-sd-name"]];
            NSArray *peers = [appleMidiRtpSession valueForKey:@"peers"];
           if (peers)
               if ([peers count] >0)
                  string = [NSString stringWithFormat:@"%@", [peers objectAtIndex:0]];     
     

            
            
           
            CFRelease(properties);
        }
        
    }
    
    return string;
    
}

-(NSString *)sourceDescription
{
    const ItemCount numberOfSources  = MIDIGetNumberOfSources();
    NSString *string = nil;
    
    
    if (numberOfSources > 0) // only show first
    {
        MIDIEndpointRef endpoint = MIDIGetSource(0); 
        
        
        
        MIDIEntityRef entity = 0;
        MIDIEndpointGetEntity(endpoint, &entity);
        
        CFPropertyListRef properties = nil;
        OSStatus s = MIDIObjectGetProperties(entity, &properties, true);
        if (s)
        {
            string = @"Unknown name";
        }
        else
        {
            string = [NSString stringWithFormat:@"%@", properties];
            
            CFRelease(properties);
        }
        
        
    }
    
    return string;
    
}

-(NSString *)destinationSessionName
{
    const ItemCount numberOfDestinations  = MIDIGetNumberOfDestinations();
    NSString *string = nil;
    
    
    if (numberOfDestinations > 0) // only show first
    {
        MIDIEndpointRef endpoint = MIDIGetDestination(0);        
        
        
        MIDIEntityRef entity = 0;
        MIDIEndpointGetEntity(endpoint, &entity);
        
        CFPropertyListRef properties = nil;
        OSStatus s = MIDIObjectGetProperties(entity, &properties, true);
        if (s)
        {
            string = @"Unknown name";
        }
        else
        {
            
            NSDictionary *dictionary = (NSDictionary*)properties;
            string = [NSString stringWithFormat:@"%@", [dictionary valueForKey:@"name"]];
            CFRelease(properties);
        }
        
        
    }
    
    return string;
    
}

-(NSString *)destinationDNSName
{
    const ItemCount numberOfDestinations      = MIDIGetNumberOfDestinations();
    NSString *string = nil;
    
    
    if (numberOfDestinations > 0) // only show first
    {
        MIDIEndpointRef endpoint = MIDIGetDestination(0); 
        
        MIDIEntityRef entity = 0;
        MIDIEndpointGetEntity(endpoint, &entity);
        
        CFPropertyListRef properties = nil;
        OSStatus s = MIDIObjectGetProperties(entity, &properties, true);
        if (s)
        {
            string = @"Unknown name";
        }
        else
        {
            NSDictionary *dictionary = (NSDictionary*)properties;
            string = [NSString stringWithFormat:@"%@", [dictionary valueForKey:@"name"]];
            
            NSDictionary *appleMidiRtpSession = [dictionary valueForKey:@"apple.midirtp.session"];
            string = [NSString stringWithFormat:@"%@", [appleMidiRtpSession valueForKey:@"dns-sd-name"]];
            
            CFRelease(properties);
        }
        
        
    }
    
    return string;
    
}
-(NSString *)destinationDescription
{
    const ItemCount numberOfDestinations = MIDIGetNumberOfDestinations();
    NSString *string = nil;
    
    
    if (numberOfDestinations > 0) // only show first
    {
        MIDIEndpointRef endpoint = MIDIGetDestination(0); 
        
        MIDIEntityRef entity = 0;
        MIDIEndpointGetEntity(endpoint, &entity);
        
        CFPropertyListRef properties = nil;
        OSStatus s = MIDIObjectGetProperties(entity, &properties, true);
        if (s)
        {
            string = @"Unknown name";
        }
        else
        {
            string = [NSString stringWithFormat:@"%@", properties];
            
            CFRelease(properties);
        }
        
        
    }
    
    return string;
    
}


@end
