//
//  LJBLCWController.m
//  LJBluetooth
//
//  Created by 李蒋 on 2018/3/28.
//  Copyright © 2018年 JiangLi. All rights reserved.
//

#import "LJBLCWController.h"
#import <CoreBluetooth/CoreBluetooth.h>

//宏定义特征
#define SERVICE_UUID @"CDD1"
#define CHARACTERISTIC_UUID @"CDD2"

@interface LJBLCWController ()<CBPeripheralManagerDelegate>

//创建外设管理对象
@property(strong,nonatomic)CBPeripheralManager * peripheralManager;

//用于手动发送数据
@property(strong,nonatomic)CBMutableCharacteristic * characteristic;
//输入框
@property(strong,nonatomic)UITextField * textf;

@end

@implementation LJBLCWController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"外设";
    [self creatUI];
    [self doSomething];
}
-(void)creatUI{
    //发送按钮
    UIButton * sendbt = [UIButton buttonWithType:UIButtonTypeCustom];
    sendbt.frame = CGRectMake(60, 140, 70, 60);
    [sendbt setTitle:@"发送" forState:UIControlStateNormal];
    [sendbt setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [sendbt setBackgroundColor:[UIColor grayColor]];
    [sendbt addTarget:self action:@selector(sendAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sendbt];
    //文本输入框
    self.textf = [[UITextField alloc] initWithFrame:CGRectMake(10, 80, 160, 45)];
    self.textf.layer.borderWidth = 1;
    self.textf.layer.borderColor = [UIColor blueColor].CGColor;
    [self.view addSubview:self.textf];
    
}
-(void)doSomething{
    //初始化外设对象管理器，并放到主线程（回调方法：peripheralManagerDidUpdateState）
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
}
//外设管理回调方法实现
//当创建CBPeripheralManager的时候，会回调判断蓝牙状态的方法。当蓝牙状态没问题的时候创建外设的Service（服务）和Characteristics（特征）
/*
 设备的蓝牙状态
 CBManagerStateUnknown = 0,  未知
 CBManagerStateResetting,    重置中
 CBManagerStateUnsupported,  不支持
 CBManagerStateUnauthorized, 未验证
 CBManagerStatePoweredOff,   未启动
 CBManagerStatePoweredOn,    可用
 */
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state == CBManagerStatePoweredOn) {
        //创建servic服务和特征
        [self setupServiceAndCharacteristics];
        //根据服务UUID进行广播
        [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:@[[CBUUID UUIDWithString:SERVICE_UUID]]}];
    }
}
//创建服务和特征
-(void)setupServiceAndCharacteristics{
    //创建服务
    CBUUID * serviceId = [CBUUID UUIDWithString:SERVICE_UUID];
    CBMutableService * service = [[CBMutableService alloc] initWithType:serviceId primary:YES];
    //创建服务中的特征
    CBUUID * characteristicId = [CBUUID UUIDWithString:CHARACTERISTIC_UUID];
    CBMutableCharacteristic * characteristic = [[CBMutableCharacteristic alloc] 
                                                initWithType:characteristicId properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite | CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    //特征添加进服务
    service.characteristics = @[characteristic];
    //服务加入管理
    [self.peripheralManager addService:service];
    self.characteristic = characteristic;
}

//当中心设备写入数据的时候，外设会调用下面这个方法。
/** 中心设备写入数据的时候回调 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    // 写入数据的请求
    CBATTRequest *request = requests.lastObject;
    // 把写入的数据显示在文本框中
    self.textf.text = [[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding];
}
//主动给中心设备发送数据的方法。
/** 通过固定的特征发送数据到中心设备 */

- (void)sendAction {
    if (self.characteristic) {
        BOOL sendSuccess = [self.peripheralManager updateValue:[self.textf.text dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.characteristic onSubscribedCentrals:nil];
        if (sendSuccess) {
            NSLog(@"数据发送成功");
        }else {
            NSLog(@"数据发送失败");
        }
    }
    else{
        UIAlertController *controller=[UIAlertController alertControllerWithTitle:@"提示" message:@"没有搜索到可用设备，请先搜索并连接可用设备！" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *act1=[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        UIAlertAction * act2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil];
        [controller addAction:act2];
        [controller addAction:act1];
        [self presentViewController:controller animated:YES completion:nil];
    }
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
