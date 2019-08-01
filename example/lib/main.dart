import 'package:scoped_model/scoped_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttercouch/document.dart';
import 'package:fluttercouch/fluttercouch.dart';
import 'package:fluttercouch/mutable_document.dart';
import 'package:fluttercouch/query/query.dart';
// import 'package:scoped_model/scoped_model.dart';

class AppModel extends Model with Fluttercouch {
  String _databaseName;
  Document docExample;
  Query query;

  AppModel() {
    initPlatformState();
  }

  initPlatformState() async {
    try {
      _databaseName = await initDatabaseWithName("infodiocesi");

      // setReplicatorEndpoint("ws://localhost:4984/infodiocesi");
      // setReplicatorType("PUSH_AND_PULL");
      // setReplicatorBasicAuthentication(<String, String>{
      //   "username": "defaultUser",
      //   "password": "defaultPassword"
      // });
      // setReplicatorContinuous(true);
      // initReplicator();
      // startReplicator();
      docExample = await getDocumentWithId("diocesi_tab");
      notifyListeners();
      MutableDocument mutableDoc = MutableDocument();
      mutableDoc.setString("prova", "");
    } on PlatformException {}
  }

  Future<Map<String, Document>> getNote() async {
    var quer = List<SelectResultProtocol>();
    quer.add(SelectResult.expression(Meta.id));
    quer.add(SelectResult.all());

    Query query = QueryBuilder.select(quer).from(_databaseName);
    var result = Map<String, Document>();
    try {
      await query.execute().then((ResultSet rs) {
        for (var a in rs) {
          getDocumentWithId(a.getString(key: "id")).then((doc) {
            result.putIfAbsent(a.getString(key: "id"), () => doc);
          });
          // result.addEntries(a.getString(key: "id"),()=> a.getString(key: "name"));
        }
      });
    } on PlatformException {}
    return result;
  }

  Future<bool> saveNote(inStr) async {
    bool isOk = false;
    try {
      MutableDocument doc = MutableDocument();
      doc.setString("name", inStr);
      saveDocumentWithId(inStr, doc);
      isOk = true;
    } on PlatformException {}
    return isOk;
  }
}

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Fluttercouch example application',
        home: new ScopedModel<AppModel>(
          model: new AppModel(),
          child: new Home(),
        ));
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String txt_value;
  List<String> litems = [];

  final _formKey = GlobalKey<FormFieldState>();

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Fluttercouch example application'),
      ),
      body: new Center(
        child: new Column(
          children: <Widget>[
            new Text("This is an example app"),
            Flexible(
              flex: 4,
              child: ListView.builder(
                  itemCount: litems.length,
                  itemBuilder: (BuildContext ctxt, int index) {
                    return new Text(litems[index]);
                  }),
            ),
            new ScopedModelDescendant<AppModel>(
              builder: (context, child, model) => Flexible(
                flex: 2,
                child: Form(
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        key: _formKey,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.person),
                          hintText: 'What do people call you?',
                          labelText: 'Name *',
                        ),
                        onSaved: (String value) {
                          // This optional block of code can be used to run
                          // code when the user saves the form.
                          txt_value = value;
                        },
                        validator: (String value) {
                          if (value.isEmpty) {
                            return "Value can't be empty";
                          }
                          return null;
                        },
                      ),
                      FlatButton(
                        child: Text("Save"),
                        onPressed: () {
                          if (_formKey.currentState.validate()) {
                            _formKey.currentState.save();

                            model.saveNote(txt_value).then((isok) {
                              if (isok) {
                                _formKey.currentState.reset();
                                model.getNote().then((val) {
                                  for (var a in val.keys) {
                                    litems.add(a);
                                  }
                                  setState(() {
                                    // litems.add("$val");
                                  });
                                });
                                // litems.add(model.getNote().);
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
