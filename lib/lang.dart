

import 'dart:convert';

import 'package:flutter/services.dart';

class LanguageManager {
  var data, something;
  bool loading = true;

  Future<void> load() async {
    print('initializing language manager ...');
    data = jsonDecode(await rootBundle.loadString('json/en_ar.json'));
    loading = false;
  }
}