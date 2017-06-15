//
//  ViewController.m
//  TestRunLoop
//
//  Created by Jinxin_Fan on 2017/6/14.
//  Copyright © 2017年 Jinxin_Fan. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+WebCache.h"
#define  ShowImageTableViewReusableIdentifier @"ShowImageTableViewReusableIdentifier"
#define ImageWidth 50

typedef void(^SaveFuncBlock)();

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (strong,nonatomic) UITableView* showImageTableView;
//存放任务的数组
@property (nonatomic, strong) NSMutableArray *saveTaskMarr;

//最大任务数（超过最大任务数的任务就停止执行）
@property (nonatomic, assign) NSInteger maxTasksNumber;

//任务执行的代码块
@property (nonatomic, copy) SaveFuncBlock saveFuncBlock;

//定时器，保证runloop一直处于循环中
@property (nonatomic, weak) NSTimer *timer;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.showImageTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:ShowImageTableViewReusableIdentifier];
    [self.view addSubview:self.showImageTableView];
    self.maxTasksNumber = 18;
     [self addRunloopObserver];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(setRunLoop) userInfo:nil repeats:YES];
}
//此方法主要是利用计时器事件保持runloop处于循环中，不用做任何处理
-(void)setRunLoop{}

-(NSMutableArray *)saveTaskMarr{
    
    if (!_saveTaskMarr) {
        
        _saveTaskMarr = [NSMutableArray array];
    }
    
    return _saveTaskMarr;
}

//懒加载
-(UITableView *)showImageTableView{
    
    if (!_showImageTableView) {
        _showImageTableView = [[UITableView alloc]initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
        _showImageTableView.backgroundColor = [UIColor yellowColor];
        _showImageTableView.delegate = self;
        _showImageTableView.dataSource = self;
    }
    
    return _showImageTableView;
}

-(void)addImageToCell:(UITableViewCell*)cell andTag:(NSInteger)tag{
    
    UIImageView* cellImageView = [[UIImageView alloc]initWithFrame:CGRectMake(tag*(ImageWidth+5), 5, ImageWidth, ImageWidth)];
    
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        
        NSData* imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://img5.duitang.com/uploads/item/201312/14/20131214173346_iVKdT.jpeg"]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            cellImageView.image = [UIImage imageWithData:imageData];
            [cell.contentView addSubview:cellImageView];
        });
    });
}

//添加任务进数组保存
-(void)addTasks:(SaveFuncBlock)taskBlock{
    
    [self.saveTaskMarr addObject:taskBlock];
    //超过每次最多执行的任务数就移出当前数组
    if (self.saveTaskMarr.count > self.maxTasksNumber) {
        
        [self.saveTaskMarr removeObjectAtIndex:0];
    }
    
}

-(void)addRunloopObserver{
    //获取当前的RunLoop
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    //定义一个centext
    CFRunLoopObserverContext context = {
        0,
        ( __bridge void *)(self),
        &CFRetain,
        &CFRelease,
        NULL
    };
    //定义一个观察者
    static CFRunLoopObserverRef defaultModeObsever;
    //创建观察者
    defaultModeObsever = CFRunLoopObserverCreate(NULL,
                                                 kCFRunLoopBeforeWaiting,
                                                 YES,
                                                 NSIntegerMax - 999,
                                                 &Callback,
                                                 &context
                                                 );
    
    //添加当前RunLoop的观察者
    CFRunLoopAddObserver(runloop, defaultModeObsever, kCFRunLoopDefaultMode);
    //c语言有creat 就需要release
    CFRelease(defaultModeObsever);
}

//MARK: 回调函数
//定义一个回调函数  一次RunLoop来一次
static void Callback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    ViewController * vcSelf = (__bridge ViewController *)(info);
    
    if (vcSelf.saveTaskMarr.count > 0) {
        
        //获取一次数组里面的任务并执行
        SaveFuncBlock funcBlock = vcSelf.saveTaskMarr.firstObject;
        funcBlock();
        [vcSelf.saveTaskMarr removeObjectAtIndex:0];
    }
}
//数据源代理
#pragma mark- UITableViewDelegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:ShowImageTableViewReusableIdentifier];
    //每个cell中添加3张图片
    for (int i = 0; i < 5; i++)
    {
#if 0 //优化过的效果
        //添加任务到数组
        __weak typeof(self) weakSelf = self;
        [self addTasks:^{
            //下载图片的任务
            [weakSelf addImageToCell:cell andTag:i];
        }];
#endif
        
#if 0 //优化前的效果
        UIImageView* cellImageView = [[UIImageView alloc]initWithFrame:CGRectMake(i*(ImageWidth+5), 5, ImageWidth, ImageWidth)];
        NSData* imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://img5.duitang.com/uploads/item/201312/14/20131214173346_iVKdT.jpeg"]];
        cellImageView.image = [UIImage imageWithData:imageData];
        [cell.contentView addSubview:cellImageView];
        
#endif
#if 1 //三方库的效果
        UIImageView* cellImageView = [[UIImageView alloc]initWithFrame:CGRectMake(i*(ImageWidth+5), 5, ImageWidth, ImageWidth)];
        [cellImageView  sd_setImageWithURL:[NSURL URLWithString:@"http://img5.duitang.com/uploads/item/201312/14/20131214173346_iVKdT.jpeg"]];
        [cell.contentView addSubview:cellImageView];
        
#endif
    }
    
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 399;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 135;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
