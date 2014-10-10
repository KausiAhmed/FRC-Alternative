//
//  KARootVC.m
//  Alternative
//
//  Created by Kausi Ahmed on 7/6/14.
//
//

#import "KARootVC.h"
#import "Meeting.h"
#import "KAAppDelegate.h"

@interface KARootVC ()
@property (nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation KARootVC

- (NSManagedObjectContext *)getManagedObjectContext
{
    KAAppDelegate *appDelegate = (KAAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    return self.managedObjectContext;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.managedObjectContext)
    {
        [self getManagedObjectContext];
    }
}

- (IBAction)buttonGenerateDataTapped:(UIButton *)sender
{
    [self generateDataToStore];
}

- (void)generateDataToStore
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    
    NSDate *date = [NSDate date];
    NSDateComponents *comps = [cal components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                     fromDate:date];
    NSDate *today = [cal dateFromComponents:comps];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    
    NSDate *startDate;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    
    
    
    for (int i = -30; i<20; i++)
    {
        Meeting *meeting = [NSEntityDescription
                            insertNewObjectForEntityForName:@"Meeting"
                            inManagedObjectContext:self.managedObjectContext];
        
        [components setDay:-i];
        startDate = [cal dateByAddingComponents:components toDate:today options:0];
        meeting.startDate = startDate;
        meeting.title = [formatter stringFromDate:startDate];
        NSLog(@"Meeting.StartDate: %@", meeting.startDate);
        NSLog(@"Meeting.Title: %@", meeting.title);
    }
    BOOL save = [self.managedObjectContext save:nil];
    if (!save) NSLog(@"There was an Error saving to Core Data in RootVC");
}

@end
