import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quranak/lang.dart';
import 'package:quranak/theme_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

var glob_dict;

class TestHome extends StatefulWidget {
  const TestHome({super.key});

  @override
  State<TestHome> createState() => _TestHomeState();
}

class _TestHomeState extends State<TestHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Placeholder(),
    );
  }
}

class OnLoad_Data { // <ONLOAD>
  String name = '';
  int language = 0;
  int hasanat_counter = 0;
  String current_surah = '';
  int current_surah_index = 0;
  int current_ayah = 0;
  int surah_offset = 0;
  List<String> surahs_done = ['5', '3', '5', '6'];
}


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage>  with TickerProviderStateMixin {
  bool loading_json = true, loading_ud = true, loading_quran = true, set_controller_on_load = true;
  bool calculating_offset = true;
  double sw = 0;
  OnLoad_Data ud = new OnLoad_Data();
  LanguageManager lm = LanguageManager();
  bool moved_to_choosing = false, init_reader_loaded = false;
  dynamic quran = {}, readers = {};
  int verses_count = 0;
  List<int> verses_ilist = [];
  CarouselSliderController carousel_controller = CarouselSliderController();
  var audio_player = AudioPlayer();
  BannerAd? _bannerAd;
  int reader_selected = 0, verses_count_with_ads = 0;
  String reader_name_url = '';
  List<List> carousel_items = [];
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isLoad = false;


  void scheduleReminder() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      '01',
      'repeated_channel',
      channelDescription: 'Channel for daily reminders to read quran',
      importance: Importance.max,
      priority: Priority.high,
      showProgress: false
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    flutterLocalNotificationsPlugin.periodicallyShow(
      0,
      get_text('T'),
      ud.language == 0 ? 'Continue Reading Quran!' : 'متابعة القرائة',
      RepeatInterval.hourly,
      platformChannelSpecifics,
    ).onError((e, _) {
      log('NOTIFICATIONS PROB : $e');
    },);

    //flutterLocalNotificationsPlugin.
    /*flutterLocalNotificationsPlugin.periodicallyShowWithDuration(1, 'hello', 'hello', const Duration(minutes: 1), NotificationDetails(
      android: AndroidNotificationDetails('hello', 'hello', priority: Priority.max)
    ));*/

  }



  String get_text(String name) {
    return lm.data['$name${ud.language}'] ?? 'EMPTY';
  }

  @override
  void initState() {

    lm.load().then((value) => setState(() {
      loading_json = false;
      glob_dict = lm.data;
    }));

    this.scheduleReminder();

    AwesomeNotifications().isNotificationAllowed().then((v) {
      if (!v)AwesomeNotifications().requestPermissionToSendNotifications();
    });

    //audio_player.setReleaseMode(ReleaseMode.stop);

    /*flutterLocalNotificationsPlugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings(
            '@mipmap/ic_launcher'
        )
    )).then((value) => this.show_notification()).onError((error, stackTrace) => print("[%%%-] $error"));*/

    load_quran();

    super.initState();
  }


  // TODO: replace this test ad unit with your own ad unit.
  final BannerAdUnitId1 = 'ca-app-pub-4980834571806250/3960538721';//'ca-app-pub-4980834571806250/3960538721';
  //final BannerAdUnitId2 = 'ca-app-pub-3940256099942544/9214589741';//'ca-app-pub-4980834571806250/5806073057';

  Future<void> show_notification() async {
    /*AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'interactive_channel_id',
      'Presistent Notification',
      channelDescription: 'Description',
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      ongoing: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'play_action',
          'Play',
          icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          showsUserInterface: false,
          cancelNotification: false
        ),
      ]
    );



    flutterLocalNotificationsPlugin.show(0, 'Hello', 'Hello',
        NotificationDetails(android: androidNotificationDetails));*/
    this.scheduleReminder();
  }

  void load_ad() async {
    if(_isLoad)
      return;
    // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
    /*final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        MediaQuery.sizeOf(context).width.truncate());*/
    final size = await AdSize.banner;

    _bannerAd = BannerAd(
      adUnitId: BannerAdUnitId1,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _isLoad = true;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          // Dispose the ad here to free resources.
          ad.dispose();
        },
      ),
    )..load();

  }


  void open_app() async {
    final app_store_url = 'https://play.google.com/store/apps/details?id=com.mdapps.quranak';
    final url = Uri.parse(app_store_url);
    if (await canLaunchUrl(url)) {
      launchUrl(url);
    }
  }

  Widget button_view(String name, bool dialog, Icon icon, BuildContext ctx) {
    return MaterialButton(
      onPressed: () {
        if (!dialog) {
          open_app();
          return;
        }

        showDialog(context: context, builder: (BuildContext c) {
          return AlertDialog(
            title: Text(get_text('T')),
            content: Text(get_text('ABOUTC')),
          );
        });
      },
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: ud.language == 0? TextDirection.ltr : TextDirection.rtl,
          children: [
            Text(name, style: TextStyle(fontSize: 14),),icon
          ],
        ),
      ),
    );
  }

  Widget loading_screen() {
    return Center(child: CircularProgressIndicator(),);
  }

  Future<void> load_user_data() async {
    //HomeWidget.saveWidgetData<String>('quranak', 'Mohammed');

    final pref = await SharedPreferences.getInstance();

    ud.name = pref.getString('name') ?? '{EMPTY}';
    ud.language = pref.getInt('language') ?? 0;
    ud.hasanat_counter = pref.getInt('hasanat_counter') ?? 0;
    ud.current_surah = pref.getString('current_surah_' + (ud.language == 0? 'en' : 'ar')) ?? 'EMPTY';
    ud.current_surah_index = pref.getInt('current_surah_index') ?? 0;

    log('${ud.current_surah_index} - ${ud.current_ayah}');

    if (ud.current_surah == 'EMPTY') {
      Navigator.pushNamed(context, '/choose_surah').then((value) {
        setState(() {
          calculating_offset = true;
          load_user_data();
          carousel_controller.jumpToPage(0);
        });
      });
    }

    ud.current_ayah = pref.getInt('${ud.current_surah_index}_counter') ?? 0;
    verses_count = quran[ud.current_surah_index-1]['total_verses'];

    if(calculating_offset){
      calculating_offset = false;
      ud.surah_offset = 1;

      int i = 1;

      print('$i == ${ud.current_surah_index}');

      while(i < (ud.current_surah_index)) {
        ud.surah_offset += (quran[i-1]['total_verses'] as int);
        i++;
      }
    }

    reader_name_url = pref.getString('reader_name') ?? (ud.language == 0 ? 'en.walk':'ar.abdurrahmaansudais');

    print('[#3] $reader_name_url');

    if(!init_reader_loaded && ud.language == 1) {
      for (int i = 0; i < readers['data'].length; ++i) {
        if (readers['data'][i]['identifier'] == reader_name_url) {
          reader_selected = i;
          init_reader_loaded = true;
          break;
        }
      }
    }

    if (ud.language == 0) {
      reader_selected = 17;
      reader_name_url = 'en.walk';
    }

    setState(() {
      loading_ud = false;
      loading_quran = false;
    });
  }

  Future<void> load_quran() async {
    quran = jsonDecode(await rootBundle.loadString('json/quran_en.json'));
    readers = jsonDecode(await rootBundle.loadString('json/readers.json'));

    load_user_data();
  }

  TextDirection get_direction() {
    return ud.language == 0 ? TextDirection.ltr : TextDirection.rtl;
  }

  Widget get_designed_button(String text, String route) {
    return Container(
      height: 50,
      margin: EdgeInsets.all(10),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) => Colors.white)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: get_direction(),
          children: [
            Text(text, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
            Icon(ud.language == 0? Icons.chevron_right:Icons.chevron_left, color: Colors.black,)
          ],
        ),
        onPressed: () {
          Navigator.pushNamed(context, route).then((_) {setState(() {
            calculating_offset = true;
            load_user_data().then((value) => carousel_controller.jumpToPage(ud.current_ayah));
          });});
        },
      ),
    );
  }

  var language_selected = [false, false];

  String get_ayah(int offset) {
    try {
      return quran[ud.current_surah_index - 1]['verses'][offset][ud.language ==
          0 ? 'translation' : 'text'];
    }catch(e){
      return 'ERROR';
    }
  }

  Widget get_ad_banner(BannerAd ad) {
    return StatefulBuilder(
      builder: (context, setState) => Container(
        child: AdWidget(ad: ad),
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        alignment: Alignment.center,
      ),
    );
  }

  Future<void> update_current_ayah() async {
    final pref = await SharedPreferences.getInstance();
    print('updating ayah to ${ud.current_ayah}');
    //pref.setInt('current_ayah', ud.current_ayah);
    pref.setInt('${ud.current_surah_index}_counter', ud.current_ayah);
  }

  late AnimationController animation_controller;


  Widget carousel_builder(BuildContext ctx, int e, int u) {
    bool _last_verse = ud.current_ayah == verses_count;
    bool _is_done = e < ud.current_ayah || _last_verse;

    log('${ud.current_ayah} -- ${verses_count} -- $e -- $u');


    final animated_container = AnimatedContainer(
      duration: const Duration(milliseconds: 1500),
      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      width: sw - 85,
      height: 250,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _is_done ? c1 : c1.withOpacity(.1),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: _is_done ? c1 : c1.withOpacity(.1),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),

      //width: sw ,
      child: Column(
        children: [
          Expanded(
            child: AutoSizeText(get_ayah(e), style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontFamily: 'Amiri',
              color: _is_done? Colors.white: Colors.black
            ), ),
          ),

          SizedBox(height: 10,),

          Row(
            textDirection: get_direction(),
            mainAxisAlignment : MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: carousel_builder_audio_func, icon: Icon(Icons.spatial_audio_off, color: _is_done?Colors.white:Colors.black,) ),
              Expanded(child: Text('${ud.current_surah}:${e+1}', style: TextStyle(color: _is_done?Colors.white:Colors.black),))
            ],
          )
        ],
      ),
    );

    log('last verse? $_last_verse');

    if (_last_verse && u+1 == verses_count) {
      return Stack(
      children: [TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: math.pi),
          duration: const Duration(milliseconds: 500   ),
          curve: Curves.easeIn,
          builder: (_, double v, __) {
            final offset = math.sin(v) * 10.0;
            return Positioned(child: animated_container, bottom: offset, top: -offset,);
          }
      ),]
    );
    }

    return animated_container;
  }

  @override
  void dispose() {
    log('onDispose');
    audio_player.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  int last_verse = 0;

  bool auto_play = false;

  void carousel_builder_audio_func() {

    final url_str = 'https://cdn.islamic.network/quran/audio/${ud.language == 1 ? readers['data'][reader_selected]["version"]:192}'
        '/${ud.language == 1 ? reader_name_url : "en.walk"}/${ud.surah_offset + ud.current_ayah - last_verse}.mp3';

    log(url_str);

    int _localCurrentAyah =ud.current_ayah+1;
    int _localCurrentSurah = ud.current_surah_index;

    audio_player.setUrl(url_str).then((v) {
      audio_player.stop();
      audio_player.play().onError((error, stackTrace) {
        print('[AUDIO_PROB]: $error');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(get_text('AUDIO_PROB')),
        ));
      }).whenComplete(() {
        if (_localCurrentAyah-1 == verses_count)
          return;
        if(_localCurrentAyah != ud.current_ayah && _localCurrentSurah == ud.current_surah_index) {
          carousel_controller.animateToPage(_localCurrentAyah);
          carousel_builder_onChanged(ud.current_ayah + 1);
        }

        if(auto_play) {
          if (_localCurrentSurah == ud.current_surah_index)
            carousel_builder_audio_func();
          else
            setState(() {
              auto_play = false;
            });
        }
      });
    });
  }

  void carousel_builder_onChanged(int v) {
    if (v >= ud.current_ayah) {
      ud.current_ayah = v;


      if(v == verses_count-1) {
        ud.current_ayah = verses_count;
        last_verse = 1;
      } else {
        last_verse = 0;
      }

      setState(() {
        if(v > 0)
          update_current_ayah();
      });
    } else {
      ud.current_ayah = v;

      if (v == verses_count - 1) {
        ud.current_ayah = verses_count;
        last_verse = 1;
      } else
        last_verse = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoad) load_ad();

    sw = MediaQuery.of(context).size.width;


    if(loading_json || loading_ud || loading_quran) return Scaffold(
      body: loading_screen(),
    );

    if(set_controller_on_load)
      set_controller_on_load = false;

    language_selected = ud.language == 0 ? [true, false] : [false, true];

    print(ud.current_ayah);


    return Scaffold(
      drawer: Container(
          color: Colors.white,
          width: MediaQuery.of(context).size.width - 100,
          padding: EdgeInsets.all(5),
          child: SafeArea(
            child: Column(
              children: [
                //button_view(get_text('CHANGE_NAME'), '/start_surah', Icon(Icons.edit, size: 15,), context),
                button_view(get_text('RATE_US'), false, Icon(Icons.star, size: 15,), context),
                button_view(get_text('ABOUT'), true, Icon(Icons.info, size: 15,), context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    textDirection: ud.language == 0? TextDirection.ltr : TextDirection.rtl,
                    children: [
                      Text(get_text('LANGUAGE')),
                      Container(
                        height: 25,
                        child: ToggleButtons(children: [
                          Text('EN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w200, color: Colors.grey)),
                          Text('AR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w200, color: Colors.grey)),
                        ], isSelected: language_selected,
                        onPressed: (int index) {
                          setState(() {
                            switch(index) {
                              case 0:

                                ud.language = 0;
                                language_selected = [true, false];
                              case 1:
                                ud.language = 1;
                                language_selected = [false, true];
                            }

                            SharedPreferences.getInstance().then((value) => value.setInt('language', ud.language));
                          });
                        }),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    textDirection: ud.language == 0? TextDirection.ltr : TextDirection.rtl,
                    children: [
                      Text(get_text('READER')),

                      SizedBox(width: 10,),

                      Expanded(
                        child: (ud.language == 0) ? Text('Ibrahim Walk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black))
                            : DropdownButton<int>(items: (readers['data'] as List).map((e) {
                          return DropdownMenuItem<int>(child: Text(e[ud.language == 0 ? 'englishName' : 'name'],
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black), overflow: TextOverflow.ellipsis), value: e['index'],
                          onTap: () => reader_selected = e['index'],);
                        }).toList(), onChanged: (v) {
                          SharedPreferences.getInstance().then((pref) {
                            print('[#5] $reader_selected');
                            pref.setString('reader_name', readers['data'][reader_selected]['identifier']).then((value) {
                              setState(() {
                                load_user_data();
                              });
                            });
                          });
                        },isExpanded: true , hint: Text(readers['data'][reader_selected][ud.language == 0 ? 'englishName' : 'name'],
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ),
      appBar: AppBar(
        title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(get_text('T'),),
          //IconButton(onPressed: () {}, icon: Icon(Icons.menu))
        ], textDirection: get_direction()),
      ),
      body:  Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CarouselSlider.builder(
            itemBuilder: carousel_builder,
            options: CarouselOptions(
                height: 250,
                padEnds: true,
                disableCenter: true,
                enableInfiniteScroll: false,
                initialPage: ud.current_ayah,
                onPageChanged: (v, r) {
                  carousel_builder_onChanged(v);
                }
            ),
            carouselController: carousel_controller,
            itemCount: verses_count,
          ),
        ),

        SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(children: [
            Text(get_text('AUTO_PLAY')),
            Switch(value: auto_play, onChanged: (v) { setState(() {auto_play = v;});})
          ], mainAxisAlignment: MainAxisAlignment.spaceBetween, textDirection: get_direction(),),
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: get_direction(),
            children: [
              Text("${ud.current_ayah+(ud.current_ayah == verses_count ? 0:1)}/$verses_count",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
              SizedBox(width: 15,),
              Expanded(
                child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.easeIn,
                  tween: Tween<double>(
                    begin: ((ud.current_ayah+1) / verses_count)-1,
                    end: ((ud.current_ayah+1) / verses_count)
                  ),
                  builder: (_, v, ___) => LinearProgressIndicator(
                    backgroundColor: c1.withOpacity(.2),
                    borderRadius: BorderRadius.circular(3.5),
                    minHeight: 10,
                    value: v,
                  ),
                ),
              )
            ],
          ),
        ),

        Expanded(
          //height: 150,
          child: SingleChildScrollView(
            child: Column(
              children: [
                get_designed_button(get_text('START_SURAH'), '/choose_surah'),
                get_designed_button(get_text('STATISTICS'), '/statistics'),
                get_designed_button(get_text('OFFLINE_READING'), '/offline_reading'),
              ],
            ),
          ),
        ),

        Platform.isAndroid && _isLoad? get_ad_banner(_bannerAd!) : SizedBox()

      ],),
    );
  }

}
