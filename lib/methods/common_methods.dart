import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class CommonMethods {
  Future<bool> checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity().checkConnectivity();
  
    // ignore: collection_methods_unrelated_type
    if (connectionResult.contains(ConnectivityResult.none)) {
      displaySnackBar(
          "Your Internet is not available. Check your connection and try again.",
          context);
          return false;
    }
    return true;
  }

  void displaySnackBar(String messageText, BuildContext context) {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
