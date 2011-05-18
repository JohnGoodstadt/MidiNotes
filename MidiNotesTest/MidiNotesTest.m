//
//  MidiNotesTest.m
//  MidiNotesTest
//
//  Created by john goodstadt on 18/05/2011.
//  Copyright 2011John Goodstadt. All rights reserved.
//

#import "MidiNotesTest.h"
#import "midi.h"

@implementation MidiNotesTest

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
    STAssertEqualObjects([MidiNote noteNumberToNoteName:60],  @"C ", @"noteNumberToNoteName 60 is not 'C '");
    STAssertEqualObjects([MidiNote noteNumberToNoteName:61],  @"C#", @"noteNumberToNoteName 60 is not 'C#'");
    STAssertEqualObjects([MidiNote noteNumberToNoteName:0],   @"C ", @"noteNumberToNoteName");
    STAssertEqualObjects([MidiNote noteNumberToNoteName:1],   @"C#", @"noteNumberToNoteName");
    STAssertEqualObjects([MidiNote noteNumberToNoteName:127], @"G ", @"noteNumberToNoteName");
    STAssertEqualObjects([MidiNote noteNumberToNoteName:128], @"G ", @"noteNumberToNoteName");
    STAssertEqualObjects([MidiNote noteNumberToNoteName:5000],@"G ", @"noteNumberToNoteName");
    STAssertEqualObjects([MidiNote noteNumberToNoteName:-1],  @"C ", @"noteNumberToNoteName");
    
    STAssertTrue([MidiNote noteNumberToOctave:60] == 4, @"noteNumberToOctave");
    STAssertTrue([MidiNote noteNumberToOctave:61] == 4, @"noteNumberToOctave");
    
    STAssertTrue([MidiNote noteNumberToOctave:12] == 0, @"noteNumberToOctave");
    STAssertTrue([MidiNote noteNumberToOctave:0] == -1, @"noteNumberToOctave");
    STAssertTrue([MidiNote noteNumberToOctave:-10] == -1, @"noteNumberToOctave invalid number");
    
    STAssertTrue([MidiNote noteNumberToOctave:127] == 9, @"noteNumberToOctave");
    STAssertTrue([MidiNote noteNumberToOctave:128] == 9, @"noteNumberToOctave");
    STAssertTrue([MidiNote noteNumberToOctave:5000] == 9, @"noteNumberToOctave");
    
    STAssertEqualObjects([MidiNote noteNumberToString:60],  @"C 4", @"noteNumberToString");
    STAssertEqualObjects([MidiNote noteNumberToString:61],  @"C#4", @"noteNumberToString");
    
    STAssertEqualObjects([MidiNote noteNumberToString:0],  @"C -1", @"noteNumberToString");
    STAssertEqualObjects([MidiNote noteNumberToString:12],  @"C 0", @"noteNumberToString");
    STAssertEqualObjects([MidiNote noteNumberToString:127],  @"G 9", @"noteNumberToString");
    STAssertEqualObjects([MidiNote noteNumberToString:128],  @"G 9", @"noteNumberToString");
    STAssertEqualObjects([MidiNote noteNumberToString:10000], @"G 9", @"noteNumberToString");
    
    
    
    const UInt8 note      = 60;
    const UInt8 noteOn[]  = { 0x90, note, 127 };
    const UInt8 noteOff[] = { 0x8F, note, 0   }; 
    
    
    UInt32 size = sizeof(noteOn);
    
    Byte packetBuffer[size+100];
    MIDIPacketList *packetList = (MIDIPacketList*)packetBuffer;
    MIDIPacket     *packet     = MIDIPacketListInit(packetList);
    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, noteOn);
    
    
    STAssertTrue([MidiNote statusToType:packet ] == 1,@"MidiNote statusToType - Note On");
    STAssertTrue([MidiNote packetToChannelNumber:packet ] == 1,@"MidiNote packetToChannelNumber");
    
    STAssertEqualObjects([MidiNote stringFromMIDIPacket:packet], @"90 3C 7F C 4 Note On", @"stringFromMIDIPacket");
    
    
    
    packet  = MIDIPacketListInit(packetList);
    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, noteOff);
    
    STAssertTrue([MidiNote statusToType:packet ] == 0,@"MidiNote statusToType - Note Off");
    STAssertTrue([MidiNote packetToChannelNumber:packet ] == 16,@"MidiNote packetToChannelNumber");
    STAssertEqualObjects([MidiNote stringFromMIDIPacket:packet], @"8F 3C 00 C 4 Note Off", @"stringFromMIDIPacket");
    

}

@end
