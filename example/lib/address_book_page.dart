import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_contact_picker/easy_contact_picker.dart';

class AddressBookPage extends StatefulWidget {
  @override
  _AddressBookPageState createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage> with AutomaticKeepAliveClientMixin{

  List<Contact> _list = [];
  final EasyContactPicker _contactPicker = new EasyContactPicker();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _openAddressBook();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("通讯录"),
      ),
      body: ListView.builder(
        itemBuilder: (context, index){
          return _getItemWithIndex(_list[index]);
        },
        itemCount: _list.length,
      )
    );
  }

  Widget _getItemWithIndex(Contact contact){
    return Container(
      height: 45,
      padding: EdgeInsets.only(left: 13),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(contact.fullName??""),
          Text(contact.phoneNumber??"",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  _openAddressBook() async{

    if (await Permission.contacts.request().isGranted) {
      _getContactData();
    }
  }

  _getContactData() async{
    List<Contact> list = await _contactPicker.selectContacts();
    setState(() {
      _list = list;
    });
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;

}
