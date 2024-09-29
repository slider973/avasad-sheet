import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PreferenceList extends StatelessWidget {
  const PreferenceList({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          backgroundColor: Colors.teal,
          leading: Text('Preferences'),

        ),
        child: CupertinoFormSection(
          header: const Text('Section header'),
          children: <Widget>[
            CupertinoFormRow(
              prefix: const Text('Prefix'),
              child: CupertinoSwitch(
                value: true,
                onChanged: (bool value) {},
              ),
            ),
          ],
        ));
  }
}
