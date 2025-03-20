import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quranak/lang.dart';
import 'package:quranak/pages/home.dart';
import 'package:quranak/theme_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChooseSurahPage extends StatefulWidget {
  const ChooseSurahPage({super.key});

  @override
  State<ChooseSurahPage> createState() => _ChooseSurahPageState();
}



class _ChooseSurahPageState extends State<ChooseSurahPage> {
  int maxDistance = 3;
  OnLoad_Data ud = OnLoad_Data();
  LanguageManager lm = LanguageManager();
  bool loading_data = true, searching = false;
  List<dynamic> surahs_list = [];
  List<dynamic> searching_results = [];
  TextEditingController search_controller = TextEditingController();

  Future<void> load_all_data() async {
    final pref = await SharedPreferences.getInstance();
    ud.language = pref.getInt('language') ?? 0;
    ud.surahs_done = pref.getStringList('surahs_done') ?? [];
    ud.current_surah = pref.getString('current_surah') ?? '';
    print("loading json data ...");
    await lm.load();
    surahs_list = lm.data['SURAH_LIST${ud.language}'];

    for(String key in pref.getKeys()) {
      log(key);
      if (key.endsWith('_counter'))
        surahs_in_pref.addAll(
            {int.parse(key.split('_')[0]): pref.getInt(key) ?? 0});
    }


    setState(() => loading_data = false);
    search_controller.addListener(() {
      print(search_controller.text);
      final t = search_controller.text;
      setState(() => searching = t.isNotEmpty);
      searching_results = searchInList(surahs_list, t, 0);
      //log(searching_results.toString());
    });
  }

// Function to calculate Levenshtein Distance (for measuring similarity)
  int levenshteinDistance(String a, String b) {
    List<List<int>> dp = List.generate(a.length + 1,
            (i) => List<int>.filled(b.length + 1, 0));

    for (int i = 0; i <= a.length; i++) dp[i][0] = i;
    for (int j = 0; j <= b.length; j++) dp[0][j] = j;

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        int cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = math.min(
            math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
            dp[i - 1][j - 1] + cost
        );
      }
    }
    return dp[a.length][b.length];
  }

  List<dynamic> searchInList(List<dynamic> list, String pattern, int maxDistance) {
    RegExp regExp = RegExp(pattern, caseSensitive: false);
    List<dynamic> results = [];

    for (var item in list) {
      if (regExp.hasMatch(item['name']) || levenshteinDistance(pattern, item['name']) <= maxDistance) {
        results.add(item);
      }
    }

    return results;
  }

  Map<int, int> surahs_in_pref = {};

  @override
  void initState() {
    searching = false;
    super.initState();
    load_all_data();
  }

  String name_en = '', name_ar = '';

  Future<void> save_and_pop() async {
    final pref = await SharedPreferences.getInstance();
    final surah_counter_t = '${ud.current_surah_index}_counter';
    await pref.setString('current_surah_en', name_en);
    await pref.setString('current_surah_ar', name_ar);
    await pref.setInt('current_surah_index', ud.current_surah_index);
    if(pref.getInt(surah_counter_t) == null)
      await pref.setInt('${ud.current_surah_index}_counter', ud.current_ayah);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    TextDirection td = ud.language == 0 ? TextDirection.ltr : TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(),
      body: loading_data == true ? Center(child: CircularProgressIndicator(),) :
      Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    textDirection: td,
                    decoration: InputDecoration(
                      hintTextDirection: td,
                      hintText: lm.data['SEARCH_SURAH${ud.language}']
                    ),
                    controller: search_controller,
                  ),
                ),
                
                IconButton(onPressed: () {}, icon: Icon(Icons.search))
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(itemBuilder: (context, index) {
              //final st = lm.data['SURAH_LIST0'][0]['count'] == ;
              final m_index = searching ? surahs_list[searching_results[index]['number']-1]['number']-1 : index;
              bool show_done_mark = false;
              bool show_hm = false;
              int a = 0, d = 0;

              if (surahs_in_pref.containsKey(m_index+1)) {
                d = surahs_in_pref[m_index+1] ?? 0;
                a = lm.data['SURAH_LIST0'][m_index]['count'];
                //log("$a -- $d");
                show_done_mark = a == d;
                if (!show_done_mark) {
                  show_hm = true;
                }
              }


              return Directionality(
                textDirection: td,
                child: ListTile(
                  onTap: () {
                    String selected_surah = searching ? searching_results[index]['name'] : surahs_list[index]['name'];

                    log("selected surah --> $selected_surah || $m_index");

                    name_ar = lm.data['SURAH_LIST1'][m_index]['name'];
                    name_en = lm.data['SURAH_LIST0'][m_index]['name'];

                    ud.current_ayah = 0;
                    //ud.current_surah_index = searching ? searching_results[index]['number'] : surahs_list[index]['number'];
                    ud.current_surah_index = m_index+1;

                    log('[[]] $selected_surah - $name_en - $name_ar - $m_index');

                    print('selected surah is $selected_surah');
                    save_and_pop();
                  },

                  leading: Icon(ud.language == 0 ? Icons.chevron_right : Icons.chevron_left),
                  title: Text(searching ? searching_results[index]['name'] : surahs_list[index]['name']),
                  trailing: show_done_mark ? Icon(Icons.done_all, color: c1,) : (show_hm ? Text('$a / $d', style: TextStyle(
                    fontWeight: FontWeight.bold
                  ),) : SizedBox()),
                ),
              );
            }, itemCount: searching ? searching_results.length : surahs_list.length),
          ),
        ],
      ),
    );
  }
}
