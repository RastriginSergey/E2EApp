//
//  EventsTableViewController.m
//  NexmoTestApp
//
//  Created by Nicola Di Pol on 20/12/2019.
//  Copyright © 2019 Vonage. All rights reserved.
//

#import "EventsTableViewController.h"
#import "NXMHelper.h"

static NSUInteger const EVENTS_PAGE_SIZE = 50;
static NSString *const EVENT_TYPE_FILTER = nil; // E.g.: @"text", @"image" etc.
static NSString *const EVENT_REUSE_ID = @"eventReuseId";
static NSString *const EVENTS_TITLE_FORMAT = @"Events [%@]";

@interface EventsTableViewController ()

@property (nonatomic, assign) NXMPageOrder order;
@property (nonatomic, nullable) NXMEventsPage *eventsPage;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *previousPageButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toggleOrderButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *nextPageButton;
@property UIActivityIndicatorView *activityIndicatorView;

@end

@implementation EventsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    self.tableView.allowsSelection = NO;
    UIView *tableViewFooter = [UIView new];
    tableViewFooter.backgroundColor = UIColor.whiteColor;
    self.tableView.tableFooterView = tableViewFooter;

    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

    self.order = NXMPageOrderAsc;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self cleanAndGetEventsPage];
}

- (IBAction)previousPageButtonPressed:(UIBarButtonItem *)sender {
    if ([self.eventsPage hasPreviousPage]) {
        [self showActivityIndicatorView];

        __weak EventsTableViewController *weakSelf = self;
        [self.eventsPage previousPage:^(NSError * _Nullable error, NXMEventsPage * _Nullable page) {
            [weakSelf showPage:(error || !page) ? nil : page];
        }];
    } else {
        NSLog(@"❌ This is the FIRST page: no previous page available! ❌");
    }
}

- (IBAction)toggleOrderButtonPressed:(UIBarButtonItem *)sender {
    [self toggleOrder];
    [self cleanAndGetEventsPage];
}

- (IBAction)nextPageButtonPressed:(UIBarButtonItem *)sender {
    if ([self.eventsPage hasNextPage]) {
        [self showActivityIndicatorView];

        __weak typeof(self) weakSelf = self;
        [self.eventsPage nextPage:^(NSError * _Nullable error, NXMEventsPage * _Nullable page) {
            [weakSelf showPage:(error || !page) ? nil : page];
        }];
    } else {
        NSLog(@"❌ This is the LAST page: no next page available! ❌");
    }
}

- (void)showActivityIndicatorView {
    self.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    self.activityIndicatorView.hidden = NO;
    self.activityIndicatorView.hidesWhenStopped = NO;
    [self.view addSubview: self.activityIndicatorView];
    [self.view bringSubviewToFront:self.activityIndicatorView];
    [NSLayoutConstraint activateConstraints:@[
        [self.activityIndicatorView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.activityIndicatorView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
    [self.activityIndicatorView startAnimating];
}

- (void)hideActivityIndicatorView {
    [self.activityIndicatorView stopAnimating];
    [self.activityIndicatorView removeFromSuperview];
}

- (void)getEventsPage {
    [self showActivityIndicatorView];

    __weak EventsTableViewController *weakSelf = self;
    [self.conversation getEventsPageWithSize:EVENTS_PAGE_SIZE
                                       order:self.order
                           completionHandler:^(NSError * _Nullable error, NXMEventsPage * _Nullable page) {
                               [weakSelf showPage:(error || !page) ? nil : page];
                           }];
}

- (void)cleanAndGetEventsPage {
    __weak EventsTableViewController *weakSelf = self;
    [self showPage:nil completion:^{
        [weakSelf getEventsPage];
    }];
}

- (void)showPage:(nullable NXMEventsPage *)page {
    [self showPage:page completion:nil];
}

- (void)showPage:(nullable NXMEventsPage *)page completion:(void(^_Nullable)(void))completion {
    NSString *orderString = self.order == NXMPageOrderAsc ? @"ASC" : @"DESC";
    self.eventsPage = page;
    BOOL isThereAtLeastOneEvent = self.eventsPage.events.count > 0;
    __weak EventsTableViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.navigationItem.title = [NSString stringWithFormat:EVENTS_TITLE_FORMAT, orderString];
        [weakSelf.tableView reloadData];
        if (isThereAtLeastOneEvent) {
            [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                      atScrollPosition:UITableViewScrollPositionTop
                                              animated:YES];
        }

        [weakSelf hideActivityIndicatorView];

        if (completion) {
            completion();
        }
    });
}

- (void)toggleOrder {
    self.order = self.order == NXMPageOrderAsc ? NXMPageOrderDesc : NXMPageOrderAsc;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
    NSArray<NXMEvent *> *events = self.eventsPage.events;
    return events ? events.count : 0;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: EVENT_REUSE_ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle
                                      reuseIdentifier: EVENT_REUSE_ID];
    }
    cell.textLabel.numberOfLines = 0;
    NXMEvent *event = self.eventsPage.events[indexPath.row];
    NSString *eventTypeDescription = [NXMHelper descriptionForEventType:event.type];
    cell.textLabel.text = [NSString stringWithFormat:@"ID: %li\nType: %@ %@",
                           (long)event.uuid, eventTypeDescription, event.description];
    return cell;
}

@end
