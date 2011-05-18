//
//  midi.h
//  Sibelius
//
//  Created by john goodstadt on 05/05/2011.
//  Copyright 2011 John Goodstadt. All rights reserved.
//  Use this file in your own projects as you see fit.
//  Please email me at john@goodstadt.me.uk for any problems, fixes, addition or thanks.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

@class Midi;
@class MidiNote;

#define IF_IOS_HAS_COREMIDI if([[[UIDevice currentDevice] systemVersion] floatValue] >= 4.19)

@protocol MidiDelegate

// Raised on main run loop
/// NOTE: Raised on high-priority background thread.

@optional
- (void) midiNoteReceived;
- (void) midiNoteReceivedWithNote:(MidiNote *)note;
- (void) midiNotificationReceived;
- (void) midiNotificationReceivedWithNotification:(NSValue *)message;

@end
/* if adding to here also add to MidiType_toString in .m file */
typedef enum {
    kNoteOff,
    kNoteOn,
    kActiveSensing,
    kAfterTouch,
    kControlChange,
    kProgramChange,
    kChannelPressure,
    kPitchWheel,
    kUndefined
} MidiType;

@interface MidiNote : NSObject {
 
    const MIDIPacket *packet;
   
    MIDITimeStamp		timeStamp; /*UInt64*/
    UInt8 status;
    UInt8 data1;
    UInt8 data2;
    UInt8 channel;
    
    MidiType statusType;
    

    NSString *NoteName;
    NSString *statusTypeDescription;
    
}
@property (assign)   const MIDIPacket *packet;
@property (assign)   MIDITimeStamp timeStamp;
@property (assign)   UInt8 status;
@property (assign)   UInt8 data1;
@property (assign)   UInt8 data2;
@property (assign)   UInt8 channel;
@property (assign)   MidiType statusType;
@property (nonatomic,retain)   NSString *statusTypeDescription;

-(NSString *) name;
-(int) octave;
-(UInt8) number;
-(NSString *) description;

+(MidiType ) statusToType:(const MIDIPacket *)packet;
+(UInt8) packetToChannelNumber:(const MIDIPacket *) packet;
+(NSString *) stringFromMIDIPacket:(const MIDIPacket *) packet;
+(UInt8) noteNumberFromMIDIPacket:(const MIDIPacket *) packet;
+(UInt8) octaveFromMIDIPacket:(const MIDIPacket *) packet;

+(NSString *)noteNumberToNoteName:(int)noteNumber;
+(int)       noteNumberToOctave:(int)noteNumber;
+(NSString *)noteNumberToString:(int)noteNumber;
@end


@interface Midi : NSObject {
    
    MIDIClientRef      client;
    MIDIPortRef        outputPort;
    MIDIPortRef        inputPort;
    
    BOOL isOutputPaused;
    NSMutableArray *notes;
    NSMutableSet *filteredNotes;
    
    NSObject<MidiDelegate>*delegate;

}
@property (nonatomic,assign)   NSObject <MidiDelegate>*delegate;
@property (nonatomic,retain)   NSMutableArray *notes;
@property (nonatomic,retain)   NSMutableSet *filteredNotes;
@property (assign) BOOL isOutputPaused;


// avoid compile errors
-(void) sendBytes:(const UInt8*)bytes size:(UInt32)size;
-(void) sendPacketList:(const MIDIPacketList *)packetList;
-(void) midiReadObjectiveC:(const MIDIPacketList *)packetList;
-(void) addFilter:(MidiType)statusType;
-(void) removeFilter:(MidiType)statusType;
-(BOOL) isTypeFilteredOut:(MidiType)statusType; // private routine
-(NSString *)sourceDNSName;
-(NSString *)sourceSessionName;
-(NSString *)sourceDescription;
-(NSString *)sourceAddress;
-(NSString *)destinationDNSName;
-(NSString *)destinationSessionName;
-(NSString *)destinationDescription;
@end

