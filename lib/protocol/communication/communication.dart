library communication;

import 'package:nearby_test/global/globals.dart';
import 'package:nearby_test/protocol/protocol.dart';
import 'package:nearby_test/protocol/communication/ncp_service/ncp_service.dart';
import 'package:uuid/uuid.dart';

part 'dummy_route.dart';

class Communications {
  Communications(this.ncpService);

  final NcpService ncpService;

  void sendNeighborsToId({
    required String receiverId,
    required String senderId,
    required List<DiscoverDevice> devices,
    required MessageRoute route,
  }) {
    final List<Map> data = devices.map((device) => device.toMap()).toList();
    final Message message = Message(
      id: const Uuid().v4(),
      senderId: senderId,
      receiverId: receiverId,
      route: route,
      payload: data,
      messageType: MessageType.neighborsResponse,
    );
  }

  ///Handles and incomming message
  ///
  ///Needs [ownId] to put message in context to device
  ///Retruns the Messsge if device is last node in messageroute
  Message? handleMessage(Message message, String ownId) {
    if (message.receiverId == ownId) {
      return message;
    }
    final MessageRoute messageRoute = message.route;
    final List<String> routeDeviceIdList =
        messageRoute.map<String>((node) => node.deviceId).toList();
    final ownIndex = routeDeviceIdList.indexOf(ownId);
    sendMessageToId(message, routeDeviceIdList[ownIndex + 1]);
  }

  sendMessageToId(Message message, String id) {
    ncpService.sendMessageToId(message, id);
  }
}