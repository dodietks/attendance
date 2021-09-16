import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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

  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPosition;

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

  void _attendancePlus(element, int attendanceValue) {
    if (element["isPresent"]) {
      int actualAttendance = int.parse(element["attendance"]);
      int attendance = actualAttendance + attendanceValue;
      element["attendance"] = attendance.toString();

      element["isPresent"] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de presença"),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
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
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(17.0, 0, 0, 0),
                    child: TextField(
                      controller: _attendanceController,
                      decoration: const InputDecoration(
                        labelText: "Presenças",
                        labelStyle: TextStyle(color: Colors.amber),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.amber)),
                    onPressed: _addStuddent,
                    child: const Icon(Icons.person_add_alt_1),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10.0, 0, 0, 5.0),
                    child: ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.amber)),
                      onPressed: _addAttendance,
                      child: const Icon(Icons.done),
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
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.person_remove_alt_1,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        activeColor: Colors.amber,
        title: Text(_studdentList[index]["name"]),
        subtitle: Text(_studdentList[index]["attendance"]),
        value: _studdentList[index]["isPresent"],
        secondary: CircleAvatar(
          backgroundColor:
              _studdentList[index]["isPresent"] ? Colors.green : Colors.amber,
          child: Icon(
            _studdentList[index]["isPresent"] ? Icons.task_alt : Icons.face,
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
        setState(() {
          _lastRemoved = Map.from(_studdentList[index]);
          _lastRemovedPosition = index;
          _studdentList.removeAt(index);

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
                  child: Text("Aluno: \"${_lastRemoved["name"]}\" removido!"),
                ),
              ],
            ),
            action: SnackBarAction(
                textColor: Colors.amber,
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _studdentList.insert(_lastRemovedPosition, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: const Duration(seconds: 3),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
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
