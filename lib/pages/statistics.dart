

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quranak/theme_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsPage extends StatefulWidget {

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String show_t = '';
  bool loading_data = true, _isLoad = false;
  int ud_language = 0;
  List<Map<String, dynamic>> _stat = [];
  dynamic json_data = {};
  int total_verses = 0, total_ayat = 0;
  BannerAd? _bannerAd;

  Future<void> load_user_data() async {
    final pref = await SharedPreferences.getInstance();

    ud_language = pref.getInt('language') ?? 2;

    json_data = jsonDecode(await rootBundle.loadString('json/en_ar.json'));

    for(String key in pref.getKeys()) {
      if (key.endsWith('_counter')){
        //log('${int.parse(key.split("_")[0])}',name: 'stat_');
        dynamic v = json_data['SURAH_LIST$ud_language'][int.parse(key.split('_')[0])-1];
        Map<String, dynamic> new_data = {
          'index' : int.parse(key.split('_')[0]),
          'name' : v['name'] as String,
          'count' : v['count'] as int,
          'done' : pref.getInt(key) ?? 0,
        };

        if (new_data['done'] == new_data['count'])
          total_ayat ++;

        total_verses += pref.getInt(key) ?? 0;

        _stat.add(new_data);

      }
    }

    setState(() {
      loading_data = false;
    });


  }

  final BannerAdUnitId2 = 'ca-app-pub-4980834571806250/5806073057';

  void load_ad() async{
    if(_isLoad)
      return;

    _bannerAd = BannerAd(
      adUnitId: BannerAdUnitId2,
      request: const AdRequest(),
      size: AdSize.banner,
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


  @override
  void initState() {
    load_user_data();
    super.initState();
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


  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tdir = ud_language == 0 ? TextDirection.ltr : TextDirection.rtl;

    if (!_isLoad) load_ad();

    TextStyle _s1 = TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.bold
    );

    return Scaffold(
      appBar: AppBar(title: Row(
        children: [
          Text(loading_data ? '' : json_data['STATISTICS$ud_language']),
        ], textDirection: tdir,
      ),),
      body: loading_data ? Center(child: CircularProgressIndicator(),) : Column(
        children: [
          SizedBox(height: 10,),
          Container(
            //duration: const Duration(seconds: 1),
            padding: EdgeInsets.all(10),
            height: 220,
            width: 220,
            //curve: Curves.easeIn,
            child: Stack(
              children: [
                Container(
                  height: 200,
                  width: 200,
                  child: TweenAnimationBuilder(
                    duration: Duration(seconds: 1),
                    tween: Tween<double>(
                      begin: 0,
                      end: 1
                    ),
                    curve: Curves.easeInOut,
                    builder: (BuildContext context, double value, Widget? child) {
                      return CircularProgressIndicator(
                        backgroundColor: c1.withOpacity(.2),
                        value: (total_verses / 6236)* value,
                        strokeWidth: 10,
                      );
                    } ,
                  ),
                ),

                Positioned.fill(bottom: 70, child: Align(alignment: Alignment.center,child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$total_verses', style: _s1.copyWith(color: Colors.pink)),
                    Text('   /   '),
                    Text('6236', style: _s1.copyWith(color: Colors.deepPurple),),
                  ],
                ),),),

                Positioned.fill(bottom: 30, right: 85,child: Align(alignment: Alignment.center,child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${json_data["ADONE$ud_language"]}', style: TextStyle(fontSize: 10),),
                  ],
                ),),),

                Positioned.fill(bottom: 30, left: 65,child: Align(alignment: Alignment.center,child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${json_data["FV$ud_language"]}', style: TextStyle(fontSize: 10),),
                  ],
                ),),),

                /// =========================================
                /// =========================================
                /// =========================================

                Positioned.fill(top: 30, child: Align(alignment: Alignment.center,child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$total_ayat', style: _s1.copyWith(color: Colors.pink)),
                    Text('   /   '),
                    Text('114', style: _s1.copyWith(color: Colors.deepPurple),),
                  ],
                ),),),

                Positioned.fill(top: 70, right: 85,child: Align(alignment: Alignment.center,child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${json_data["SDONE$ud_language"]}', style: TextStyle(fontSize: 10),),
                  ],
                ),),),

                Positioned.fill(top: 70, left: 65,child: Align(alignment: Alignment.center,child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${json_data["FQ$ud_language"]}', style: TextStyle(fontSize: 10),),
                  ],
                ),),),
              ],
            )
          ),
          SizedBox(height: 10),

          //get_ad_banner(_bannerAd!),
          //Text('$_isLoad'),
          Platform.isAndroid && _isLoad? get_ad_banner(_bannerAd!) : SizedBox(),
          Divider(height: 1),
          Expanded(child: Directionality(
            textDirection: tdir,
            child: ListView.builder(itemBuilder: (context, index) {
              return Row(
                children: [
                  Expanded(
                    child: ListTile(
                      leading: SizedBox(width:ud_language == 0 ? 80 : 60, child: Text(_stat[index]['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),)),
                      title: LinearProgressIndicator(
                        value: _stat[index]["done"]/_stat[index]["count"],
                        backgroundColor: c1.withOpacity(.2),
                        borderRadius: BorderRadius.circular(3.5),
                        minHeight: 10,
                      ),
                      subtitle: Text('${_stat[index]["done"]}/${_stat[index]["count"]}', style: TextStyle(fontWeight: FontWeight.bold),),
                      trailing: _stat[index]['done'] == _stat[index]['count'] ? Icon(Icons.done_all, color: c1,) : null
                    ),
                  ),

                  SizedBox(width : 50,child: IconButton(onPressed: () {
                    SharedPreferences.getInstance().then((pref) {
                      pref.setString('current_surah_ar', json_data['SURAH_LIST1'][_stat[index]['index']-1]['name']);
                      pref.setString('current_surah_en', json_data['SURAH_LIST0'][_stat[index]['index']-1]['name']);
                      pref.setInt('current_surah_index', _stat[index]['index']);
                      log("${_stat[index]['index']} ==> ${json_data['SURAH_LIST1'][_stat[index]['index']]['name']}", name: 'hello');
                      Navigator.pop(context, true);
                    });
                  },icon: const Icon(Icons.chevron_right))),
                ],
              );
            },itemCount: _stat.length),
          ))
        ],
      ),
    );
  }
}
