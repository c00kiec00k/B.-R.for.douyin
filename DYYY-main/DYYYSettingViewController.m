#import "DYYYSettingViewController.h"
#import "DYYYManager.h"

typedef NS_ENUM(NSInteger, DYYYSettingItemType) {
    DYYYSettingItemTypeSwitch,
    DYYYSettingItemTypeTextField,
    DYYYSettingItemTypeSpeedPicker
};

@interface DYYYSettingItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) DYYYSettingItemType type;
@property (nonatomic, copy, nullable) NSString *placeholder;

+ (instancetype)itemWithTitle:(NSString *)title key:(NSString *)key type:(DYYYSettingItemType)type;
+ (instancetype)itemWithTitle:(NSString *)title key:(NSString *)key type:(DYYYSettingItemType)type placeholder:(nullable NSString *)placeholder;

@end

@implementation DYYYSettingItem

+ (instancetype)itemWithTitle:(NSString *)title key:(NSString *)key type:(DYYYSettingItemType)type {
    return [self itemWithTitle:title key:key type:type placeholder:nil];
}

+ (instancetype)itemWithTitle:(NSString *)title key:(NSString *)key type:(DYYYSettingItemType)type placeholder:(nullable NSString *)placeholder {
    DYYYSettingItem *item = [[DYYYSettingItem alloc] init];
    item.title = title;
    item.key = key;
    item.type = type;
    item.placeholder = placeholder;
    return item;
}

@end

@interface DYYYSettingViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSArray<DYYYSettingItem *> *> *settingSections;
@property (nonatomic, strong) UILabel *footerLabel;
@property (nonatomic, strong) NSMutableArray<NSString *> *sectionTitles;
@property (nonatomic, strong) NSMutableSet *expandedSections;
@property (nonatomic, strong) UIVisualEffectView *blurEffectView;
@property (nonatomic, strong) UIVisualEffectView *vibrancyEffectView;
@property (nonatomic, assign) BOOL isAgreementShown;

@end

@implementation DYYYSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"DYYY设置";
    self.expandedSections = [NSMutableSet set];
    self.isAgreementShown = NO;
    
    [self setupAppearance];
    [self setupBlurEffect];
    [self setupTableView];
    [self setupSettingItems];
    [self setupSectionTitles];
    [self setupFooterLabel];
    [self addTitleGradientAnimation];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.isAgreementShown) {
        [self checkFirstLaunch];
        self.isAgreementShown = YES;
    }
}

- (void)setupAppearance {
    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.largeTitleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
}

- (void)setupBlurEffect {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.blurEffectView.frame = self.view.bounds;
    self.blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.blurEffectView];
    
    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    self.vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
    self.vibrancyEffectView.frame = self.blurEffectView.bounds;
    self.vibrancyEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.blurEffectView.contentView addSubview:self.vibrancyEffectView];
    
    UIView *overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
    overlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:overlayView];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    self.tableView.sectionHeaderTopPadding = 0;
    [self.view addSubview:self.tableView];
}

- (void)setupSettingItems {
    self.settingSections = @[
        @[
            [DYYYSettingItem itemWithTitle:@"启用弹幕改色" key:@"DYYYEnableDanmuColor" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"自定弹幕颜色" key:@"DYYYdanmuColor" type:DYYYSettingItemTypeTextField placeholder:@"十六进制"],
            [DYYYSettingItem itemWithTitle:@"启用深色键盘" key:@"DYYYisDarkKeyBoard" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"显示进度时长" key:@"DYYYisShowScheduleDisplay" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"时长纵轴位置" key:@"DYYYTimelineVerticalPosition" type:DYYYSettingItemTypeTextField placeholder:@"-12.5"],
            [DYYYSettingItem itemWithTitle:@"隐藏视频进度" key:@"DYYYHideVideoProgress" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"启用自动播放" key:@"DYYYisEnableAutoPlay" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"推荐过滤直播" key:@"DYYYisSkipLive" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"推荐过滤热点" key:@"DYYYisSkipHotSpot" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"推荐过滤低赞" key:@"DYYYfilterLowLikes" type:DYYYSettingItemTypeTextField placeholder:@"填0关闭"],
            [DYYYSettingItem itemWithTitle:@"推荐过滤文案" key:@"DYYYfilterKeywords" type:DYYYSettingItemTypeTextField placeholder:@"不填关闭"],           
            [DYYYSettingItem itemWithTitle:@"启用首页净化" key:@"DYYYisEnablePure" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"启用首页全屏" key:@"DYYYisEnableFullScreen" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"启用屏蔽广告" key:@"DYYYNoAds" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"屏蔽检测更新" key:@"DYYYNoUpdates" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"评论区毛玻璃" key:@"DYYYisEnableCommentBlur" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"毛玻璃透明度" key:@"DYYYCommentBlurTransparent" type:DYYYSettingItemTypeTextField placeholder:@"0-1小数"],
            [DYYYSettingItem itemWithTitle:@"时间属地显示" key:@"DYYYisEnableArea" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"时间标签颜色" key:@"DYYYLabelColor" type:DYYYSettingItemTypeTextField placeholder:@"十六进制"],
            [DYYYSettingItem itemWithTitle:@"隐藏系统顶栏" key:@"DYYYisHideStatusbar" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"关注二次确认" key:@"DYYYfollowTips" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"收藏二次确认" key:@"DYYYcollectTips" type:DYYYSettingItemTypeSwitch]

        ],
        @[
            [DYYYSettingItem itemWithTitle:@"设置顶栏透明" key:@"DYYYtopbartransparent" type:DYYYSettingItemTypeTextField placeholder:@"0-1小数"],
            [DYYYSettingItem itemWithTitle:@"设置全局透明" key:@"DYYYGlobalTransparency" type:DYYYSettingItemTypeTextField placeholder:@"0-1小数"],
            [DYYYSettingItem itemWithTitle:@"设置默认倍速" key:@"DYYYDefaultSpeed" type:DYYYSettingItemTypeSpeedPicker],
            [DYYYSettingItem itemWithTitle:@"右侧栏缩放度" key:@"DYYYElementScale" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
            [DYYYSettingItem itemWithTitle:@"昵称文案缩放" key:@"DYYYNicknameScale" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
            [DYYYSettingItem itemWithTitle:@"昵称下移距离" key:@"DYYYNicknameVerticalOffset" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
            [DYYYSettingItem itemWithTitle:@"文案下移距离" key:@"DYYYDescriptionVerticalOffset" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
            [DYYYSettingItem itemWithTitle:@"属地左移系数" key:@"DYYYIPLeftShiftFactor" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
            [DYYYSettingItem itemWithTitle:@"设置首页标题" key:@"DYYYIndexTitle" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
            [DYYYSettingItem itemWithTitle:@"设置朋友标题" key:@"DYYYFriendsTitle" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
            [DYYYSettingItem itemWithTitle:@"设置消息标题" key:@"DYYYMsgTitle" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
            [DYYYSettingItem itemWithTitle:@"设置我的标题" key:@"DYYYSelfTitle" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"]
        ],
        @[
            [DYYYSettingItem itemWithTitle:@"隐藏全屏观看" key:@"DYYYisHiddenEntry" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏底栏商城" key:@"DYYYHideShopButton" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏底栏信息" key:@"DYYYHideMessageButton" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏底栏朋友" key:@"DYYYHideFriendsButton" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏底栏加号" key:@"DYYYisHiddenJia" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏底栏红点" key:@"DYYYisHiddenBottomDot" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏底栏背景" key:@"DYYYisHiddenBottomBg" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏侧栏红点" key:@"DYYYisHiddenSidebarDot" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏头像加号" key:@"DYYYHideLOTAnimationView" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏点赞按钮" key:@"DYYYHideLikeButton" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏评论按钮" key:@"DYYYHideCommentButton" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏收藏按钮" key:@"DYYYHideCollectButton" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏头像按钮" key:@"DYYYHideAvatarButton" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏音乐按钮" key:@"DYYYHideMusicButton" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏分享按钮" key:@"DYYYHideShareButton" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏视频定位" key:@"DYYYHideLocation" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏右上搜索" key:@"DYYYHideDiscover" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏相关搜索" key:@"DYYYHideInteractionSearch" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏通知提示" key:@"DYYYHidePushBanner" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏头像列表" key:@"DYYYisHiddenAvatarList" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏头像气泡" key:@"DYYYisHiddenAvatarBubble" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏左侧边栏" key:@"DYYYisHiddenLeftSideBar" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏吃喝玩乐" key:@"DYYYHideCapsuleView" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏弹幕按钮" key:@"DYYYHideDanmuButton" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏取消静音" key:@"DYYYHideCancelMute" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏去汽水听" key:@"DYYYHideQuqishuiting" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏共创头像" key:@"DYYYHideGongChuang" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏热点提示" key:@"DYYYHideHotspot" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏推荐提示" key:@"DYYYHideRecommendTips" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏分享提示" key:@"DYYYHideShareContentView" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏作者声明" key:@"DYYYHideAntiAddictedNotice" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏拍摄同款" key:@"DYYYHideFeedAnchorContainer" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏挑战贴纸" key:@"DYYYHideChallengeStickers" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏校园提示" key:@"DYYYHideTemplateTags" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏作者店铺" key:@"DYYYHideHisShop" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏关注直播" key:@"DYYYHidenCapsuleView" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏顶栏横线" key:@"DYYYHidentopbarprompt" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"隐藏短剧合集" key:@"DYYYHideTemplatePlaylet" type:DYYYSettingItemTypeSwitch]
        ],
        @[
            [DYYYSettingItem itemWithTitle:@"移除推荐" key:@"DYYYHideHotContainer" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"移除关注" key:@"DYYYHideFollow" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"移除精选" key:@"DYYYHideMediumVideo" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"移除商城" key:@"DYYYHideMall" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"移除朋友" key:@"DYYYHideFriend" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"移除同城" key:@"DYYYHideNearby" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"移除团购" key:@"DYYYHideGroupon" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"移除直播" key:@"DYYYHideTabLive" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"移除热点" key:@"DYYYHidePadHot" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"移除经验" key:@"DYYYHideHangout" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"移除短剧" key:@"DYYYHidePlaylet" type:DYYYSettingItemTypeSwitch]
        ],
        @[
            [DYYYSettingItem itemWithTitle:@"Base64备份设置(点击复制)" key:@"DYYYBackupSettings" type:DYYYSettingItemTypeSwitch],
            [DYYYSettingItem itemWithTitle:@"Base64恢复设置(从剪贴板)" key:@"DYYYRestoreSettings" type:DYYYSettingItemTypeSwitch]
        ]
    ];
}

- (void)setupSectionTitles {
    self.sectionTitles = [NSMutableArray arrayWithObjects:@"功能设置", @"视觉设置", @"界面隐藏", @"功能移除", @"小工具", @"关于", @"增强设置", nil];
}

- (void)setupFooterLabel {
    self.footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    self.footerLabel.text = [NSString stringWithFormat:@"Developer By @huamidev\nVersion: %@ (%@)", @"2.2-2", @"2503End"];
    self.footerLabel.textAlignment = NSTextAlignmentCenter;
    self.footerLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.footerLabel.textColor = [UIColor colorWithRed:173/255.0 green:216/255.0 blue:230/255.0 alpha:1.0];
    self.footerLabel.numberOfLines = 2;
    self.footerLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.tableView.tableFooterView = self.footerLabel;
}


- (void)addTitleGradientAnimation {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(__bridge id)[UIColor systemRedColor].CGColor, (__bridge id)[UIColor systemBlueColor].CGColor];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 0);
    gradient.frame = CGRectMake(0, 0, 150, 30);
    
    UIView *titleView = [[UIView alloc] initWithFrame:gradient.frame];
    [titleView.layer addSublayer:gradient];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleView.bounds];
    titleLabel.text = self.title;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    titleLabel.textColor = [UIColor clearColor];
    
    gradient.mask = titleLabel.layer;
    self.navigationItem.titleView = titleView;
    
    CABasicAnimation *colorChange = [CABasicAnimation animationWithKeyPath:@"colors"];
    colorChange.toValue = @[(__bridge id)[UIColor systemYellowColor].CGColor, (__bridge id)[UIColor systemGreenColor].CGColor];
    colorChange.duration = 2.0;
    colorChange.autoreverses = YES;
    colorChange.repeatCount = HUGE_VALF;
    
    [gradient addAnimation:colorChange forKey:@"colorChangeAnimation"];
}

#pragma mark - First Launch Agreement

- (void)checkFirstLaunch {
    
    BOOL hasAgreed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"];
    
    if (!hasAgreed) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAgreementAlert];
        });
    }
}

- (void)showAgreementAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"用户协议"
                                                                             message:@"本插件为开源项目\n仅供学习交流用途\n如有侵权请联系, GitHub 仓库：Wtrwx/DYYY\n请遵守当地法律法规, 逆向工程仅为学习目的\n盗用源码进行商业用途/发布但未标记开源项目必究\n详情请参阅项目内 MIT 许可证\n\n请输入\"我已阅读并同意继续使用\"以继续使用"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alertController.textFields.firstObject;
        NSString *inputText = textField.text;
        
        if ([inputText isEqualToString:@"我已阅读并同意继续使用"]) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DYYYUserAgreementAccepted"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"输入错误"
                                                                               message:@"请正确输入"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self showAgreementAlert];
            }];
            
            [errorAlert addAction:okAction];
            [self presentViewController:errorAlert animated:YES completion:nil];
        }
    }];

    UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"退出" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        exit(0);
    }];
    
    [alertController addAction:confirmAction];
    [alertController addAction:exitAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.settingSections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section < self.sectionTitles.count) {
        return self.sectionTitles[section];
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 44)];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, headerView.bounds.size.width - 50, 44)];
    titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [headerView addSubview:titleLabel];
    
    UIImageView *arrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(titleLabel.frame.origin.x + titleLabel.frame.size.width - 30, 15, 14, 14)];
    arrowImageView.image = [UIImage systemImageNamed:[self.expandedSections containsObject:@(section)] ? @"chevron.down" : @"chevron.right"];
    arrowImageView.tintColor = [UIColor lightGrayColor];
    arrowImageView.tag = 100;
    arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    [headerView addSubview:arrowImageView];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = headerView.bounds;
    button.tag = section;
    [button addTarget:self action:@selector(headerTapped:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:button];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.expandedSections containsObject:@(section)] ? self.settingSections[section].count : 0;
}

- (void)toggleSection:(UIButton *)sender {
    NSNumber *section = @(sender.tag);
    if ([self.expandedSections containsObject:section]) {
        [self.expandedSections removeObject:section];
    } else {
        [self.expandedSections addObject:section];
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sender.tag] withRowAnimation:UITableViewRowAnimationFade];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"DYYYSettingCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // 移除所有子视图
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    
    DYYYSettingItem *item = self.settingSections[indexPath.section][indexPath.row];
    
    // 设置单元格样式
    cell.contentView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
    cell.contentView.layer.cornerRadius = 10;
    cell.contentView.layer.masksToBounds = YES;
    
    // 创建标题标签
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, cell.contentView.bounds.size.width - 30, 50)];
    titleLabel.text = item.title;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [cell.contentView addSubview:titleLabel];
    
    // 根据项目类型添加不同的控件
    switch (item.type) {
        case DYYYSettingItemTypeSwitch: {
            UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(cell.contentView.bounds.size.width - 65, 10, 51, 31)];
            [switchControl setOn:[[NSUserDefaults standardUserDefaults] boolForKey:item.key]];
            [switchControl addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
            switchControl.onTintColor = [UIColor colorWithRed:0/255.0 green:175/255.0 blue:255/255.0 alpha:1.0];
            switchControl.tag = indexPath.section * 1000 + indexPath.row;
            
            // 为备份和恢复开关设置特定tag
            if ([item.key isEqualToString:@"DYYYBackupSettings"]) {
                switchControl.tag = 88001; // 备份设置特定tag
            } else if ([item.key isEqualToString:@"DYYYRestoreSettings"]) {
                switchControl.tag = 88002; // 恢复设置特定tag
            }
            
            [cell.contentView addSubview:switchControl];
            break;
        }
        case DYYYSettingItemTypeTextField: {
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(cell.contentView.bounds.size.width - 150, 10, 130, 30)];
            textField.borderStyle = UITextBorderStyleRoundedRect;
            textField.placeholder = item.placeholder;
            textField.attributedPlaceholder = [[NSAttributedString alloc]
                initWithString:item.placeholder
                attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
            textField.text = [[NSUserDefaults standardUserDefaults] objectForKey:item.key];
            textField.textAlignment = NSTextAlignmentRight;
            textField.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
            textField.textColor = [UIColor whiteColor];
            
            [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingDidEnd];
            textField.tag = indexPath.section * 1000 + indexPath.row;
            cell.accessoryView = textField;
            break;
        }
        case DYYYSettingItemTypeSpeedPicker: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            UITextField *speedField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 80, 30)];
            speedField.text = [NSString stringWithFormat:@"%.2f", [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"]];
            speedField.textColor = [UIColor whiteColor];
            speedField.borderStyle = UITextBorderStyleNone;
            speedField.backgroundColor = [UIColor clearColor];
            speedField.textAlignment = NSTextAlignmentRight;
            speedField.enabled = NO;
            
            speedField.tag = 999;
            cell.accessoryView = speedField;
            break;
        }
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat sectionInset = 16;
    cell.contentView.frame = UIEdgeInsetsInsetRect(cell.contentView.frame, UIEdgeInsetsMake(0, sectionInset, 0, sectionInset));
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DYYYSettingItem *item = self.settingSections[indexPath.section][indexPath.row];
    if (item.type == DYYYSettingItemTypeSpeedPicker) {
        [self showSpeedPicker];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showSpeedPicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择倍速"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray *speeds = @[@0.75, @1.0, @1.25, @1.5, @2.0, @2.5, @3.0];
    for (NSNumber *speed in speeds) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%.2f", speed.floatValue]
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
            [[NSUserDefaults standardUserDefaults] setFloat:speed.floatValue forKey:@"DYYYDefaultSpeed"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            for (NSInteger section = 0; section < self.settingSections.count; section++) {
                NSArray *items = self.settingSections[section];
                for (NSInteger row = 0; row < items.count; row++) {
                    DYYYSettingItem *item = items[row];
                    if (item.type == DYYYSettingItemTypeSpeedPicker) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                        UITextField *speedField = [cell.accessoryView viewWithTag:999];
                        if (speedField) {
                            speedField.text = [NSString stringWithFormat:@"%.2f", speed.floatValue];
                        }
                        break;
                    }
                }
            }
        }];
        [alert addAction:action];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
        alert.popoverPresentationController.sourceView = selectedCell;
        alert.popoverPresentationController.sourceRect = selectedCell.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Actions

- (void)switchValueChanged:(UISwitch *)sender {
    // 处理备份和恢复开关的特殊情况
    if (sender.tag == 88001 && sender.isOn) {
        // 备份设置
        [DYYYManager backupSettingsToBase64AndCopy];
        
        // 延迟关闭开关
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [sender setOn:NO animated:YES];
        });
        return;
    } 
    else if (sender.tag == 88002 && sender.isOn) {
        // 恢复设置
        [DYYYManager restoreSettingsFromBase64];
        
        // 延迟关闭开关
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [sender setOn:NO animated:YES];
        });
        return;
    }
    
    // 处理常规开关
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag % 1000 inSection:sender.tag / 1000];
    DYYYSettingItem *item = self.settingSections[indexPath.section][indexPath.row];
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:item.key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)textFieldDidChange:(UITextField *)textField {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag % 1000 inSection:textField.tag / 1000];
    DYYYSettingItem *item = self.settingSections[indexPath.section][indexPath.row];
    [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:item.key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)headerTapped:(UIButton *)sender {
    NSNumber *section = @(sender.tag);
    if ([self.expandedSections containsObject:section]) {
        [self.expandedSections removeObject:section];
    } else {
        [self.expandedSections addObject:section];
    }
    
    UIView *headerView = [self.tableView headerViewForSection:sender.tag];
    UIImageView *arrowImageView = [headerView viewWithTag:100];
    
    [UIView animateWithDuration:0.3 animations:^{
        arrowImageView.image = [UIImage systemImageNamed:[self.expandedSections containsObject:section] ? @"chevron.down" : @"chevron.right"];
    }];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sender.tag] withRowAnimation:UITableViewRowAnimationFade];
}

@end
