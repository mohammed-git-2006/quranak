import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quranak/pages/offline_reading.dart';
import 'package:quranak/pages/statistics.dart';
import 'package:quranak/lang.dart';
import 'package:quranak/pages/choose_surah.dart';
import 'package:quranak/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_data.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

var language = 0;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();    

  runApp(MaterialApp(
    routes: {
      '/start' : (context) => FirstHome(),
      '/home' : (context) => HomePage(),
      '/statistics' : (context) => StatisticsPage(),
      '/offline_reading' : (context) => ChoosePDF(),
      '/choose_surah' : (context) => ChooseSurahPage()
    },
    theme: ThemeData(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)
          )
        )
      ),
      colorScheme: ColorScheme.light(primary: c1),
      appBarTheme: AppBarTheme(
        backgroundColor: c1,

      ),
      indicatorColor: c1,
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: Colors.green),
      inputDecorationTheme: InputDecorationTheme(
        focusColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(width: 5)
        ),
        fillColor: Colors.black
      ),
      fontFamily: 'Roboto',
      fontFamilyFallback: ['Cairo'],
      //backgroundColor: Colors.white,
      primaryColor: c1,

    ),
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Quranak'),
      ),
      body: FirstHome(),
    ),
  ));
}

class FirstHome extends StatefulWidget {
  const FirstHome({super.key});

  @override
  State<FirstHome> createState() => _FirstHomeState();
}

class _FirstHomeState extends State<FirstHome> {
  int state_loaded = 0;
  int page_index = 0;
  bool loading_json_data = true;
  bool first_time_indc = false;
  LanguageManager lm = LanguageManager();

  @override
  void initState() {
    super.initState();

    lm.load().then((value) => setState(() => loading_json_data = false));
    //SharedPreferences.getInstance().then((value) => value.clear());

  } //int language = 0; // default to english

  Future<void> set_state_to1() async {
    setState(() => loading_json_data = true);
    final pref = await SharedPreferences.getInstance();
    await pref.setInt('state', 1);
    Navigator.popAndPushNamed(context, '/home');
  }

  String get_text(String name) {
    return lm.data['$name$language'] ?? '{EMPTY}';
  }

  Widget loading_screen() {
    return Center(child: CircularProgressIndicator(color: c1,));
  }


  Widget loading_home_screen() {
    return Placeholder();
  }

  Widget get_radio_button(int l) {
    return Center(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Radio(value: l, groupValue: language, onChanged: (value) {
            setState(() {
              language = value as int;
            });
          }, fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return c1.withOpacity(.32);
            }
            return c1;
          }),),

          SizedBox(width: 15,),

          Text(l == 0 ? "English" : "العربية" , style:  const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18
          ),)
        ],
      ),
    );
  }

  Widget get_banner_view(String tn, String im) {
    return Column(
      children: [
        Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              get_text(tn),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 23,
              ),
            )
        ),

        SizedBox(height: 25,),
        Padding(
          padding: EdgeInsets.all(5),
          child: Image(image: AssetImage(im),
              width: MediaQuery.of(context).size.width * .5),
        )
      ],
    );
  }

  Widget get_current_step() {
    switch(page_index) {
      case 0:
        return Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              get_radio_button(0),

              SizedBox(height: 15,),

              get_radio_button(1)
            ],
          )
        );

      case 1:
        return get_banner_view('SLIDE_1_', 'images/Quran_vec.jpg');

      case 2:
        return get_banner_view('SLIDE_2_', 'images/Quran_reading_vec.png');
    }



    setState(() {
      page_index = 0;
    });

    return get_current_step();
  }

  Widget first_time() {
    return Column(
      children: [
        Expanded(
          child: Center(child: get_current_step())
        ),

        Padding(
          padding: EdgeInsets.all(0),
          child: SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              borderRadius: BorderRadius.zero,
              color: Theme.of(context).primaryColor,
              child: Container(
                child: Text(get_text('N'), style: const TextStyle(
                  fontFamily: 'DM',
                  fontFamilyFallback: ['Cairo'],
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black
                ),),
              ),
              onPressed: () => setState(() {
                if(page_index == 2)
                  set_state_to1();

                set_language_to_pref();
                page_index ++;
              }),
            ),
          ),
        )
      ],
    );
  }

  Future<void> set_language_to_pref() async {
    final pref = await SharedPreferences.getInstance();
    await pref.setInt('language', language);
  }

  Future<void> check_state() async {
    final pref = await SharedPreferences.getInstance();
    
    final keys = pref.getKeys();
    
    for(String key in keys) {
      print("$key ==> ${pref.get(key)}");
    }

    state_loaded = pref.getInt('state') ?? 0;
    // state_loaded = 0;

    if (state_loaded == 1)
      Navigator.popAndPushNamed(context, '/home');

    //await pref.setInt('state', 1);
  }

  @override
  Widget build(BuildContext context) {
    if(loading_json_data)
      return loading_screen();

    check_state();

    print('MAIN_PAGE ==> STATE ==> $state_loaded');

    switch(state_loaded) {
      case 1:
        Navigator.pushNamed(context, '/home');
        break;

      case 0:
        return first_time();
    }

    return Center(child: CircularProgressIndicator(),);
  }
}

