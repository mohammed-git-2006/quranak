

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';


class ChoosePDF extends StatefulWidget {
  const ChoosePDF({super.key});

  @override
  State<ChoosePDF> createState() => _ChoosePDFState();
}

class _ChoosePDFState extends State<ChoosePDF> {
  bool ar_downloaded = false, loading = true, loading_err = false;
  double loading_perc = .0;
  Directory? doc;

  void open_page_with_value(BuildContext c, int v) {
    Navigator.push(c, MaterialPageRoute(builder: (ctx) => OfflineReadingPage(vl: v,)));
  }

  void download_file() async{
    var request = Request('GET', Uri.parse(''));
    var response = await Client().send(request);

    final int totalLength = response.contentLength ?? 1;
    int totalLoaded = 0;

    File f = File('$doc/ar.pdf');
    var sink = f.openWrite();

    setState(() {
      loading = true;
      loading_perc = 0;
      loading_err = false;
    });

    response.stream.listen((chunk) {
      totalLoaded += chunk.length;
      sink.add(chunk);

      setState(() {
        loading_perc = (totalLoaded / totalLength) * 100.0;
      });
    }, onError: (e) {
      setState(() {
        loading_err = true;
        loading = false;
        ar_downloaded = false;
      });
    }, onDone: () {
      sink.close();

      setState(() {
        loading = false;
        loading_err = false;
        ar_downloaded = true;
      });
    });
  }

  @override
  void initState() async {
    doc = await getApplicationDocumentsDirectory();

    try {
      File f = File('$doc/ar.pdf');
      bool r = f.existsSync();
      if (!r) throw 'Not downloaded';


    } catch(e) {

    }
  }



  @override

  Widget build(BuildContext context) {

    double w = MediaQuery.of(context).size.width;



    return Scaffold(
      appBar: AppBar(),
      body: loading ? Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              child: ElevatedButton(onPressed: () {open_page_with_value(context, 0);}, child: Text('Quran PDF in English'),),
              width: w-20,
              height: 50,
            ),

            SizedBox(height: 15,),

            Container(
              child: ElevatedButton(onPressed: () {open_page_with_value(context, 1);}, child: Text('القرآن PDF بالعربية'),),
              width: w-20,
              height: 50,
            ),

            Container(
              width: w-20,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  download_file();
                },
                child: ListTile(
                  title: Text('القرآن PDF بالعربية'),
                  trailing: loading ? LinearProgressIndicator(value: loading_perc,) : Icon(Icons.download),
                )
              ),
            )
          ],
        ),
      ),
    );
  }
}



class OfflineReadingPage extends StatefulWidget {
  final int vl;
  const OfflineReadingPage({required this.vl});

  @override
  State<OfflineReadingPage> createState() => _OfflineReadingPageState();
}

class _OfflineReadingPageState extends State<OfflineReadingPage> {
  int ud_language = 0;
  dynamic json_data = {};
  bool _isLoading = true;
  Uint8List? pdf_memory;
  final GlobalKey<SfPdfViewerState> w_pdfViewerKey = GlobalKey();
  PdfViewerController _pdfViewerController = PdfViewerController();
  TextEditingController _psc = TextEditingController();
  int last_page_searched = 1;
  BannerAd? _bannerAd;

  void update_pdf_page(int v) {
    SharedPreferences.getInstance().then((pref) => pref.setInt('pdf_${widget.vl}', v));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoad) load_ad();
    return _isLoading ? Scaffold(appBar: AppBar(), body: Center(child: CircularProgressIndicator(),)) : Scaffold(
      appBar: AppBar(title: Text(json_data['T$ud_language']),),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(icon: Icon(Icons.skip_previous),onPressed: () {
                    _pdfViewerController.previousPage();

                  },),
                  IconButton(icon: Icon(Icons.skip_next),onPressed: () {
                    _pdfViewerController.nextPage();
                  },),
                ],
              ),

              //SizedBox(width: 40),

              Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: TextField(
                      decoration: InputDecoration(
                        border: UnderlineInputBorder()
                      ),
                      controller: _psc,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),

                  IconButton(icon: Icon(Icons.search), onPressed: () {
                    if(_psc.text.isEmpty)
                      _psc.text = (last_page_searched ).toString();

                    _pdfViewerController.jumpToPage(int.parse(_psc.text));
                    last_page_searched = int.parse(_psc.text);
                    SharedPreferences.getInstance().then((pref) => pref.setInt('pdf_${widget.vl}', last_page_searched));
                  },),
                ],
              )
            ],
          ),

          SizedBox(height: 10,),

          Expanded(
            child: SfPdfViewer.asset(
              widget.vl == 0 ? 'pdf/quran_en.pdf' : 'pdf/quran_ar.pdf',controller: _pdfViewerController, onPageChanged: (details) {
                SharedPreferences.getInstance().then((pref) => pref.setInt('pdf_${widget.vl}', details.newPageNumber));
              }
              //key: _pdfViewerKey,
            ),
          ),

          Platform.isAndroid && _isLoad? get_ad_banner(_bannerAd!) : SizedBox()
        ],
      ),
    );
  }

  final BannerAdUnitId = 'ca-app-pub-4980834571806250/5790068677';

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
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

  bool _isLoad = false;

  Future<void> load_ad() async{
    _bannerAd = BannerAd(
      adUnitId: BannerAdUnitId,
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
          ad.dispose();
        },
      ),
    )..load();
  }

  void load_user_data() async {
    final pref = await SharedPreferences.getInstance();
    ud_language = pref.getInt('language') ?? 0;
    json_data = await jsonDecode(await rootBundle.loadString('json/en_ar.json'));
    last_page_searched = pref.getInt('pdf_${widget.vl}') ?? 1;
    _psc.text = (last_page_searched).toString();

    _pdfViewerController.jumpToPage(pref.getInt('pdf_${widget.vl}') ?? 0);

    await load_ad();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    load_user_data();

    super.initState();
  }
}
