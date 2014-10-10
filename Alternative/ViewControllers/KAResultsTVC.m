//
//  KAResultsTVC.m
//  Alternative
//
//  Created by Kausi Ahmed on 7/6/14.
//
//

#import "KAResultsTVC.h"
#import "KASectionModel.h"
#import "KAAppDelegate.h"
#import "Meeting.h"

@interface KAResultsTVC ()

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSMutableArray *sectionZero;
@property (nonatomic) NSMutableArray *sectionOne;
@property (nonatomic) NSMutableArray *sectionTwo;

@property (nonatomic) NSArray *sectionModels;
@property (nonatomic) NSMutableDictionary *sectionMap;

@end

@implementation KAResultsTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!self.managedObjectContext) [self getManagedObjectContext];
    [self refreshData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext];

}

- (void)handleDataModelChange:(NSNotification *)notification
{
    NSSet *updatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
    NSSet *deletedObjects = [[notification userInfo] objectForKey:NSDeletedObjectsKey];
    NSSet *insertedObjects = [[notification userInfo] objectForKey:NSInsertedObjectsKey];
    
    NSLog(@"updatedObjects %@", updatedObjects);
    NSLog(@"deletedObjects %@", deletedObjects);
    NSLog(@"insertedObject %@", insertedObjects);
}

- (void)refreshData
{
    [self fetchTodaysObjects];
    [self fetchUpcomingObjects];
    [self fetchPastObjects];
    [self processSectionData];
}

- (NSManagedObjectContext *)getManagedObjectContext {
    KAAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    return self.managedObjectContext;
}
- (IBAction)navButtonAddDataTapped:(id)sender
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
    
    for (int i = -30; i<30; i++)
    {
        Meeting *meeting = [NSEntityDescription
                            insertNewObjectForEntityForName:@"Meeting"
                            inManagedObjectContext:self.managedObjectContext];
        
        [components setDay:-i];
        startDate = [cal dateByAddingComponents:components toDate:today options:0];
        meeting.startDate = startDate;
        meeting.title = [formatter stringFromDate:startDate];
        
    }
    BOOL save = [self.managedObjectContext save:nil];
    if (!save) NSLog(@"There was an Error saving to Core Data in RootVC");
    if (save)
    {
        NSLog(@"New Datasaved");
        [self refreshData];

    }

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.sectionModels count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"RowsInSection %i", [((KASectionModel *)self.sectionModels[section]).rowModels count]);
    return [((KASectionModel *)self.sectionModels[section]).rowModels count];;
}


- (void)fetchTodaysObjects
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Meeting" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *firstSort = [[NSSortDescriptor alloc] initWithKey:@"startDate"
                                                              ascending:YES];
    [fetchRequest setSortDescriptors:@[firstSort]];
    
    NSPredicate *subPredToday = [NSPredicate predicateWithFormat:@"(startDate >= %@) AND (startDate <= %@)", [self beginningOfDay], [self endOfDay]];
    [fetchRequest setPredicate:subPredToday];
    
    NSError *error;
    
    if(!self.sectionZero)
    {
        self.sectionZero = [[NSMutableArray alloc]init];
    } else ([self.sectionZero removeAllObjects]);
    
    self.sectionZero = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy];

}

-(void)fetchUpcomingObjects
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Meeting"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *firstSort = [[NSSortDescriptor alloc] initWithKey:@"startDate"
                                                              ascending:YES];
    [fetchRequest setSortDescriptors:@[firstSort]];
    
    NSPredicate *subPredFuture = [NSPredicate predicateWithFormat:@"startDate > %@", [self endOfDay]];
    [fetchRequest setPredicate:subPredFuture];
    
    NSError *error;
    
    if(!self.sectionOne)
    {
        self.sectionOne = [[NSMutableArray alloc]init];
    } else ([self.sectionOne removeAllObjects]);
    
    self.sectionOne = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy];
}

-(void)fetchPastObjects
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Meeting"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *firstSort = [[NSSortDescriptor alloc] initWithKey:@"startDate"
                                                              ascending:YES];
    
    [fetchRequest setSortDescriptors:@[firstSort]];
    
    NSPredicate *subPredPast = [NSPredicate predicateWithFormat:@"startDate < %@", [self beginningOfDay]];
    [fetchRequest setPredicate:subPredPast];
    
    NSError *error;
    
    if(!self.sectionTwo)
    {
        self.sectionTwo = [[NSMutableArray alloc]init];
    } else ([self.sectionTwo removeAllObjects]);
    
    self.sectionTwo = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy];
}

#pragma mark - Process Dates
- (NSDate *)beginningOfDay
{
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:now];
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    int timeZoneOffset = [destinationTimeZone secondsFromGMTForDate:now] / 3600;
    [components setHour:timeZoneOffset];
    [components setMinute:0];
    [components setSecond:0];
    NSDate *beginningOfDay = [calendar dateFromComponents:components];
    
    return beginningOfDay;
}

- (NSDate *)endOfDay
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *components = [NSDateComponents new];
    components.day = 1;
    
    NSDate *endOfDay = [calendar dateByAddingComponents:components
                                                 toDate:[self beginningOfDay]
                                                options:0];
    
    endOfDay = [endOfDay dateByAddingTimeInterval:-1];
    return endOfDay;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    Meeting *rowTitle= ((KASectionModel *)self.sectionModels[indexPath.section]).rowModels[indexPath.row];
    cell.textLabel.text = rowTitle.title;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    KASectionModel *array =self.sectionModels[section];
    return  array.sectionTitle;
}


-(void)processSectionData
{
    NSArray *sectionsArray = @[self.sectionZero, self.sectionOne, self.sectionTwo];
    NSArray *sectionTitles = @[@"Today", @"Upcoming", @"Past"];
    NSMutableArray *mutableSectionModels = [NSMutableArray array];
    
    [sectionsArray enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger index, BOOL *stop)
     {
         if ([array count]>0)
         {
             KASectionModel *sectionModel = [[KASectionModel alloc]init];
             sectionModel.rowModels = array;
             sectionModel.sectionTitle = sectionTitles[index];
             sectionModel.tag = index+1; // track this to enable re-ordering in the future
             [mutableSectionModels addObject:sectionModel];
         }
     }];
    
    self.sectionModels = [mutableSectionModels copy];
    
    [self.tableView reloadData];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];

    
}




@end
