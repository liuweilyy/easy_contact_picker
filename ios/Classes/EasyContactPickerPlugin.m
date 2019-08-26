#import "EasyContactPickerPlugin.h"
#import <ContactsUI/ContactsUI.h>
#import "ContactModel.h"

NSString*const CHANNEL = @"plugins.flutter.io/easy_contact_picker";
// 跳转原生选择联系人页面
NSString*const METHOD_CALL_NATIVE = @"selectContactNative";
// 获取联系人列表
NSString*const METHOD_CALL_LIST = @"selectContactList";

@interface EasyContactPickerPlugin () <CNContactPickerDelegate>

@property(copy, nonatomic) FlutterResult result;

@end

@implementation EasyContactPickerPlugin{
  UIImagePickerController *_imagePickerController;
  UIViewController *_viewController;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:CHANNEL
            binaryMessenger:[registrar messenger]];
    
  UIViewController *viewController =
  [UIApplication sharedApplication].delegate.window.rootViewController;
    
  EasyContactPickerPlugin* instance = [[EasyContactPickerPlugin alloc] initWithViewController:viewController];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithViewController:(UIViewController *)viewController {
  self = [super init];
  if (self) {
      _viewController = viewController;
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if (self.result) {
        self.result([FlutterError errorWithCode:@"multiple_request"
                                        message:@"Cancelled by a second request"
                                        details:nil]);
        self.result = nil;
    }
    //METHOD_CALL_NATIVE 跳转本地选择通讯录
    if ([METHOD_CALL_NATIVE isEqualToString:call.method]) {
        self.result = result;
        [self openContactPickerVC];
    }
    //METHOD_CALL_LIST 获取本地通讯录数据
    else if ([METHOD_CALL_LIST isEqualToString:call.method]) {
        self.result = result;
        [self getContactArray];
    }
}

/// 打开通讯录
- (void)openContactPickerVC{

    CNContactPickerViewController *contactPicker = [[CNContactPickerViewController alloc] init];
    contactPicker.delegate = self;
    contactPicker.displayedPropertyKeys = @[CNContactPhoneNumbersKey];
    [_viewController presentViewController:contactPicker animated:YES completion:nil];
}

///  进入系统通讯录页面
- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperty:(CNContactProperty *)contactProperty {
    CNPhoneNumber *phoneNumberModel = (CNPhoneNumber *)contactProperty.value;
    
    [_viewController dismissViewControllerAnimated:YES completion:^{
        /// 联系人
        NSString *name = [NSString stringWithFormat:@"%@%@",contactProperty.contact.familyName, contactProperty.contact.givenName];
        /// 电话
        NSString *phoneNumber = phoneNumberModel.stringValue;
        phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                    [dict setObject:name forKey:@"fullName"];
                    [dict setObject:phoneNumber forKey:@"phoneNumber"];
                    self.result(dict);
    }];
}

/// 获取联系人数据
- (void)getContactArray{
    NSMutableArray *contacts = [[NSMutableArray alloc]initWithCapacity:1];
    CNContactStore *store = [[CNContactStore alloc] init];


    [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {

            // 获取联系人仓库
            CNContactStore * store = [[CNContactStore alloc] init];

            // 创建联系人信息的请求对象
            NSArray * keys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactNamePrefixKey, CNContactPhoneticFamilyNameKey];

            // 根据请求Key, 创建请求对象
            CNContactFetchRequest * request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];

            // 发送请求
            [store enumerateContactsWithFetchRequest:request error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
                ContactModel *contactModel = [[ContactModel alloc]init];
                // 获取名字
                NSString * givenName = contact.givenName;
                // 获取姓氏
                NSString * familyName = contact.familyName;

                contactModel.name = [NSString stringWithFormat:@"%@%@",familyName,givenName];
                // 获取电话
                NSArray * phoneArray = contact.phoneNumbers;
                for (CNLabeledValue * labelValue in phoneArray) {
                    CNPhoneNumber * number = labelValue.value;
                    contactModel.phoneNumber = number.stringValue;
                }
                [contacts addObject:contactModel];
            }];
            self.result([self defaultHandleContactObject:contacts]);
        } else {
            self.result([FlutterError errorWithCode:@"" message:@"授权失败" details:@""]);
        }
    }];
}

- (NSArray<NSMutableDictionary *> *)defaultHandleContactObject:(NSArray<ContactModel *> *)contactObjects
{
    return [self handleContactObjects:contactObjects groupingByKeyPath:@"name" sortInGroupKeyPath:@"name"];
}

- (NSArray<NSMutableDictionary *>*)handleContactObjects:(NSArray<ContactModel *> *)contactObjects groupingByKeyPath:(NSString *)keyPath sortInGroupKeyPath:(NSString *)sortInGroupkeyPath
{

    UILocalizedIndexedCollation * localizedCollation = [UILocalizedIndexedCollation currentCollation];

    //初始化数组返回的数组
    NSMutableArray <NSMutableArray *> * contacts = [NSMutableArray arrayWithCapacity:0];

    /// 注:
    /// 为什么不直接用27，而用count呢，这里取决于初始化方式
    /// 初始化方式为[[Class alloc] init],那么这个count = 0
    /// 初始化方式为[Class currentCollation],那么这个count = 27

    //根据UILocalizedIndexedCollation的27个Title放入27个存储数据的数组
    for (NSInteger i = 0; i < localizedCollation.sectionTitles.count; i++)
    {
        [contacts addObject:[NSMutableArray arrayWithCapacity:0]];
    }

    //开始遍历联系人对象，进行分组
    for (ContactModel * contactObject in contactObjects)
    {
        //获取名字在UILocalizedIndexedCollation标头的索引数
        NSInteger section = [localizedCollation sectionForObject:contactObject collationStringSelector:NSSelectorFromString(keyPath)];
        //获取索引对应的字母
        contactObject.firstLetter = localizedCollation.sectionTitles[section];
        //根据索引在相应的数组上添加数据
        [contacts[section] addObject:contactObject];
    }

    //对每个同组的联系人进行排序
    for (NSInteger i = 0; i < localizedCollation.sectionTitles.count; i++)
    {
        //获取需要排序的数组
        NSMutableArray * tempMutableArray = contacts[i];
        //这里因为需要通过nameObject的name进行排序，排序器排序(排序方法有好几种，楼主选择的排序器排序)
        NSSortDescriptor * sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:sortInGroupkeyPath ascending:true];
        [tempMutableArray sortUsingDescriptors:@[sortDescriptor]];
        contacts[i] = tempMutableArray;

    }

    //新建一个temp空的数组（目的是为了在调用enumerateObjectsUsingBlock函数的时候把空的数组添加到这个数组里，
    //在将数据源空数组移除，或者在函数调用的时候进行判断，空的移除）
    NSMutableArray *temp = [NSMutableArray new];
    [contacts enumerateObjectsUsingBlock:^(NSMutableArray * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.count == 0) {
            [temp addObject:obj];
        }
    }];
    //移除空数组
    [contacts removeObjectsInArray:temp];

    //最终返回的数据
    NSMutableArray* lastArray = [NSMutableArray arrayWithCapacity:1];
    [contacts enumerateObjectsUsingBlock:^(NSMutableArray * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [obj enumerateObjectsUsingBlock:^(ContactModel *  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setObject:model.name  forKey:@"fullName"];
            [dict setObject:model.phoneNumber forKey:@"phoneNumber"];
            [dict setObject:model.firstLetter forKey:@"firstLetter"];
            [lastArray addObject:dict];
        }];
    }];
    //返回
    return lastArray;
}
@end
