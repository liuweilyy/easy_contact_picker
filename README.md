# easy_contact_picker

Flutter 通讯录联系人选择器，同时支持Android和iOS。

## 特性
在调用获取联系人方法之前需要先获取获取权限,<br>
可以打开Native通讯录选择联系人，也可以返回通讯录列表，自己构建UI。
## 用法
### 添加这一行到pubspec.yaml
```
  easy_contact_picker: ^0.0.2
```

### 引用
```
import 'package:easy_contact_picker/easy_contact_picker.dart';
```
### 添加权限
#### Android
```
<!-- 读取联系人 -->
<uses-permission android:name="android.permission.READ_CONTACTS"/>
```
#### iOS<br>
##### info.plist中添加读取通讯录权限
``` 
Privacy - Contacts Usage Description
```
##### Background Modes中 Background fetch 和 Remote notification打对勾

### 示例1 打开Native通讯录<br>
#### 1.EasyContactPicker中打开Native通讯录方法
```
Future<List<Contact>> selectContacts() async {
    final List result =
    await _channel.invokeMethod('selectContactList');
    if (result == null) {
      return null;
    }
    List<Contact> contacts = new List();
    result.forEach((f){
      contacts.add(new Contact.fromMap(f));
    });
    return contacts;
  }
```
#### 2.调用示例<br>
##### Widget中声明<br>
```
Contact _contact = new Contact(fullName: "", phoneNumber: "");
final EasyContactPicker _contactPicker = new EasyContactPicker();
```
##### Widget中调用<br>
```
_getContactData() async{
    Contact contact = await _contactPicker.selectContactWithNative();
    setState(() {
      _contact = contact;
    });
  }
```
#### 示例2 返回通讯录数组<br>
##### 1.EasyContactPicker中返回通讯录数组方法
```
Future<Contact> selectContactWithNative() async {
    final Map<dynamic, dynamic> result =
    await _channel.invokeMethod('selectContactNative');
    if (result == null) {
      return null;
    }
    return new Contact.fromMap(result);
  }
```
##### 2.调用示例<br>
###### Widget中声明<br>
```
  List<Contact> _list = new List();
  final EasyContactPicker _contactPicker = new EasyContactPicker();
```
##### Widget中调用<br>
```
_getContactData() async{
    List<Contact> list = await _contactPicker.selectContacts();
    setState(() {
      _list = list;
    });
  }
```
