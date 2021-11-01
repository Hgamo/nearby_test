import 'dart:convert';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';
import 'package:nearby_test/global/globals.dart';


///Helper class to combine several [NearbyHelper] functions
///
///Parameter [nearby] is required (implicitly)
class NearbyHelpers {
  final Nearby nearby;

  NearbyHelpers(this.nearby);

  ///Sends connected devices exept applicant to device in a standardised way
  ///
  ///Converts a list to json sting and the encodabele format for NCA transmission
  ///[id] and [devices] are required (implicitly)
  sendConnectedDevicesToId(String id, List<DiscoverDevice> devices) async {
    try {
      final List<String> deviceData = devices
          .where((device) =>
              device.connectionStatus == ConnectionStatus.done &&
              device.id != id)
          .map<String>((device) => device.toJson())
          .toList();
      final Map data = {'connectedDevices': deviceData};
      final String jsonData = jsonEncode(data);
      await nearby.sendBytesPayload(id, Uint8List.fromList(jsonData.codeUnits));
    } catch (e) {
      print('error while trying to send connected Devices to $id: $e');
    }
  }
}