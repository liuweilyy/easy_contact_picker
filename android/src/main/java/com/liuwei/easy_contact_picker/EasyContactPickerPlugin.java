package com.liuwei.easy_contact_picker;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.provider.ContactsContract;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** EasyContactPickerPlugin */
public class EasyContactPickerPlugin
    implements MethodCallHandler, PluginRegistry.ActivityResultListener, FlutterPlugin, ActivityAware {

  private static final String CHANNEL = "plugins.flutter.io/easy_contact_picker";
  // 跳转原生选择联系人页面
  static final String METHOD_CALL_NATIVE = "selectContactNative";
  // 获取联系人列表
  static final String METHOD_CALL_LIST = "selectContactList";

  private ContactsCallBack contactsCallBack;

  // Change constructor access modifier to public
  public EasyContactPickerPlugin() {
  }

  /** update plugin to implement FlutterPlugin : start */
  /**
   * * import io.flutter.embedding.engine.plugins.FlutterPlugin;
   * * import androidx.annotation.NonNull;
   * * import io.flutter.plugin.common.BinaryMessenger;
   */
  private MethodChannel channel;

  public void initPlugin(BinaryMessenger binaryMessenger, Context context) {
    channel = new MethodChannel(binaryMessenger, CHANNEL);
    channel.setMethodCallHandler(this);
  }

  public void deInitPlugin() {
    if (null != channel) {
      channel.setMethodCallHandler(null);
      channel = null;
    }
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
    initPlugin(binding.getBinaryMessenger(), binding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
    deInitPlugin();
  }

  /** update plugin to implement FlutterPlugin : end */

  /** update plugin to implement ActivityAware : start */
  /**
   * implement PluginRegistry.RequestPermissionsResultListener for
   * addRequestPermissionsResultListener
   */
  /**
   * implement PluginRegistry.ActivityResultListener for addActivityResultListener
   */
  /** import io.flutter.embedding.engine.plugins.activity.ActivityAware; */
  /**
   * import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
   */

  private Activity activity;

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
    binding.addActivityResultListener(this);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivity() {
    dispose();
  }

  private void dispose() {
    deInitPlugin();
    this.activity = null;
  }

  private boolean runOnUiThread(Runnable runnable) {
    if (activity != null) {
      activity.runOnUiThread(runnable);
      return true;
    }
    return false;
  }

  /** update plugin to implement ActivityAware : end */

  @Override
  public void onMethodCall(MethodCall call, final Result result) {
    if (call.method.equals(METHOD_CALL_NATIVE)){
      contactsCallBack = new ContactsCallBack() {
        @Override
        void successWithMap(HashMap<String, String> map) {
          super.successWithMap(map);
          result.success(map);
        }

        @Override
        void error() {
          super.error();
        }
      };
      runOnUiThread(new Runnable() {
        @Override
        public void run() {
          intentToContact();
        }
      });
    }
    else if (call.method.equals(METHOD_CALL_LIST)){
      contactsCallBack = new ContactsCallBack() {
        @Override
        void successWithList(List<HashMap> contacts) {
          super.successWithList(contacts);
          result.success(contacts);
        }

        @Override
        void error() {
          super.error();
        }
      };
      getContacts();
    }
  }

  /** 跳转到联系人界面. */
  private void intentToContact() {
    if (null == activity)
      return;
    Intent intent = new Intent();
    intent.setAction("android.intent.action.PICK");
    intent.addCategory("android.intent.category.DEFAULT");
    intent.setType("vnd.android.cursor.dir/phone_v2");
    activity.startActivityForResult(intent, 0x30);
  }

  private void getContacts(){
    if (null == activity)
      return;
    //（实际上就是“sort_key”字段） 出来是首字母
    final String PHONE_BOOK_LABEL = "phonebook_label";
    //需要查询的字段
    final String[] CONTACTOR_ION = new String[]{
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER,
            PHONE_BOOK_LABEL
    };

    List contacts = new ArrayList<>();
    Uri uri = null;
    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN_MR2) {
      uri = ContactsContract.CommonDataKinds.Contactables.CONTENT_URI;
    }
    //获取联系人。按首字母排序
    Cursor cursor = activity.getContentResolver().query(uri, CONTACTOR_ION, null, null,
        ContactsContract.CommonDataKinds.Phone.SORT_KEY_PRIMARY);
    if (cursor != null) {

      while (cursor.moveToNext()) {
        HashMap<String, String> map = new HashMap<String, String>();
        int nameIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME);
        int phoneNumIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER);
        int firstCharIndex = cursor.getColumnIndex(PHONE_BOOK_LABEL);

        if (nameIndex != -1 && phoneNumIndex != -1 && firstCharIndex != -1) {
          String name = cursor.getString(nameIndex);
          String phoneNum = cursor.getString(phoneNumIndex);
          String firstChar = cursor.getString(firstCharIndex);
          map.put("fullName", name);
          map.put("phoneNumber", phoneNum);
          map.put("firstLetter", firstChar);

          contacts.add(map);
        }
      }
      cursor.close();
      contactsCallBack.successWithList(contacts);
    }

  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    if (requestCode == 0x30 && null != activity) {
      if (data != null) {
        Uri uri = data.getData();
        String phoneNum = null;
        String contactName = null;
        // 创建内容解析者
        ContentResolver contentResolver = activity.getContentResolver();
        Cursor cursor = null;
        if (uri != null) {
          cursor = contentResolver.query(uri,
                  new String[]{"display_name","data1"},null,null,null);
        }
        while (cursor.moveToNext()) {
          int contactNameIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME);
          int phoneNumIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER);
          if (contactNameIndex != -1 && phoneNumIndex != -1) {
            contactName = cursor.getString(contactNameIndex);
            phoneNum = cursor.getString(phoneNumIndex);
          }
        }
        cursor.close();
        //  把电话号码中的  -  符号 替换成空格
        if (phoneNum != null) {
          phoneNum = phoneNum.replaceAll("-", " ");
          // 空格去掉  为什么不直接-替换成"" 因为测试的时候发现还是会有空格 只能这么处理
          phoneNum= phoneNum.replaceAll(" ", "");
        }
        HashMap<String, String> map =  new HashMap<String, String>();
        map.put("fullName", contactName);
        map.put("phoneNumber", phoneNum);
        contactsCallBack.successWithMap(map);
      }
    }
    return false;
  }

  /** 获取通讯录回调. */
  public abstract class ContactsCallBack{
    void successWithList(List<HashMap> contacts){};
    void successWithMap(HashMap<String, String> map){};
    void error(){};
  }
}
