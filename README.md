## **一键备份恢复插件设置**
#### 备份恢复功能允许用户将当前所有设置保存为Base64编码的字符串，并在需要时从该字符串中恢复设置。
### 1. 功能流程
#### > 备份流程:
- 用户点击"Base64备份设置(点击复制)"开关
- 系统从NSUserDefaults中获取所有以"DYYY"开头的设置
- 将这些设置序列化为JSON
- 将JSON转换为Base64编码的字符串
- 复制该字符串到剪贴板
- 显示成功提示
- 自动关闭开关
#### > 恢复流程:
- 用户点击"Base64恢复设置(从剪贴板)"开关
- 系统从剪贴板获取Base64编码的字符串
- 将该字符串解码为JSON
- 解析JSON得到设置键值对
- 将这些键值对保存到NSUserDefaults
- 显示成功提示
- 自动关闭开关

### 2. 代码实现
#### 2.1 Manager中的核心方法
 ```js
 DYYYManager.h 中的声明:
 
+ (NSString *)base64EncodeUserSettings;
+ (BOOL)base64DecodeAndRestoreUserSettings:(NSString *)base64String;
+ (void)backupSettingsToBase64AndCopy;
+ (void)restoreSettingsFromBase64;
 ```
// DYYYManager.m 中的实现:
// 将用户设置编码为Base64字符串


```+ (NSString *)base64EncodeUserSettings {
    // 获取所有用户设置
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dictionary = [defaults dictionaryRepresentation];
    NSMutableDictionary *prefs = [NSMutableDictionary dictionary];
    
    // 只备份DYYY相关的设置
    for (NSString *key in dictionary) {
        if ([key hasPrefix:@"DYYY"]) {
            id value = [defaults objectForKey:key];
            if (value) {
                [prefs setObject:value forKey:key];
            }
        }
    }
    
    // 如果没有找到DYYY设置，返回空字典
    if (prefs.count == 0) {
        [self showToast:@"未找到设置，请确保已保存过设置"];
        return nil;
    }
    
    // 将设置转换为JSON数据
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:prefs 
                                                       options:NSJSONWritingPrettyPrinted 
                                                         error:&error];
    if (error) {
        NSLog(@"Error serializing settings: %@", error);
        [self showToast:@"设置序列化失败"];
        return nil;
    }
    
    // 转换为Base64字符串
    NSString *base64String = [jsonData base64EncodedStringWithOptions:0];
    return base64String;
}

```
// 从Base64字符串解码并恢复用户设置

```+ (BOOL)base64DecodeAndRestoreUserSettings:(NSString *)base64String {
    if (!base64String || base64String.length == 0) {
        [self showToast:@"无效的备份数据"];
        return NO;
    }
    
    // 从Base64解码
    NSData *jsonData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    if (!jsonData) {
        [self showToast:@"Base64解码失败"];
        return NO;
    }
    
    // 解析JSON数据
    NSError *error;
    NSDictionary *settings = [NSJSONSerialization JSONObjectWithData:jsonData 
                                                             options:0 
                                                               error:&error];
    if (error || !settings) {
        NSLog(@"Error parsing settings JSON: %@", error);
        [self showToast:@"设置解析失败"];
        return NO;
    }
    
    // 保存到NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [settings enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [defaults setObject:obj forKey:key];
    }];
    [defaults synchronize];
    
    [self showToast:@"设置已恢复，重启抖音生效"];
    return YES;
}

```
// 备份设置到Base64并复制到剪贴板

```+ (void)backupSettingsToBase64AndCopy {
    NSString *base64String = [self base64EncodeUserSettings];
    if (base64String) {
        // 复制到剪贴板
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        [pasteboard setString:base64String];
        [self showToast:@"设置已备份到剪贴板"];
    } else {
        [self showToast:@"设置备份失败"];
    }
}
```

// 从剪贴板恢复Base64编码的设置

```+ (void)restoreSettingsFromBase64 {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSString *base64String = [pasteboard string];
    
    if (!base64String || base64String.length == 0) {
        [self showToast:@"剪贴板为空，无法恢复设置"];
        return;
    }
    
    if ([self base64DecodeAndRestoreUserSettings:base64String]) {
        [self showToast:@"设置已从剪贴板恢复"];
    } else {
        [self showToast:@"无法识别剪贴板内容为有效设置"];
    }
}
```
#### 2.2 设置界面配置（DYYYSettingViewController.m）

```// 在setupSettingItems方法中添加备份恢复设置项
@[
    [DYYYSettingItem itemWithTitle:@"Base64备份设置(点击复制)" key:@"DYYYBackupSettings" type:DYYYSettingItemTypeSwitch],
    [DYYYSettingItem itemWithTitle:@"Base64恢复设置(从剪贴板)" key:@"DYYYRestoreSettings" type:DYYYSettingItemTypeSwitch]
]

// 处理开关变化（特殊情况）
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
    
    // 处理常规开关...
}
```
#### 2.3 原生设置界面集成（DYYYSettings.xm）

```// 在copyItems数组中添加备份恢复项
NSMutableArray<AWESettingItemModel *> *copyItems = [NSMutableArray array];
NSArray *copySettings = @[
    // 其他设置项...
    @{@"identifier": @"DYYYBackupSettings", @"title": @"一键备份设置", @"detail": @"复制到剪贴板", @"cellType": @6, @"imageName": @"ic_rectangleonrectangleup_outlined_20"},
    @{@"identifier": @"DYYYRestoreSettings", @"title": @"一键恢复设置", @"detail": @"从剪贴板恢复", @"cellType": @6, @"imageName": @"ic_rectangleonrectangleup_outlined_20"}
];

// 处理开关状态变化
item.switchChangedBlock = ^{
    __strong AWESettingItemModel *strongItem = weakItem;
    if (strongItem) {
        BOOL isSwitchOn = !strongItem.isSwitchOn;
        strongItem.isSwitchOn = isSwitchOn;
        
        // 检查是否为备份和恢复功能
        if ([strongItem.identifier isEqualToString:@"DYYYBackupSettings"] && isSwitchOn) {
            // 调用备份功能
            [%c(DYYYManager) backupSettingsToBase64AndCopy];
            
            // 延迟关闭开关
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                strongItem.isSwitchOn = NO;
            });
            return;
        } else if ([strongItem.identifier isEqualToString:@"DYYYRestoreSettings"] && isSwitchOn) {
            // 调用恢复功能
            [%c(DYYYManager) restoreSettingsFromBase64];
            
            // 延迟关闭开关
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                strongItem.isSwitchOn = NO;
            });
            return;
        } else {
            // 其他开关设置保存
            setUserDefaults(@(isSwitchOn), strongItem.identifier);
        }
    }
};
```
#### 3. 需要注意的点
1. 过滤设置：只保存以"DYYY"开头的设置，避免保存无关设置
2. JSON序列化：使用NSJSONSerialization将设置对象转换为JSON
3. Base64编码/解码：使用Foundation框架的Base64编解码方法
4. 开关自动复位：通过延迟执行将开关状态重置为关闭
5. 剪贴板集成：使用UIPasteboard实现数据共享
6. 用户反馈：通过showToast提供操作结果反馈
7. 特殊标签：使用特定tag值（88001和88002）识别备份恢复开关
#### 4. 实现特点
1. 无文件依赖：使用NSUserDefaults和剪贴板，不依赖外部文件系统
2. 易于分享：生成的Base64字符串可以通过任何文本通道分享
3. 幂等操作：备份和恢复操作可以多次执行，不会造成数据损坏
4. 双重实现：同时支持原生设置页面和自定义设置页面的操作
5. 即时反馈：所有操作都有即时的Toast提示
6. 即点即用：开关会在操作完成后自动关闭，不需要用户手动关闭
#### 5. 调用流程图
【用户点击备份】-> backupSettingsToBase64AndCopy()
                  -> base64EncodeUserSettings()
                     -> 获取NSUserDefaults中所有DYYY设置
                     -> 转换为JSON格式
                     -> Base64编码
                  -> 复制到剪贴板
                  -> 显示Toast提示
                  -> 自动关闭开关

【用户点击恢复】-> restoreSettingsFromBase64()
                  -> 从剪贴板获取内容
                  -> base64DecodeAndRestoreUserSettings()
                     -> Base64解码
                     -> 解析JSON格式
                     -> 写入到NSUserDefaults
                  -> 显示Toast提示
                  -> 自动关闭开关
