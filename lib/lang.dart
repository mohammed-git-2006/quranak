

import 'dart:convert';

import 'package:flutter/services.dart';

class LanguageManager {
  var data, something, something_else;
  bool loading = true;

  Future<void> load() async {
    print('initializing language manager ...');
    data = jsonDecode(await rootBundle.loadString('json/en_ar.json'));
    loading = false;
  }
}