// 
// Copyright (c) 2010 Eric Czarny <eczarny@gmail.com>
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of  this  software  and  associated documentation files (the "Software"), to
// deal  in  the Software without restriction, including without limitation the
// rights  to  use,  copy,  modify,  merge,  publish,  distribute,  sublicense,
// and/or sell copies  of  the  Software,  and  to  permit  persons to whom the
// Software is furnished to do so, subject to the following conditions:
// 
// The  above  copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE  SOFTWARE  IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED,  INCLUDING  BUT  NOT  LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS  OR  COPYRIGHT  HOLDERS  BE  LIABLE  FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY,  WHETHER  IN  AN  ACTION  OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
// 

//
// Test Client
// TestClientXMLParserWindowController.m
//
// Created by Eric Czarny on Thursday, July 9, 2009.
// Copyright (c) 2010 Divisible by Zero.
//

#import "TestClientXMLParserWindowController.h"
#import "XMLRPCEventBasedParser.h"

@interface TestClientXMLParserWindowController (TestClientXMLParserWindowControllerPrivate)

- (NSString *)typeForItem: (id)item;

@end

#pragma mark -

@implementation TestClientXMLParserWindowController

static TestClientXMLParserWindowController *sharedInstance = nil;

- (id)init {
    if (self = [super initWithWindowNibName: @"TestClientXMLParserWindow"]) {
        myParsedObject = nil;
    }
    
    return self;
}

#pragma mark -

+ (id)allocWithZone: (NSZone *)zone {
    @synchronized(self) {
        if (!sharedInstance) {
            sharedInstance = [super allocWithZone: zone];
            
            return sharedInstance;
        }
    }
    
    return nil;
}

#pragma mark -

+ (TestClientXMLParserWindowController *)sharedController {
    @synchronized(self) {
        if (!sharedInstance) {
            [[self alloc] init];
        }
    }
    
    return sharedInstance;
}

#pragma mark -

- (void)awakeFromNib {
    [[self window] center];
}

#pragma mark -

- (void)showXMLParserWindow: (id)sender {
    [self showWindow: sender];
}

- (void)hideXMLParserWindow: (id)sender {
    [self close];
}

#pragma mark -

- (void)toggleXMLParserWindow: (id)sender {
    if ([[self window] isKeyWindow]) {
        [self hideXMLParserWindow: sender];
    } else {
        [self showXMLParserWindow: sender];
    }
}

#pragma mark -

- (void)parse: (id)sender {
    NSData *data = [[myXML string] dataUsingEncoding: NSUTF8StringEncoding];
    XMLRPCEventBasedParser *parser = (XMLRPCEventBasedParser *)[[XMLRPCEventBasedParser alloc] initWithData: data];
    
    if (!parser) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        
        [alert addButtonWithTitle: @"OK"];
        [alert setMessageText: @"The parser encountered an error."];
        [alert setInformativeText: @"There was a problem creating the XML parser."];
        [alert setAlertStyle: NSCriticalAlertStyle];
        
        [alert runModal];
        
        return;
    }
    
    [myParsedObject release];
    
    myParsedObject = [[parser parse] retain];
    
    NSError *parserError = [[[parser parserError] retain] autorelease];
    
    [parser release];
    
    if (!myParsedObject) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        
        [alert addButtonWithTitle: @"OK"];
        [alert setMessageText: @"The parser encountered an error."];
        [alert setInformativeText: [parserError localizedDescription]];
        [alert setAlertStyle: NSCriticalAlertStyle];
        
        [alert runModal];
        
        return;
    }
    
    [myParserResult reloadData];
}

#pragma mark -

#pragma mark Outline View Data Source Methods

#pragma mark -

- (id)outlineView: (NSOutlineView *)outlineView child: (NSInteger)index ofItem: (id)item {
    if (item == nil) {
        item = myParsedObject;
    }
    
    if ([item isKindOfClass: [NSDictionary class]]) {
        return [item objectForKey: [[item allKeys] objectAtIndex: index]];
    } else if ([item isKindOfClass: [NSArray class]]) {
        return [item objectAtIndex: index];
    }
    
    return item;
}

- (BOOL)outlineView: (NSOutlineView *)outlineView isItemExpandable: (id)item {
    if ([item isKindOfClass: [NSDictionary class]] || [item isKindOfClass: [NSArray class]]) {
        if ([item count] > 0) {
            return YES;
        }
    }
    
    return NO;
}

- (NSInteger)outlineView: (NSOutlineView *)outlineView numberOfChildrenOfItem: (id)item {
    if (item == nil) {
        item = myParsedObject;
    }
    
    if ([item isKindOfClass: [NSDictionary class]] || [item isKindOfClass: [NSArray class]]) {
        return [item count];
    } else if (item != nil) {
        return 1;
    }
    
    return 0;
}

- (id)outlineView: (NSOutlineView *)outlineView objectValueForTableColumn: (NSTableColumn *)tableColumn byItem: (id)item {
    NSString *columnIdentifier = (NSString *)[tableColumn identifier];
    
    if ([columnIdentifier isEqualToString: @"type"]) {
        id parentObject = [outlineView parentForItem: item] ? [outlineView parentForItem: item] : myParsedObject;
        
        if ([parentObject isKindOfClass: [NSDictionary class]]) {
            return [NSString stringWithFormat: @"\"%@\", %@", [[parentObject allKeysForObject: item] objectAtIndex: 0], [self typeForItem: item]];
        } else if ([parentObject isKindOfClass: [NSArray class]]) {
            return [NSString stringWithFormat: @"Item %d, %@", [parentObject indexOfObject: item], [self typeForItem: item]];
        } else {
            return [self typeForItem: item];
        }
    } else {
        if ([item isKindOfClass: [NSDictionary class]] || [item isKindOfClass: [NSArray class]]) {
            return [NSString stringWithFormat: @"%d items", [item count]];
        } else {
            return [NSString stringWithFormat: @"\"%@\"", item];
        }
    }
    
    return nil;
}

@end

#pragma mark -

@implementation TestClientXMLParserWindowController (TestClientXMLParserWindowControllerPrivate)

- (NSString *)typeForItem: (id)item {
    NSString *type;
    
    if ([item isKindOfClass: [NSArray class]]) {
        type = @"Array";
    } else if ([item isKindOfClass: [NSDictionary class]]) {
        type = @"Dictionary";
    } else if ([item isKindOfClass: [NSString class]]) {
        type = @"String";
    } else if ([item isKindOfClass: [NSNumber class]]) {
        type = @"Number";
    } else if ([item isKindOfClass: [NSDate class]]) {
        type = @"Date";
    } else if ([item isKindOfClass: [NSData class]]) {
        type = @"Data";
    } else {
        type = @"Object";
    }
    
    return type;
}

@end
