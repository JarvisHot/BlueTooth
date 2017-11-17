//
//  ViewController.m
//  BlueTooth
//
//  Created by jiang on 2017/11/17.
//  Copyright © 2017年 jarvis. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
@interface ViewController ()<CBCentralManagerDelegate,UITableViewDelegate,UITableViewDataSource,CBPeripheralDelegate>
@property(nonatomic,strong)CBCentralManager *manager;
@property(nonatomic,strong)NSMutableArray*deviceArray;
@property (weak, nonatomic) IBOutlet UITableView *table;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //    CBPeripheral 蓝牙外设，比如蓝牙手环、蓝牙心跳监视器、蓝牙打印机。
    //    CBCentralManager 蓝牙外设管理中心，与手机的蓝牙硬件模板关联，可以获取到手机中蓝牙模块的一些状态等，但是管理的就是蓝牙外设。
    //    CBService 蓝牙外设的服务，每一个蓝牙外设都有0个或者多个服务。而每一个蓝牙服务又可能包含0个或者多个蓝牙服务，也可能包含0个或者多个蓝牙特性。
    //    CBCharacteristic 每一个蓝牙特性中都包含有一些数据或者信息。
    
    
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    [_table registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    self.deviceArray=@[].mutableCopy;
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@" bluetooth-%@",central);
    switch (central.state) {
        case CBManagerStatePoweredOn:
            NSLog(@"打开，可用");
            [_manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@(NO)}];
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"可用，未打开");
            break;
        case CBManagerStateUnsupported:
            NSLog(@"SDK不支持");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"程序未授权");
            break;
        case CBManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case CBManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
    }
    
    
}
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"name----%@",peripheral);
    if (peripheral.name.length <= 0) {
        return ;
    }
    
    NSLog(@"Discovered name:%@,identifier:%@,advertisementData:%@,RSSI:%@", peripheral.name, peripheral.identifier,advertisementData,RSSI);
    if (self.deviceArray.count == 0) {
        NSDictionary *dict = @{@"peripheral":peripheral, @"RSSI":RSSI};
        [self.deviceArray addObject:dict];
    } else {
        BOOL isExist = NO;
        for (int i = 0; i < self.deviceArray.count; i++) {
            NSDictionary *dict = [self.deviceArray objectAtIndex:i];
            CBPeripheral *per = dict[@"peripheral"];
            if ([per.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
                isExist = YES;
                NSDictionary *dict = @{@"peripheral":peripheral, @"RSSI":RSSI};
                [_deviceArray replaceObjectAtIndex:i withObject:dict];
            }
        }
        
        if (!isExist) {
            NSDictionary *dict = @{@"peripheral":peripheral, @"RSSI":RSSI};
            [self.deviceArray addObject:dict];
        }
    }
    NSLog(@"devicearr----%@",_deviceArray);
    [self.table reloadData];
}
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral");
    // 连接成功后，查找服务
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"didFailToConnectPeripheral");
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return self.deviceArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell*cell=[tableView dequeueReusableCellWithIdentifier:@"cell"];
    NSDictionary *dict = [self.deviceArray objectAtIndex:indexPath.row];
    //    NSLog(@"dict;-----%@",dict[@"peripheral"]);
    CBPeripheral*per=dict[@"peripheral"];
    cell.textLabel.text=[NSString stringWithFormat:@"%@--%@",per.name,per.identifier];
    cell.detailTextLabel.text=[NSString stringWithFormat:@"%@",dict[@"RSSI"]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = [self.deviceArray objectAtIndex:indexPath.row];
    CBPeripheral *peripheral = dict[@"peripheral"];
    // 连接某个蓝牙外设
    [self.manager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey:@(YES)}];
    // 设置外设的代理是为了后面查询外设的服务和外设的特性，以及特性中的数据。
    [peripheral setDelegate:self];
    // 既然已经连接到某个蓝牙了，那就不需要在继续扫描外设了
    [self.manager stopScan];
    [self.table deselectRowAtIndexPath:indexPath animated:YES];
}

// MARK:   CBPeripheralDelegate
#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    NSString *UUID = [peripheral.identifier UUIDString];
    NSLog(@"didDiscoverServices:%@",UUID);
    if (error) {
        NSLog(@"出错");
        return;
    }
    
    CBUUID *cbUUID = [CBUUID UUIDWithString:UUID];
    NSLog(@"cbUUID:%@",cbUUID);
    
    for (CBService *service in peripheral.services) {
        NSLog(@"service:%@",service.UUID);
        //如果我们知道要查询的特性的CBUUID，可以在参数一中传入CBUUID数组。
        [peripheral discoverCharacteristics:nil forService:service];
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error
{
    if (error) {
        NSLog(@"出错");
        return;
    }
    
    for (CBCharacteristic *character in service.characteristics) {
        // 这是一个枚举类型的属性
        CBCharacteristicProperties properties = character.properties;
        if (properties & CBCharacteristicPropertyBroadcast) {
            //如果是广播特性
        }
        
        if (properties & CBCharacteristicPropertyRead) {
            //如果具备读特性，即可以读取特性的value
            [peripheral readValueForCharacteristic:character];
        }
        
        if (properties & CBCharacteristicPropertyWriteWithoutResponse) {
            //如果具备写入值不需要响应的特性
            //这里保存这个可以写的特性，便于后面往这个特性中写数据
            //            _chatacter = character;
        }
        
        if (properties & CBCharacteristicPropertyWrite) {
            //如果具备写入值的特性，这个应该会有一些响应
        }
        
        if (properties & CBCharacteristicPropertyNotify) {
            //如果具备通知的特性，无响应
            [peripheral setNotifyValue:YES forCharacteristic:character];
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (error) {
        NSLog(@"错误didUpdateNotification：%@",error);
        return;
    }
    
    CBCharacteristicProperties properties = characteristic.properties;
    if (properties & CBCharacteristicPropertyRead) {
        //如果具备读特性，即可以读取特性的value
        [peripheral readValueForCharacteristic:characteristic];
    }
}
// 读取新值的结果
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"错误：%@",error);
        return;
    }
    
    NSData *data = characteristic.value;
    if (data.length <= 0) {
        return;
    }
    NSString *info = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"info:%@",info);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
