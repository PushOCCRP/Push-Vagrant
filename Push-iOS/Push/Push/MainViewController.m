//
//  MainViewController.m
//  Push
//
//  Created by Christopher Guess on 11/11/15.
//  Copyright © 2015 OCCRP. All rights reserved.
//

#import "MainViewController.h"
#import "FeaturedArticleTableViewCell.h"
#import "ArticlePageViewController.h"
#import "ArticleViewController.h"
#import "PushSyncManager.h"
#import <SVPullToRefresh/SVPullToRefresh.h>
#import "SearchViewController.h"
#import <Masonry/Masonry.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <AFNetworking/UIImage+AFNetworking.h>

#import <Crashlytics/Crashlytics.h>

// These are also set in the respective nibs, so if you change it make sure you change it there too
static NSString * featuredCellIdentifier = @"FEATURED_ARTICLE_STORY_CELL";
static NSString * standardCellIdentifier = @"ARTICLE_STORY_CELL";


@interface MainViewController ()

@property (nonatomic, retain) IBOutlet UITableView * tableView;

@property (nonatomic, retain) NSArray * articles;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self setupNavigationBar];
    [self setupTableView];
    
    __weak typeof(self) weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf loadArticles];
    }];
    
    [self loadInitialArticles];
    
    // TODO: Track the user action that is important for you.
    [Answers logContentViewWithName:@"Article List" contentType:nil contentId:@"article_list" customAttributes:nil];
    

}

- (void)setupNavigationBar
{
    // Add Logo with custom barbutton item
    // Using a custom view for sizing
    UIImage * logoImage = [UIImage imageNamed:@"logo.png"];
    
    UIImageView * logoImageView = [[UIImageView alloc] initWithImage:logoImage];
    CGRect frame = logoImageView.frame;
    frame.size.height = self.navigationController.navigationBar.frame.size.height - 15;
    //get the appropriate width here
    CGFloat sizingRatio = frame.size.height / logoImage.size.height;
    frame.size.width = logoImage.size.width * sizingRatio;
    logoImageView.frame = frame;
    
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    UIBarButtonItem * occrpLogoButton = [[UIBarButtonItem alloc]
                                         initWithCustomView:logoImageView];
    
    self.navigationItem.leftBarButtonItem = occrpLogoButton;
    self.navigationController.navigationItem.leftBarButtonItem = occrpLogoButton;
    
    // Add search button
    UIBarButtonItem * searchBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonTapped)];
    [self.navigationItem setRightBarButtonItem:searchBarButton];

}

- (void)setupTableView
{
    [self.tableView registerNib:[UINib nibWithNibName:@"ArticleTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:standardCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"FeaturedArticleTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:featuredCellIdentifier];
}

- (void)loadInitialArticles
{
    self.articles = [[PushSyncManager sharedManager] articlesWithCompletionHandler:^(NSArray *articles) {
        NSLog(@"%@", articles);
        self.articles = articles;
        [self.tableView reloadData];
        [self.tableView.pullToRefreshView stopAnimating];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    } failure:^(NSError *error) {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Connection Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        [self.tableView.pullToRefreshView stopAnimating];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];
    
    if(self.articles){
        [self.tableView reloadData];
    } else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }

}

- (void)loadArticles
{
    [[PushSyncManager sharedManager] articlesWithCompletionHandler:^(NSArray *articles) {
        NSLog(@"%@", articles);
        self.articles = articles;
        [self.tableView reloadData];
        [self.tableView.pullToRefreshView stopAnimating];
    } failure:^(NSError *error) {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Connection Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        [self.tableView.pullToRefreshView stopAnimating];
    }];
}

- (void)searchButtonTapped
{
    SearchViewController * searchViewController = [[SearchViewController alloc] init];
    [self.navigationController pushViewController:searchViewController animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 100.0f;
    if(indexPath.row == 0){
        height = 400.0f;
    }

    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO animated:YES];
    
    ArticlePageViewController * articlePageViewController = [[ArticlePageViewController alloc] initWithArticles:self.articles];
    
    ArticleViewController * articleViewController = [[ArticleViewController alloc] initWithArticle:self.articles[indexPath.row]];
    [articlePageViewController setViewControllers:@[articleViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [self.navigationController pushViewController:articlePageViewController animated:YES];
}

// UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    ArticleTableViewCell * cell;
    
    if(indexPath.row == 0){
        cell = [tableView dequeueReusableCellWithIdentifier:featuredCellIdentifier];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:standardCellIdentifier];
    }
    
    cell.article = self.articles[indexPath.row];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Random number for testing
    return self.articles.count;
}

@end
