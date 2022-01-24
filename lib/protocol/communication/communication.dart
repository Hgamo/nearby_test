part of '../protocol.dart';

class Communications {
  Communications(this.ncpService);

  final NcpService ncpService;

  /// Sends all neighbors [devices] to receiver [receiverId]
  ///
  /// Needs [receiverId] and [ownId] for proper sending
  /// [devices] and [route] are required for proper routing
  void sendNeighborsToId({
    required String receiverId,
    required String ownId,
    required List<DiscoverDevice> devices,
    required MessageRoute route,
    final String? id,
  }) {
    final List<Map> data = devices.map((device) => device.toMap()).toList();
    final Message message = Message(
      id: id ?? const Uuid().v4(),
      senderId: ownId,
      receiverId: receiverId,
      route: route,
      payload: data,
      messageType: MessageType.neighborsResponse,
    );
    handleMessage(message, ownId);
  }

  /// Request neighbors from [receiverId]
  ///
  /// Needs [ownId] and [route] for proper sending
  /// [route] shall be generated by [ConnectedDevicesGraph]
  void requestNeighbors({
    required String receiverId,
    required String ownId,
    required MessageRoute route,
    final String? id,
  }) {
    final Message message = Message(
      id: id ?? const Uuid().v4(),
      senderId: ownId,
      receiverId: receiverId,
      route: route,
      payload: null,
      messageType: MessageType.neighborsRequest,
    );
    handleMessage(message, ownId);
  }

  ///Handles a message
  ///
  ///Needs [ownId] to put message in context to device
  ///Returns the Message if device is last node in message route
  ///Function does not check if route is valid or operational because routing is always defined by the sender
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

  ///Sends [message] to [id]
  ///
  ///Uses [ncpService] defined in constructor to send message
  ///[message] and [id] are required
  Future<void> sendMessageToId(Message message, String id) async {
    await ncpService.sendMessageToId(message, id);
  }

  /// Input method for received messages
  ///
  /// Needs [message] and [graph] to handle message
  String? messageInput({
    required Message message,
    required ConnectedDevicesGraph graph,
    required Me me,
  }) {
    print('messageInput: $message');
    final messageForMe = handleMessage(message, me.ownId);
    if (messageForMe != null) {
      print('got message for me: $messageForMe');
      final senderId = messageForMe.senderId;
      if (messageForMe.messageType == MessageType.neighborsRequest) {
        messageForMe.interpret();
        sendNeighborsToId(
          receiverId: senderId,
          ownId: me.ownId,
          devices: graph.connectedDevices(),
          route: messageForMe.route.reversed.toList(),
        );
      } else if (messageForMe.messageType == MessageType.neighborsResponse) {
        final response = messageForMe.interpret() as List<DiscoverDevice>;
        graph.addDeviceWithAncestors(
          DiscoverDevice(id: senderId),
          response,
        );
      } else if (messageForMe.messageType == MessageType.text) {
        return messageForMe.interpret() as String;
      }
    }
  }
}
