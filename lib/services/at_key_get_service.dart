import 'dart:convert';

import 'package:at_base2e15/at_base2e15.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_wavi_app/model/user.dart';
import 'package:at_wavi_app/services/at_key_set_service.dart';
import 'package:at_wavi_app/services/backend_service.dart';
import 'package:at_wavi_app/utils/at_enum.dart';
import 'package:at_wavi_app/utils/at_key_constants.dart';

class AtKeyGetService {
  AtKeyGetService._();
  static AtKeyGetService _instance = AtKeyGetService._();
  factory AtKeyGetService() => _instance;
  Map<dynamic, dynamic> _tempObject = {};
  User user = User(allPrivate: false, atsign: '');

  init() {
    user = User(allPrivate: false, atsign: '');
    user.allPrivate = false;
    user.atsign = BackendService().atClientInstance.currentAtSign!;
  }

// TODO: for testing only
  deleteKeys() async {
    var scanKeys = await BackendService().getAtKeys();
    for (var key in scanKeys) {
      await BackendService().atClientInstance.delete(key);
    }
  }

  ///fetches [atsign] profile.
  Future<User?> getProfile({String? atsign}) async {
    bool _containsPrivateAccountKey = false;
    try {
      // _setUser(atsign: atsign);
      atsign = atsign ?? BackendService().atClientInstance.currentAtSign;
      var scanKeys = await BackendService().getAtKeys();
      user.allPrivate = true;
      for (var key in scanKeys) {
        await _performLookupAndSetUser(key);
        // if (!result) errorCallBack(false);

        if (key.key!.contains(FieldsEnum.PRIVATEACCOUNT.name)) {
          _containsPrivateAccountKey = true;
        }
      }

      await createPrivateAccountKey(atsign!, _containsPrivateAccountKey);
      return user;
      // _container.updateWidgets();
      // successCallBack(true);
      // await _sdkService.sync();
    } catch (err) {
      // _logger.severe('Fetching ${_sdkService.currentAtsign} throws $err');
      // errorCallBack(err);
      print('Error in getProfile $err');
      return null;
    }
  }

  /// check & create 'PRIVATEACCOUNT key
  createPrivateAccountKey(
      String atsign, bool _containsPrivateAccountKey) async {
    try {
      if (atsign == BackendService().atClientInstance.currentAtSign) {
        if (!_containsPrivateAccountKey) {
          await AtKeySetService().update(
              BasicData(value: user.allPrivate.toString()),
              FieldsEnum.PRIVATEACCOUNT.name);
        }
      }
    } catch (err) {
      print('Error in createPrivateAccountKey $err');
    }
  }

  ///Returns `true` on fetching value for [atKey].
  Future<bool> _performLookupAndSetUser(AtKey atKey) async {
    var isSetUserField = false;
    var isCustom;
    if (atKey.key == null) {
      return false;
    }

    isCustom = atKey.key!.contains(AtText.CUSTOM);
    if (atKey.key == FieldsEnum.IMAGE.name) {
      atKey.metadata!.isBinary = true;
    }

    var successValue = await BackendService().atClientInstance.get(atKey);
    if (successValue.value != null) {
      print('fetched value ${successValue.value} for key ${atKey.key}');
      isSetUserField = _setUserField(atKey.key, successValue.value, isCustom,
          isPublic: successValue.metadata?.isPublic);
    }
    return isSetUserField;
  }

  /// sets user field with [value].
  bool _setUserField(var key, var value, bool isCustom, {bool? isPublic}) {
    try {
      bool isPrivate = true;
      if (isPublic != null && isPublic) {
        isPrivate = false;
      }
      _tempObject[key] = value;
      if (isCustom) {
        _setCustomField(value, isPrivate);
        return true;
      }
      set(key, value, isPrivate: isPrivate);
    } catch (ex) {
      // _logger.severe('setting the $key key for user throws ${ex.toString()}');
    }
    return true;
  }

  ///sets user customFields.
  void _setCustomField(String response, isPrivate) {
    var json = jsonDecode(response);
    if (json != 'null' && json != null) {
      String category = json[CustomFieldConstants.category];
      var type = getType(json[CustomFieldConstants.type]);
      var value = getCustomContentValue(type: type, json: json);
      String label = json[CustomFieldConstants.label];
      String? valueDescription = json[CustomFieldConstants.valueDescription];
      BasicData basicData = BasicData(
          accountName: label,
          value: value,
          isPrivate: isPrivate,
          type: type,
          valueDescription: valueDescription ?? '');
      // _container.createCustomField(basicData, category.toUpperCase());
      if (user.customFields[category.toUpperCase()] == null) {
        user.customFields[category.toUpperCase()] = [];
      }
      user.customFields[category.toUpperCase()]!.add(basicData);

      if (!basicData.isPrivate) {
        user.allPrivate = false;
      }
    }
  }

  ///Feches type of customField.
  getType(type) {
    if (type is String) {
      return type;
    }
    if (type[CustomFieldConstants.name] == CustomFieldConstants.txtInNumber)
      return CustomContentType.Number.name;
    else if (type[CustomFieldConstants.name] == CustomFieldConstants.txtInText)
      return CustomContentType.Text.name;
    else if (type[CustomFieldConstants.name] == CustomFieldConstants.txtInUrl)
      return CustomContentType.Link.name;
  }

  ///parses customField value from [json] based on type.
  getCustomContentValue({required var type, required var json}) {
    if (type == CustomContentType.Image.name) {
      return Base2e15.decode(json[CustomFieldConstants.value]);
    } else if (type == CustomContentType.Youtube.name) {
      if (json[CustomFieldConstants.valueLabel] != null &&
          json[CustomFieldConstants.valueLabel] != '') {
        return json[CustomFieldConstants.valueLabel];
      }
      return json[CustomFieldConstants.value];
    } else {
      return json[CustomFieldConstants.value];
    }
  }

  Map<dynamic, dynamic> objectReference() {
    return _tempObject;
  }

  dynamic set(property, value, {isPrivate, valueDescription}) {
    if (user == null) user = User();
    isPrivate = user.allPrivate == true ? true : isPrivate;
    FieldsEnum field = valueOf(property);

    var data = formData(property, value,
        private: isPrivate, valueDescription: valueDescription);
    switch (field) {
      case FieldsEnum.ATSIGN:
        user.atsign = value;
        break;
      case FieldsEnum.IMAGE:
        user.image = data;
        break;
      case FieldsEnum.FIRSTNAME:
        user.firstname = data;
        break;
      case FieldsEnum.LASTNAME:
        user.lastname = data;
        break;
      case FieldsEnum.PHONE:
        user.phone = data;
        break;
      case FieldsEnum.EMAIL:
        user.email = data;
        break;
      case FieldsEnum.ABOUT:
        user.about = data;
        break;
      case FieldsEnum.PRONOUN:
        user.pronoun = data;
        break;
      case FieldsEnum.LOCATION:
        user.location = data;
        break;
      case FieldsEnum.LOCATIONNICKNAME:
        user.locationNickName = data;
        break;
      case FieldsEnum.TWITTER:
        user.twitter = data;
        break;
      case FieldsEnum.FACEBOOK:
        user.facebook = data;
        break;
      case FieldsEnum.LINKEDIN:
        user.linkedin = data;
        break;
      case FieldsEnum.INSTAGRAM:
        user.instagram = data;
        break;
      case FieldsEnum.YOUTUBE:
        user.youtube = data;
        break;
      case FieldsEnum.TUMBLR:
        user.tumbler = data;
        break;
      case FieldsEnum.MEDIUM:
        user.medium = data;
        break;
      case FieldsEnum.PS4:
        user.ps4 = data;
        break;
      case FieldsEnum.XBOX:
        user.xbox = data;
        break;
      case FieldsEnum.STEAM:
        user.steam = data;
        break;
      case FieldsEnum.DISCORD:
        user.discord = data;
        break;
      default:
        break;
    }
  }
}

class CustomFieldConstants {
  static const String label = 'label';
  static const String value = 'value';
  static const String valueLabel = 'valueLabel';
  static const String category = 'category';
  static const String type = 'type';
  static const String name = 'name';
  static const String valueDescription = 'valueDescription';
  static const String txtInNumber = 'TextInputType.number';
  static const String txtInText = 'TextInputType.text';
  static const String txtInUrl = 'TextInputType.url';
}
