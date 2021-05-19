import 'package:easy_contact_picker/easy_contact_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HostPage extends StatefulWidget {
  @override
  _HostPageState createState() => _HostPageState();

}

class _HostPageState extends State<HostPage> with AutomaticKeepAliveClientMixin{

  Contact _contact = new Contact(fullName: "", phoneNumber: "");
  final EasyContactPicker _contactPicker = new EasyContactPicker();

  _openAddressBook() async{
    if (await Permission.contacts.request().isGranted) {
      _getContactData();
    }
  }

  _getContactData() async{
    Contact contact = await _contactPicker.selectContactWithNative();
    setState(() {
      _contact = contact;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("首页"),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(13, 20, 13, 10),
            child: Row(
              children: <Widget>[
                Text("姓名："),
                Text(_contact.fullName??'')
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(13, 0, 13, 20),
            child: Row(
              children: <Widget>[
                Text("手机号："),
                Text(_contact.phoneNumber??'')
              ],
            ),
          ),
          TextButton(
            child: Text("打开通讯录"),
            onPressed: _openAddressBook,
          )
        ],
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
