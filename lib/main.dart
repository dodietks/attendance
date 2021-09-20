import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:share/share.dart';

void main() {
  runApp(
    MaterialApp(
      home: Home(),
    ),
  );
}

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _studdentController = TextEditingController();
  final _attendanceController = TextEditingController();

  List _studdentList = [];

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _studdentList = json.decode(data!);
      });
    });
  }

  void _addStuddent() {
    if (_studdentController.text.isNotEmpty) {
      setState(() {
        Map<String, dynamic> newStuddent = {};
        newStuddent["name"] = _studdentController.text;
        newStuddent["attendance"] = _attendanceController.text.isNotEmpty
            ? _attendanceController.text
            : "0";
        _studdentController.text = "";
        _attendanceController.text = "";
        newStuddent["isPresent"] = false;
        newStuddent["active"] = true;
        _studdentList.add(newStuddent);
        _saveData();
      });
    } else {
      const snack = SnackBar(
        content: Text("O campo precisa ser preenchido"),
        duration: Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(snack);
    }
  }

  void _addAttendance() {
    setState(() {
      int attendanceValue = _attendanceController.text.isNotEmpty
          ? int.parse(_attendanceController.text)
          : 1;
      _attendanceController.text = "";

      for (var element in _studdentList) {
        _attendancePlus(element, attendanceValue);

        _saveData();
      }
    });
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _studdentList.sort((a, b) {
        if (a["isPresent"] && !b["isPresent"]) {
          return 1;
        } else if (!a["isPresent"] && b["isPresent"]) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
  }

  Future<void> _shortUnactive() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _studdentList.sort((a, b) {
        if (a["active"] && !b["active"]) {
          return -1;
        } else if (!a["active"] && b["active"]) {
          return 1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
  }

  void _attendancePlus(element, int attendanceValue) {
    if (element["isPresent"]) {
      int actualAttendance = int.parse(element["attendance"]);
      int attendance = actualAttendance + attendanceValue;
      element["attendance"] = attendance.toString();

      element["isPresent"] = false;
    }
  }

  _getCsv() async {
    //store file in documents folder
    if (await Permission.storage.request().isGranted) {
      List<List<dynamic>> rows = [];
      for (int i = 0; i < _studdentList.length; i++) {
        List<dynamic> row = [];
        row.add(_studdentList[i]["name"]);
        row.add(_studdentList[i]["attendance"]);
        row.add(_studdentList[i]["active"] ? "Ativo" : "Desativado");
        rows.add(row);
      }
      String now = DateTime.now().toString();

      String dir = (await getExternalStorageDirectory())!.path +
          "/Lista de presença " +
          now +
          ".csv";
      File file = File(dir);

      String csv = const ListToCsvConverter().convert(rows);
      file.writeAsString(csv);
    } else {
      Map<Permission, PermissionStatus> status = await [
        Permission.storage,
      ].request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.amber,
        primarySwatch: Colors.amber,
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(color: Colors.white),
          backgroundColor: Colors.amber,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        scaffoldBackgroundColor: Colors.blueGrey[50],
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Crescendo no esporte",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              )),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.get_app),
              tooltip: 'Salvar em .CSV',
              onPressed: () {
                _getCsv();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Arquivo salvo'),
                  backgroundColor: Colors.amber,
                ));
              },
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Arquivo',
              onPressed: () async {
                Directory? rootPath = await getExternalStorageDirectory();
                String? path = await FilesystemPicker.open(
                  title: 'Arquivos',
                  pickText: 'selecionado',
                  rootName: 'Selecione para compartilhar',
                  context: context,
                  rootDirectory: rootPath!,
                  fsType: FilesystemType.file,
                  folderIconColor: Colors.amber,
                  allowedExtensions: ['.csv'],
                  fileTileSelectMode: FileTileSelectMode.wholeTile,
                );
                Share.shareFiles([(path!)], text: 'Arquivo: $path');
              },
            ),
          ],
          backgroundColor: Colors.amber,
          shadowColor: Colors.amber,
          elevation: 10,
          centerTitle: false,
          toolbarHeight: 60,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35))),
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(10.0, 1.0, 10.0, 1.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _studdentController,
                      decoration: const InputDecoration(
                        labelText: "Nome",
                        labelStyle: TextStyle(color: Colors.amber),
                      ),
                      keyboardType: TextInputType.name,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(
                            r'[A-Za-záàâãéèêíïóôõöúçñÁÀÂÃÉÈÍÏÓÔÕÖÚÇÑ\s]'))
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10.0, 0, 0, 0),
                      child: TextField(
                        controller: _attendanceController,
                        decoration: const InputDecoration(
                          labelText: "Presenças",
                          labelStyle: TextStyle(color: Colors.amber),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.amber)),
                        onPressed: _addStuddent,
                        child: const Icon(
                          Icons.person_add_alt_1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10.0, 0, 0, 0),
                      child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.amber)),
                        onPressed: _addAttendance,
                        child: const Icon(
                          Icons.fact_check,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10.0),
                  itemCount: _studdentList.length,
                  itemBuilder: buildItem,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Icon(
                Icons.person_remove_alt_1,
                color: Colors.white,
              ),
              Text(
                ' Desativar: ${_studdentList[index]["name"]}.',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      secondaryBackground: Container(
        color: Colors.green,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(
                Icons.person_add_alt_1,
                color: Colors.white,
              ),
              Text(
                ' Ativar: ${_studdentList[index]["name"]}.',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      direction: DismissDirection.horizontal,
      child: CheckboxListTile(
        activeColor: Colors.amber,
        title: Text(_studdentList[index]["name"]),
        subtitle: Text("Presenças: ${_studdentList[index]["attendance"]}"),
        value: _studdentList[index]["isPresent"],
        secondary: CircleAvatar(
          backgroundColor: _studdentList[index]["active"]
              ? _studdentList[index]["isPresent"]
                  ? Colors.green
                  : Colors.amber
              : Colors.red,
          child: Icon(
            _studdentList[index]["active"]
                ? _studdentList[index]["isPresent"]
                    ? Icons.how_to_reg
                    : Icons.person
                : Icons.delete,
            color: Colors.white,
            size: 35,
          ),
        ),
        onChanged: (bool? checkBox) {
          setState(() {
            _studdentList[index]["isPresent"] = checkBox;

            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          setState(() {
            _studdentList[index]["active"] = false;
            _saveData();

            final snack = SnackBar(
              content: Row(
                children: <Widget>[
                  const Icon(
                    Icons.person_remove_alt_1,
                    color: Colors.white,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                        "Aluno: \"${_studdentList[index]["name"]}\" desativado!"),
                  ),
                ],
              ),
              action: SnackBarAction(
                  textColor: Colors.white,
                  label: "Reativar",
                  onPressed: () {
                    setState(() {
                      _studdentList[index]["active"] = true;
                      _saveData();
                    });
                  }),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.amber,
            );
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(snack);
          });
        } else {
          setState(() {
            _studdentList[index]["active"] = true;
            _saveData();

            final snack = SnackBar(
              content: Row(
                children: <Widget>[
                  const Icon(
                    Icons.person_add_alt_1,
                    color: Colors.white,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                        "Aluno: \"${_studdentList[index]["name"]}\" reativado!"),
                  ),
                ],
              ),
              action: SnackBarAction(
                  textColor: Colors.white,
                  label: "Desativar",
                  onPressed: () {
                    setState(() {
                      _studdentList[index]["active"] = false;
                      _saveData();
                    });
                  }),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.amber,
            );
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(snack);
          });
        }

        _shortUnactive();
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_studdentList);
    final file = await _getFile();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
