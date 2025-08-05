// ignore_for_file: unrelated_type_equality_checks

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService with ChangeNotifier {
  bool _online = true;
  bool get online => _online;

  ConnectivityService() {
    Connectivity().onConnectivityChanged.listen((status) {
      _online = status != ConnectivityResult.none;
      notifyListeners();
    });
    // chequeo inicial
    Connectivity().checkConnectivity().then((status) {
      _online = status != ConnectivityResult.none;
      notifyListeners();
    });
  }
}
