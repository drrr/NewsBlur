//
//  AddSiteViewController.m
//  NewsBlur
//
//  Created by Samuel Clay on 10/31/10.
//  Copyright 2010 NewsBlur. All rights reserved.
//

#import "AddSiteViewController.h"
#import "AddSiteAutocompleteCell.h"
#import "NewsBlurAppDelegate.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "NBContainerViewController.h"
#import "JSON.h"

@interface AddSiteViewController()

@property (nonatomic) NSString *activeTerm_;
@property (nonatomic, strong) NSMutableDictionary *searchResults_;

@end

@implementation AddSiteViewController

@synthesize appDelegate;
@synthesize inFolderInput;
@synthesize addFolderInput;
@synthesize siteAddressInput;
@synthesize addButton;
@synthesize cancelButton;
@synthesize folderPicker;
@synthesize siteTable;
@synthesize siteScrollView;
@synthesize jsonString;
@synthesize autocompleteResults;
@synthesize navBar;
@synthesize activityIndicator;
@synthesize siteActivityIndicator;
@synthesize addingLabel;
@synthesize errorLabel;
@synthesize addTypeControl;
@synthesize activeTerm_;
@synthesize searchResults_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    }
    return self;
}

- (void)viewDidLoad {    
    UIImageView *folderImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"folder.png"]];
    [inFolderInput setLeftView:folderImage];
    [inFolderInput setLeftViewMode:UITextFieldViewModeAlways];
    UIImageView *folderImage2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"folder.png"]];
    [addFolderInput setLeftView:folderImage2];
    [addFolderInput setLeftViewMode:UITextFieldViewModeAlways];
    
    UIImageView *urlImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"world.png"]];
    [siteAddressInput setLeftView:urlImage];
    [siteAddressInput setLeftViewMode:UITextFieldViewModeAlways];
    
    navBar.tintColor = [UIColor colorWithRed:0.16f green:0.36f blue:0.46 alpha:0.9];
    
    addFolderInput.frame = CGRectMake(self.view.frame.size.width, 
                                      siteAddressInput.frame.origin.y, 
                                      siteAddressInput.frame.size.width, 
                                      siteAddressInput.frame.size.height);
    
    self.activeTerm_ = @"";
    self.searchResults_ = [[NSMutableDictionary alloc] init];
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.errorLabel setHidden:YES];
    [self.addingLabel setHidden:YES];
    [self.folderPicker setHidden:YES];
    [self.siteScrollView setAlpha:0];
    [self.activityIndicator stopAnimating];
    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        return YES;
    }
    
    return NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [self.activityIndicator stopAnimating];
    [super viewDidAppear:animated];
    [self showFolderPicker];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.siteTable.hidden = NO;
        self.siteScrollView.frame = CGRectMake(self.siteScrollView.frame.origin.x,
                                           self.siteScrollView.frame.origin.y,
                                           320,
                                           295);
    }
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
	// Release any cached data, images, etc that aren't in use.
}


- (IBAction)doCancelButton {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [appDelegate.masterContainerViewController hidePopover];
    } else {
        [appDelegate.addSiteViewController dismissModalViewControllerAnimated:YES];
        
    }
}

- (IBAction)doAddButton {
    if ([self.addTypeControl selectedSegmentIndex] == 0) {
        return [self addSite];
    } else {
        return [self addFolder];
    }
}

- (void)reload {
    [inFolderInput setText:@""];
    [siteAddressInput setText:@""];
    [addFolderInput setText:@""];
    [folderPicker reloadAllComponents];
    
    folderPicker.frame = CGRectMake(0, self.view.bounds.size.height, 
                                    folderPicker.frame.size.width, 
                                    folderPicker.frame.size.height);
}

#pragma mark -
#pragma mark Add Site

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [errorLabel setText:@""];
    if (textField == inFolderInput && ![inFolderInput isFirstResponder]) {
        [self showFolderPicker];
        return NO;
    } else if (textField == siteAddressInput) {
        [self hideFolderPicker];
    } else if (textField == addFolderInput) {
        [self hideFolderPicker];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == inFolderInput) {
        
    } else if (textField == siteAddressInput) {
        if (siteAddressInput.returnKeyType == UIReturnKeySearch) {
            [self checkSiteAddress];
        } else {
            [self addSite];            
        }
    } else if (textField == addFolderInput) {
        [self addFolder];
    }
	return YES;
}

- (IBAction)checkSiteAddress {
    NSString *phrase = siteAddressInput.text;
    
    if ([phrase length] == 0) {
        [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionAllowUserInteraction 
                         animations:^{
                             [siteScrollView setAlpha:0];
                         } completion:nil];
        return;
    }
    
    if ([self.searchResults_ objectForKey:phrase]) {
        self.autocompleteResults = [self.searchResults_ objectForKey:phrase];
        [self reloadSearchResults];
        return;
    }
    
    int periodLoc = [phrase rangeOfString:@"."].location;
    if (periodLoc != NSNotFound && siteAddressInput.returnKeyType != UIReturnKeyDone) {
        // URL
        [siteAddressInput setReturnKeyType:UIReturnKeyDone];
        [siteAddressInput resignFirstResponder];
        [siteAddressInput becomeFirstResponder];
    } else if (periodLoc == NSNotFound && siteAddressInput.returnKeyType != UIReturnKeySearch) {
        // Search
        [siteAddressInput setReturnKeyType:UIReturnKeySearch];
        [siteAddressInput resignFirstResponder];
        [siteAddressInput becomeFirstResponder];
    }
    
    [self.siteActivityIndicator startAnimating];
    NSString *urlString = [NSString stringWithFormat:@"http://%@/rss_feeds/feed_autocomplete?term=%@&v=2",
                           NEWSBLUR_URL, [phrase stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(autocompleteSite:)];
    [request startAsynchronous];
}

- (void)autocompleteSite:(ASIHTTPRequest *)request {
    NSString *responseString = [request responseString];
    NSData *responseData=[responseString dataUsingEncoding:NSUTF8StringEncoding];    
    NSError *error;
    NSDictionary *results = [NSJSONSerialization 
                             JSONObjectWithData:responseData
                             options:kNilOptions 
                             error:&error];
    

    NSString *query = [NSString stringWithFormat:@"%@", [results objectForKey:@"term"]];
    NSString *phrase = siteAddressInput.text;
    
    // cache the results
    [self.searchResults_ setValue:[results objectForKey:@"feeds"] forKey:query];

    if ([phrase isEqualToString:query]) {
        self.autocompleteResults = [results objectForKey:@"feeds"];
        [self reloadSearchResults];       
    }
    
//    NSRange range = [query rangeOfString : activeTerm_];
//    BOOL found = (range.location != NSNotFound);
}

- (void)reloadSearchResults {
    if ([siteAddressInput.text length] > 0 && [autocompleteResults count] > 0) {
        [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionAllowUserInteraction 
                         animations:^{
                             [siteScrollView setAlpha:1];
                         } completion:nil];
    } else {
        [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionAllowUserInteraction 
                         animations:^{
                             [siteScrollView setAlpha:0];
                         } completion:nil];
    }
    
    [self.siteActivityIndicator stopAnimating];
    self.siteTable.hidden = NO;
    [siteTable reloadData];
}

- (IBAction)addSite {
    [self hideFolderPicker];
    self.siteTable.hidden = YES;
    [siteAddressInput resignFirstResponder];
    [self.addingLabel setHidden:NO];
    [self.addingLabel setText:@"Adding site..."];
    [self.errorLabel setHidden:YES];
    [self.activityIndicator startAnimating];
    NSString *urlString = [NSString stringWithFormat:@"http://%@/reader/add_url",
                           NEWSBLUR_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    NSString *parent_folder = [self extractParentFolder];
    [request setPostValue:parent_folder forKey:@"folder"]; 
    [request setPostValue:[siteAddressInput text] forKey:@"url"]; 
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(requestFinished:)];
    [request setDidFailSelector:@selector(requestFailed:)];
    [request setTimeOutSeconds:30];
    [request startAsynchronous];
}


- (void)requestFinished:(ASIHTTPRequest *)request {
    [self.addingLabel setHidden:YES];
    [self.activityIndicator stopAnimating];
    NSString *responseString = [request responseString];
    NSDictionary *results = [[NSDictionary alloc] 
                             initWithDictionary:[responseString JSONValue]];
    // int statusCode = [request responseStatusCode];
    int code = [[results valueForKey:@"code"] intValue];
    if (code == -1) {
        [self.errorLabel setText:[results valueForKey:@"message"]];   
        [self.errorLabel setHidden:NO];
    } else {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [appDelegate.masterContainerViewController hidePopover];
        } else {
            [appDelegate.addSiteViewController dismissModalViewControllerAnimated:YES];
            
        }
        [appDelegate reloadFeedsView:NO];
    }
    
}

- (NSString *)extractParentFolder {
    NSString *parent_folder = [inFolderInput text];
    int folder_loc = [parent_folder rangeOfString:@" - " options:NSBackwardsSearch].location;
    if ([parent_folder length] && folder_loc != NSNotFound) {
        parent_folder = [parent_folder substringFromIndex:(folder_loc + 3)];
    }
    return parent_folder;
}

#pragma mark -
#pragma mark Add Folder


- (IBAction)addFolder {
    [self hideFolderPicker];
    [addFolderInput resignFirstResponder];
    [self.addingLabel setHidden:NO];
    [self.addingLabel setText:@"Adding Folder..."];
    [self.errorLabel setHidden:YES];
    [self.activityIndicator startAnimating];
    NSString *urlString = [NSString stringWithFormat:@"http://%@/reader/add_folder",
                           NEWSBLUR_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    NSString *parent_folder = [self extractParentFolder];
    if (![parent_folder isEqualToString:@"- Top Level -"]) {
        [request setPostValue:parent_folder forKey:@"parent_folder"]; 
    }
    [request setPostValue:[addFolderInput text] forKey:@"folder"]; 
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(finishAddFolder:)];
    [request setDidFailSelector:@selector(requestFailed:)];
    [request startAsynchronous];
}

- (void)finishAddFolder:(ASIHTTPRequest *)request {
    [self.addingLabel setHidden:YES];
    [self.activityIndicator stopAnimating];
    NSString *responseString = [request responseString];
    NSDictionary *results = [[NSDictionary alloc] 
                             initWithDictionary:[responseString JSONValue]];
    // int statusCode = [request responseStatusCode];
    int code = [[results valueForKey:@"code"] intValue];
    if (code == -1) {
        [self.errorLabel setText:[results valueForKey:@"message"]];   
        [self.errorLabel setHidden:NO];
    } else {
        [appDelegate.addSiteViewController dismissModalViewControllerAnimated:YES];
        [appDelegate reloadFeedsView:YES];
    }
    
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self.addingLabel setHidden:YES];
    [self.errorLabel setHidden:NO];
    [self.activityIndicator stopAnimating];
    NSError *error = [request error];
    NSLog(@"Error: %@", error);
    [self.errorLabel setText:error.localizedDescription];
    self.siteTable.hidden = YES;
}

#pragma mark -
#pragma mark Page Controls

- (IBAction)selectAddTypeSignup {
    [self animateLoop];
}

- (void)animateLoop {
    if ([self.addTypeControl selectedSegmentIndex] == 0) {
        [addButton setTitle:@"Add Site"];
        [addFolderInput resignFirstResponder];
        [UIView animateWithDuration:0.5 animations:^{
            siteAddressInput.frame = CGRectMake(addFolderInput.frame.origin.x, 
                                                siteAddressInput.frame.origin.y, 
                                                siteAddressInput.frame.size.width, 
                                                siteAddressInput.frame.size.height);
            addFolderInput.frame = CGRectMake(self.view.frame.size.width, 
                                              siteAddressInput.frame.origin.y, 
                                              siteAddressInput.frame.size.width, 
                                              siteAddressInput.frame.size.height);
        }];
    } else {
        [addButton setTitle:@"Add Folder"];
        [siteAddressInput resignFirstResponder];
        addFolderInput.frame = CGRectMake(self.view.frame.size.width, 
                                          siteAddressInput.frame.origin.y, 
                                          siteAddressInput.frame.size.width, 
                                          siteAddressInput.frame.size.height);
        [UIView animateWithDuration:0.5 animations:^{
            addFolderInput.frame = CGRectMake(siteAddressInput.frame.origin.x, 
                                              siteAddressInput.frame.origin.y, 
                                              siteAddressInput.frame.size.width, 
                                              siteAddressInput.frame.size.height);
            siteAddressInput.frame = CGRectMake(-1 * (siteAddressInput.frame.origin.x + 
                                                      siteAddressInput.frame.size.width), 
                                                siteAddressInput.frame.origin.y, 
                                                siteAddressInput.frame.size.width, 
                                                siteAddressInput.frame.size.height);
            siteScrollView.alpha = 0;
        }];
    }
}

#pragma mark -
#pragma mark Folder Picker

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component {
    return [[appDelegate dictFoldersArray] count] - 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
    if (row == 0) {
        return @"— Top Level —";
    } else {
        return [[appDelegate dictFoldersArray] objectAtIndex:row + 1];
    }
}

- (void)pickerView:(UIPickerView *)pickerView 
      didSelectRow:(NSInteger)row 
       inComponent:(NSInteger)component {
    NSString *folder_title;
    if (row == 0) {
        folder_title = @"- Top Level -";
    } else {
        folder_title = [[appDelegate dictFoldersArray] objectAtIndex:row + 1];        
    }
    [inFolderInput setText:folder_title];
}

- (void)showFolderPicker {
    [siteAddressInput resignFirstResponder];
    [addFolderInput resignFirstResponder];
    [inFolderInput setInputView:folderPicker];
    if (folderPicker.frame.origin.y >= self.view.bounds.size.height) {
        folderPicker.hidden = NO;
        [UIView animateWithDuration:.35 animations:^{
            folderPicker.frame = CGRectMake(0, self.view.bounds.size.height - folderPicker.frame.size.height, folderPicker.frame.size.width, folderPicker.frame.size.height);            
        }];
    }
    self.siteTable.hidden = YES;
}

- (void)hideFolderPicker {
    [UIView animateWithDuration:.35 animations:^{
        folderPicker.frame = CGRectMake(0, self.view.bounds.size.height, folderPicker.frame.size.width, folderPicker.frame.size.height);          
    }];
}

#pragma mark -
#pragma mark Autocomplete sites


- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [autocompleteResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *AddSiteAutocompleteCellIdentifier = @"AddSiteAutocompleteCellIdentifier";
    
	AddSiteAutocompleteCell *cell = (AddSiteAutocompleteCell *)[tableView dequeueReusableCellWithIdentifier:AddSiteAutocompleteCellIdentifier];
	if (cell == nil) {
		NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AddSiteAutocompleteCell"
                                                     owner:self
                                                   options:nil];
        for (id oneObject in nib) {
            if ([oneObject isKindOfClass:[AddSiteAutocompleteCell class]]) {
                cell = (AddSiteAutocompleteCell *)oneObject;
            }
        }
	}
    
    NSDictionary *result = [autocompleteResults objectAtIndex:indexPath.row];
    int subs = [[result objectForKey:@"num_subscribers"] intValue];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setPositiveFormat:@"#,###"];
	NSNumber *theScore = [NSNumber numberWithInt:subs];
    cell.feedTitle.text = [result objectForKey:@"label"];
    cell.feedUrl.text = [result objectForKey:@"value"];
    cell.feedSubs.text = [NSString stringWithFormat:@"%@ subscriber%@", 
                          [NSString stringWithFormat:@"%@", [numberFormatter stringFromNumber:theScore]], subs == 1 ? @"" : @"s"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *result = [autocompleteResults objectAtIndex:indexPath.row];
    [self.siteAddressInput setText:[result objectForKey:@"value"]];
    [self addSite];
    [UIView animateWithDuration:.35 animations:^{
        siteScrollView.alpha = 0;
    }];
}

@end