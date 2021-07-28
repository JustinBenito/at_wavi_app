import 'package:at_wavi_app/model/user.dart';
import 'package:at_wavi_app/utils/at_enum.dart';

import 'at_key_set_service.dart';

class ChangePrivacyService {
  ChangePrivacyService._();
  static ChangePrivacyService _instance = ChangePrivacyService._();
  factory ChangePrivacyService() => _instance;

  late User user;

  ///Returns 'true' on storing all fields in secondary.
  Future<bool> storeInSecondary([isCheck, scanKeys]) async {
    //storing detail fields
    for (FieldsEnum field in FieldsEnum.values) {
      var data = this.get(field.name);
      if (field == FieldsEnum.ATSIGN) {
        continue;
      }
      if (data.value != null) {
        // String key = atkeys.get(field.name);
        var isUpdated = await AtKeySetService()
            .update(data, field.name, isCheck: isCheck, scanKeys: scanKeys);
        if (!isUpdated) return isUpdated;
      }
    }
    // storing custom fields
    Map<String, List<BasicData>> customFields = user.customFields;
    if (customFields != null) {
      for (var field in customFields.entries) {
        if (field.value == null) {
          continue;
        }
        var isUpdated = await AtKeySetService().updateCustomFields(
            field.key, field.value,
            isCheck: isCheck, scanKeys: scanKeys);
        print('For $field update $isUpdated');
        if (!isUpdated) return isUpdated;
      }
    }
    return true;
  }

  setAllPrivate(private, User user) async {
    this.user = user;
    user.allPrivate = private;
    for (var field in FieldsEnum.values) {
      if ((field == FieldsEnum.ATSIGN)) {
        continue;
      }
      await setPrivacy(field.name, private);
    }
    var customFields =
        user.customFields.values.expand((element) => element).toList();
    for (var field in customFields) {
      field.isPrivate = private;
    }
    for (var field in user.customFields.entries) {
      for (var _key in field.value) {
        print('For $field update ${_key.isPrivate}');
      }
    }

    await storeInSecondary(true);
  }

  dynamic setPrivacy(property, value) async {
    BasicData field = this.get(property);
    if (user.allPrivate != null && user.allPrivate == true)
      field.isPrivate = true;
    else
      field.isPrivate =
          field.value != '' && field.value != null ? value : false;
    if (field.value == null) {
      return;
    }
    print('vaslue ${field.value} ${property}');
    // await AtKeySetService().update(field, property, isCheck: true);
  }

  dynamic get(String propertyName) {
    var _mapRep = _toMap();
    if (_mapRep.containsKey(propertyName)) {
      return _mapRep[propertyName];
    }
    throw ArgumentError('propery not found');
  }

  Map<dynamic, dynamic> _toMap() {
    return {
      FieldsEnum.ATSIGN.name: user.atsign,
      FieldsEnum.IMAGE.name: user.image,
      FieldsEnum.FIRSTNAME.name: user.firstname,
      FieldsEnum.LASTNAME.name: user.lastname,
      FieldsEnum.PHONE.name: user.phone,
      FieldsEnum.EMAIL.name: user.email,
      FieldsEnum.ABOUT.name: user.about,
      FieldsEnum.LOCATION.name: user.location,
      FieldsEnum.LOCATIONNICKNAME.name: user.locationNickName,
      FieldsEnum.PRONOUN.name: user.pronoun,
      FieldsEnum.TWITTER.name: user.twitter,
      FieldsEnum.FACEBOOK.name: user.facebook,
      FieldsEnum.LINKEDIN.name: user.linkedin,
      FieldsEnum.INSTAGRAM.name: user.instagram,
      FieldsEnum.YOUTUBE.name: user.youtube,
      FieldsEnum.TUMBLR.name: user.tumbler,
      FieldsEnum.MEDIUM.name: user.medium,
      FieldsEnum.PS4.name: user.ps4,
      FieldsEnum.XBOX.name: user.xbox,
      FieldsEnum.STEAM.name: user.steam,
      FieldsEnum.DISCORD.name: user.discord,
    };
  }
}
