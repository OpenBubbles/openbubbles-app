import 'dart:io';

import 'package:bluebubbles/app/components/avatars/contact_avatar_widget.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_location_clipper.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_page.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/app/wrappers/theme_switcher.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'dart:async';

class FindMy extends StatefulWidget {
  final iMessageAppData data;
  final Message message;
  final bool isPopup;


  FindMy({
    super.key,
    required this.data,
    required this.message,
    this.isPopup = false,
  });

  @override
  OptimizedState createState() => _FindMyState();
}

class _FindMyState extends OptimizedState<FindMy> with AutomaticKeepAliveClientMixin {
  iMessageAppData get data => widget.data;

  final MapController mapController = MapController();

  @override
  bool get wantKeepAlive => true;

  late Function cancel;
  String mainLocation = "";

  StreamSubscription? locationSub;
  Position? location;

  @override
  void initState() {
    super.initState();
    var uri = Uri.parse(data.url!.replaceAll("+", "%2B"));
    var dataKey = base64.decode(uri.queryParameters["FindMyMessagePayloadZippedDataKey"]!);
    var decoded = json.decode(utf8.decode(ZLibCodec(raw: true).decode(dataKey)));
    print(decoded);
    mainLocation = RustPushBBUtils.bbHandleToRust(widget.message.getHandle()!);
    userPosition[mainLocation] = FindMyFriend(
      latitude: decoded["initialLocation"]["latitude"],
      longitude: decoded["initialLocation"]["longitude"],
      handle: widget.message.getHandle()!,
      title: null, 
      subtitle: null, 
      longAddress: null,
      shortAddress: null,
      lastUpdated: decoded["initialLocation"]["timestamp"] != null ? DateTime.fromMillisecondsSinceEpoch((decoded["initialLocation"]["timestamp"] * 1000).round()) : null,
      status: LocationStatus.shallow, 
      locatingInProgress: true,
    );
    (() async {
      updateFollows(await api.getBackgroundFollowing(state: pushService.state));
    })();

    cancel = pushService.subscribeToLocationUpdates((updates) {
      updateFollows(updates);
    });
  }

  @override
  void dispose() {
    if (widget.isPopup) {
      api.selectBackgroundFriend(state: pushService.state, friend: null);
    }
    locationSub?.cancel();
    cancel();
    super.dispose();
  }


  List<FindMyFriend> friendsWithLocation = [];
  List<FindMyFriend> friendsWithoutLocation = [];
  Map<String, Marker> markers = {};

  bool isLive = false;
  DateTime? expires;

  final RxMap<String, FindMyFriend> userPosition = RxMap({});

  void updateFollows(List<api.Follow> follows) {
    expires = null;
    isLive = false;
    var chat = widget.message.chat.target!;
    for (var participant in chat.participants) {
      var handle = RustPushBBUtils.bbHandleToRust(participant);
      var raw = handle.split(":")[1];

      var e = follows.firstWhereOrNull((f) => f.invitationAcceptedHandles[0] == raw);
      if (e?.expires != null && e?.expires != 0 && handle == mainLocation) {
        expires = DateTime.fromMillisecondsSinceEpoch(e!.expires);
      }
      if (e != null && handle == mainLocation && widget.isPopup) {
        api.selectBackgroundFriend(state: pushService.state, friend: e.id);
      }
      if (e?.lastLocation == null) continue;

      if (handle == mainLocation) {
        isLive = true;
      }
      
      userPosition[handle] = FindMyFriend(
        latitude: e!.lastLocation?.latitude,
        longitude: e.lastLocation?.longitude,
        longAddress: e.lastLocation?.address?.formattedAddressLines?.join("\n"), 
        shortAddress: e.lastLocation?.address != null ? "${e.lastLocation?.address?.locality}, ${e.lastLocation?.address?.stateCode ?? e.lastLocation?.address?.countryCode}" : null,
        title: null, 
        subtitle: null, 
        handle: Handle(address: e.invitationAcceptedHandles.first), 
        lastUpdated: e.lastLocation?.timestamp != null ? DateTime.fromMillisecondsSinceEpoch(e.lastLocation!.timestamp) : null,
        status: null, 
        locatingInProgress: false,
        id: e.id,
      );
    }

    updatePositions();
  }

  void buildFriendMarker(FindMyFriend friend) { 
    markers[friend.handle?.uniqueAddressAndService ?? randomString(6)] = Marker(
      key: ValueKey(friend.handle?.uniqueAddressAndService),
      point: LatLng(friend.latitude!, friend.longitude!),
      width: 35,
      height: 35,
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child:
            ContactAvatarWidget(editable: false, handle: friend.handle ?? Handle(address: friend.title ?? "Unknown")),
          ),
        ),
      ),
      alignment: Alignment.topCenter,
    );
  }

  void updatePositions() async {

    if (!(Platform.isLinux && !kIsWeb) && widget.isPopup) {
      LocationPermission granted = await Geolocator.checkPermission();
      if (granted == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
      }
      if (granted == LocationPermission.whileInUse || granted == LocationPermission.always) {
        Geolocator.getCurrentPosition().then((loc) {
          location = loc;
          buildLocationMarker(location!);
          if (!kIsDesktop && locationSub == null) {
            locationSub = Geolocator.getPositionStream().listen((event) {
              setState(() {
                buildLocationMarker(event);
              });
            });
          }
        });
      }
    }

    friendsWithLocation = userPosition.values.where((item) => (item.latitude ?? 0) != 0 && (item.longitude ?? 0) != 0).toList();
    friendsWithoutLocation = userPosition.values.where((item) => (item.latitude ?? 0) == 0 && (item.longitude ?? 0) == 0).toList();

    for (FindMyFriend e in friendsWithLocation) {
      buildFriendMarker(e);
    }

    if (!widget.isPopup && userPosition[mainLocation] != null) {
      mapController.move(LatLng(userPosition[mainLocation]!.latitude!, userPosition[mainLocation]!.longitude!), 15);
    }

    print(userPosition);
    setState(() {});
  }

  void buildLocationMarker(Position pos) {
    markers['current'] = Marker(
      key: const ValueKey('current'),
      point: LatLng(pos.latitude, pos.longitude),
      width: 25,
      height: 55,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (pos.heading.isFinite)
            Transform.rotate(
              angle: pos.heading,
              child: ClipPath(
                clipper: const FindMyLocationClipper(),
                child: Container(
                  width: 25,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.center,
                      end: Alignment.topCenter,
                      colors: [context.theme.colorScheme.primary, context.theme.colorScheme.primary.withAlpha(50)],
                    ),
                  ),
                ),
              ),
            ),
          Container(
            width: 25,
            height: 25,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(5),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      alignment: Alignment.topCenter,
    );
  }

  String getExpiry() {
    var diff = expires!.difference(DateTime.now());
    if (diff.inDays != 0) {
      return "${diff.inDays}d";
    }
    if (diff.inHours != 0) {
      return "${diff.inHours}h";
    }
    return "${diff.inMinutes}m";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const icon = Icons.apple;
    final str = data.userInfo?.subcaption;
    var child = Container(
      height: ns.width(context) / 1.5,
      child:Stack(
      children: [
        IgnorePointer(
          ignoring: !widget.isPopup,
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialZoom: 17.0,
              minZoom: 1.0,
              maxZoom: 18.0,
              initialCenter: userPosition[mainLocation] == null ? const LatLng(0, 0) : LatLng(userPosition[mainLocation]!.latitude!, userPosition[mainLocation]!.longitude!),
              // Hide popup when the map is tapped.
              keepAlive: true,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () {

              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bluebubbles.app',
              ),
              PopupMarkerLayer(
                options: PopupMarkerLayerOptions(
                  // popupController: popupController,
                  markers: markers.values.toList(),
                  popupDisplayOptions: PopupDisplayOptions(
                    builder: (context, marker) {
                      final ValueKey? key = marker.key as ValueKey?;
                      if (key?.value == "current") return const SizedBox();
                      final item = userPosition.values
                            .firstWhere((e) => e.handle?.uniqueAddressAndService == key?.value);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: context.theme.colorScheme.properSurface.withOpacity(0.8),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.handle?.displayName ?? item.title ?? "Unknown Friend",
                                  style: context.theme.textTheme.labelLarge),
                              Text(ss.settings.redactedMode.value ? "Location" : (item.longAddress ?? "Initial location"), style: context.theme.textTheme.bodySmall),
                              if (item.lastUpdated != null && item.status != LocationStatus.live)
                                Text("Last updated ${buildDate(item.lastUpdated)}", style: context.theme.textTheme.bodySmall),
                              if (item.status != null)
                                Text("${item.status!.name.capitalize!} Location", style: context.theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLive || expires != null)
        Positioned(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: expires != null ? context.theme.primaryColor : Colors.red[700],
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                const BoxShadow(
                  offset: Offset(0, 2),
                  color: Color.fromARGB(255, 151, 151, 151), //edited
                  spreadRadius: 1,
                  blurRadius: 3  //edited
                )
              ],
            ),
            child: expires != null ? Row(children: [
              const Icon(CupertinoIcons.timer, size: 15, color: Colors.white),
              const SizedBox(width: 5,),
              Text(getExpiry(), style: const TextStyle(fontSize: 15, color: Colors.white))
            ],) : const Row(children: [
              Icon(Icons.warning_rounded, size: 15, color: Colors.white),
              SizedBox(width: 5,),
              Text("Not Live", style: TextStyle(fontSize: 15, color: Colors.white))
            ],),
          ),
          left: 10,
          top: 10,
        )
      ],
    ));
    return userPosition[mainLocation]!.id == null || widget.isPopup || !isLive ? child : InkWell(
      onTap: () async {
        await Navigator.of(Get.context!).push(
          ThemeSwitcher.buildPageRoute(
            builder: (BuildContext context) {
              return FindMyPage(defaultFriend: userPosition[mainLocation]!.id);
            },
          ),
        );
      },
      child: child);
  }
}
