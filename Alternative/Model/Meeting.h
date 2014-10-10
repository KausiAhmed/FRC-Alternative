//
//  Meeting.h
//  Alternative
//
//  Created by Kausi Ahmed on 7/6/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Meeting : NSManagedObject

@property (nonatomic, retain) NSString * sectionIdentifier;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSString * title;

@end
