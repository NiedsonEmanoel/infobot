import 'dart:convert';

import 'package:bubble/bubble.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'appColors.dart';
import 'package:flutter_dialogflow/dialogflow_v2.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:fluttertoast/fluttertoast.dart';

final messageInsert = TextEditingController();
List<Map> messsages = List();
appColors colorsApp = appColors(modScreen.light);
var postUrl = "https://fcm.googleapis.com/fcm/send";
bool debugInAPP = false;
bool isTitle = false;
dynamic title;
bool isBody = false;
dynamic body;
int pass =0;
dynamic senha;
bool isMD5 = false;

void main() {
  runApp(MaterialApp(
    home: MyApp(),
    debugShowCheckedModeBanner: false,
  ));
}

String textToMd5 (String text) {
  return md5.convert(utf8.encode(text)).toString();
}

void invertDebugAPP() {
  debugInAPP = !debugInAPP;
}

void invertColor() {
  if (colorsApp.isDarkSetted == true) {
    colorsApp.setColors(modScreen.light);
  }else {
    colorsApp.setColors(modScreen.dark);
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final InAppReview inAppReview = InAppReview.instance;
  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();
  String data = "Nenhuma notificação";

  @override
  void initState() {
    messsages.insert(0, {
      "data": 0,
      "message": "Para iniciar a conversa envie um 'Oi' abaixo"
    });

    super.initState();

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) {
        print('on message $message');
        messsages.insert(0, {
          "data": 0,
          "message": "${message["notification"]['title']}\n\n${message["notification"]['body']}"
        });


        setState(() {
          data = message.toString();
        });
      },
      onResume: (Map<String, dynamic> message) {
        print('on resume $message');

        setState(() {
          data = message.toString();
        });
      },
      onLaunch: (Map<String, dynamic> message) {
        print('on launch $message');

        setState(() {
          data = message.toString();
        });
      },
    );
    _firebaseMessaging
        .requestNotificationPermissions(const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.getToken().then((token) {
      print(token);
      _firebaseMessaging.subscribeToTopic("android");
    });
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    changeTheme();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    changeTheme();
  }

  changeTheme() {
    var brightness = WidgetsBinding.instance.window.platformBrightness;
    if (brightness == Brightness.dark) {
      colorsApp = appColors(modScreen.dark);
    }else {
      colorsApp = appColors(modScreen.light);
    }

    setState(() {});
  }

  void response(query) async {
    AuthGoogle authGoogle = await AuthGoogle(
            fileJson: "assets/cupcakesbot-qlrcih-9c82160e9e70.json")
        .build();
    Dialogflow dialogflow =
        Dialogflow(authGoogle: authGoogle, language: Language.english);
    AIResponse aiResponse = await dialogflow.detectIntent(query);
    setState(() {
      messsages.insert(0, {
        "data": 0,
        "message": aiResponse.getListMessage()[0]["text"]["text"][0].toString()
      });
    });
    if (await inAppReview.isAvailable() != null) {
      inAppReview.requestReview();
    }
  }

  static Future<void> sendNotification(msg, title)async{
    final data = {
      "notification": {"body": "$msg", "title": "$title"},
      "priority": "high",
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "id": "1",
        "status": "done"
      },
      "to": "/topics/android"
    };

    final headers = {
      'content-type': 'application/json',
      'Authorization': 'key=AAAAYrIfgxE:APA91bFyys1xL0EyKoLJP1Yo9Sq61tflvCN72rkXcSTUAL9J7YXASV06CWzXCR84rf-aoyLdXMDcvwk77D_6MfqGToOUAB0HRz8H1OLHZ4RBsC9bdXmILcDaUT0aOrGA-IoWK4SUYJvb'
    };


    BaseOptions options = new BaseOptions(
      connectTimeout: 5000,
      receiveTimeout: 3000,
      headers: headers,
    );


    try {
      final response = await Dio(options).post(postUrl,
          data: data);

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Notificação Enviada!');
      } else {
        print('notification sending failed');
        // on failure do sth
      }
    }
    catch(e){
      print('exception $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "2º InfoBOT",
        ),
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        color: colorsApp.backgroundColor,
        child: Column(
          children: <Widget>[
            Flexible(
                child: ListView.builder(
                    reverse: true,
                    itemCount: messsages.length,
                    itemBuilder: (context, index) => chat(
                        messsages[index]["message"].toString(),
                        messsages[index]["data"]))),
            Divider(
              height: 5.0,
              color: Colors.indigo,
            ),
            Container(
              padding: EdgeInsets.only(left: 15.0, right: 15.0),
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: <Widget>[
                  Flexible(
                      child: TextField(
                    controller: messageInsert,
                    style: TextStyle(
                      color: colorsApp.textColor,
                    ),
                    decoration: InputDecoration.collapsed(
                        hintText: "Mensagem...",
                        hintStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18.0, color: colorsApp.hintTextColor)),
                  )),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.0),
                    child: IconButton(
                      
                        icon: Icon(
                          
                          Icons.send,
                          size: 30.0,
                          color: Colors.indigo,
                        ),
                        onPressed: () {
                           if (messageInsert.text.isEmpty) {
                            messageInsert.text = "Oi";
                            pass++;
                            pass = pass==4? 0:pass;
                            print (pass);
                            if(pass == 3) {
                              Fluttertoast.showToast(msg: "Supimpa!");
                            }
                          } else {
                            setState(() {
                              messsages.insert(0,
                                  {"data": 1, "message": messageInsert.text});

                              if(((messageInsert.text == "DEBUG_MODE") || messageInsert.text == "DEV_MODE")&&(pass == 3)) {
                                if (debugInAPP == false) {
                                  messsages.insert(0, {
                                    "data": 0,
                                    "message": "MODO DESENVOLVEDOR ATIVADO \n\n"
                                        "-> DEBUG_MODE ou DEV_MODE:\n- Desativar o modo desenvolvedor.\n\n"
                                        "-> I_C:\n-Inverter o modo de visualização do app.\n\n"
                                        "NOTIFICAÇÕES:\n"
                                        "-> ENVIAR_NOTIFICAÇÃO\n"
                                        "-Enviar notificação personalizada.\n\n"
                                        "-> N_GEOGRAFIA\n\n"
                                        "-> N_QUIMICA\n\n"
                                        "-> N_BIOLOGIA\n\n"
                                        "-> N_FILOSOFIA\n\n"
                                        "-> N_FISICA\n\n"
                                        "-> N_HISTORIA\n\n"
                                        "-> N_MATEMATICA\n\n"
                                        "-> N_PROGRAMACAO",
                                  });
                                  invertDebugAPP();
                                }else {
                                  messsages.insert(0, {
                                    "data": 0,
                                    "message": "MODO DESENVOLVEDOR DESATIVADO"
                                  });
                                  invertDebugAPP();
                                }
                              }

                              else if((messageInsert.text == "ENVIAR_NOTIFICAÇÃO")&&(debugInAPP == true)) {
                                messsages.insert(0, {
                                  "data": 0,
                                  "message": "Digite a senha:"
                                });
                                isMD5 = true;
                              }

                              else if((isMD5 == true)&&(debugInAPP == true)) {
                                senha = textToMd5(messageInsert.text);
                                if (senha == '4e5a95862de7218e4a78651e955688f1') {
                                  messsages.insert(0, {
                                    "data": 0,
                                    "message": "Digite o título:"
                                  });
                                  isTitle = true;
                                } else {
                                  isTitle = false;
                                  isBody = false;
                                  isMD5 = false;
                                  messsages.insert(0, {
                                    "data": 0,
                                    "message": "Senha incorreta :("
                                  });
                                }
                              }

                              else if((isTitle == true)&&(debugInAPP == true)) {
                                title = messageInsert.text;
                                messsages.insert(0, {
                                  "data": 0,
                                  "message": "Digite o corpo:"
                                });
                                isTitle = false;
                                isBody = true;
                              }

                              else if((isBody == true)&&(debugInAPP == true)) {
                                body = messageInsert.text;
                                sendNotification(body, title);
                                isTitle = false;
                                isBody = false;
                                isMD5 = false;
                              }

                              else if((messageInsert.text == "N_GEOGRAFIA")&&(debugInAPP == true)) {
                                sendNotification("https://meet.google.com/xpn-fgry-jkr", "Aula de Geografia");
                              }

                              else if((messageInsert.text == "N_QUIMICA")&&(debugInAPP == true)) {
                                sendNotification("https://meet.google.com/qyz-aong-kvh", "Aula de Química");
                              }

                              else if((messageInsert.text == "N_BIOLOGIA")&&(debugInAPP == true)) {
                                sendNotification("https://meet.google.com/ste-kxbj-rgt", "Aula de Biologia");
                              }

                              else if((messageInsert.text == "N_FILOSOFIA")&&(debugInAPP == true)) {
                                sendNotification("https://meet.google.com/ste-kxbj-rgt", "Aula de Biologia");
                              }

                              else if((messageInsert.text == "N_FISICA")&&(debugInAPP == true)) {
                                sendNotification("https://meet.google.com/lookup/ge3hhopaw5", "Aula de Física");
                              }

                              else if((messageInsert.text == "N_HISTORIA")&&(debugInAPP == true)) {
                                sendNotification("https://meet.google.com/gge-yasa-wwo", "Aula de História");
                              }

                              else if((messageInsert.text == "N_MATEMATICA")&&(debugInAPP == true)) {
                                sendNotification("https://meet.google.com/euk-iqhh-svh", "Aula de Matemática");
                              }

                              else if((messageInsert.text == "N_PROGRAMACAO")&&(debugInAPP == true)) {
                                sendNotification("https://meet.google.com/sfb-kins-jyz", "Aula de Programação");
                              }

                              else if((messageInsert.text == "I_C")&&(debugInAPP == true)) {
                                messsages.insert(0, {
                                  "data": 0,
                                  "message": "Cores invertidas."
                                });
                                  invertColor();
                              }
                              else {
                                response(messageInsert.text);
                              }
                            });
                            messageInsert.clear();
                          }
                        }),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 15.0,
            )
          ],
        ),
      ),
    );
  }

  //for better one i have use the bubble package check out the pubspec.yaml

  Widget chat(String message, int data) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Bubble(
          radius: Radius.circular(15.0),
          color: data == 0 ? Colors.indigo : Colors.indigoAccent,
          elevation: 0.0,
          alignment: data == 0 ? Alignment.topLeft : Alignment.topRight,
          nip: data == 0 ? BubbleNip.leftBottom : BubbleNip.rightTop,
          child: Padding(
            padding: EdgeInsets.all(2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircleAvatar(
                  backgroundImage: AssetImage(
                      data == 0 ? "assets/bot.png" : "assets/user.png"),
                ),
                SizedBox(
                  width: 10.0,
                ),
                Flexible(
                    child: Text(
                  message,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ))
              ],
            ),
          )),
    );
  }
}
