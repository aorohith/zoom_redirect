import 'dart:developer';
import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zoom_poc/utils/constants.dart';
import 'package:zoom_poc/zoom_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ZoomController controller = Get.put(ZoomController());

  @override
  void initState() {
    super.initState();
  }

  String? _validateURL(String? value) {
    try {
      final uri = Uri.tryParse(value ?? "");

      // Check if the URL is valid
      if (uri == null ||
          !uri.scheme.startsWith('https') ||
          !uri.host.contains('zoom.us')) {
        return "Invalid URL";
      }

      // Extract the path segments
      final pathSegments = uri.pathSegments;

      // Ensure that the path is not empty and contains at least two segments
      if (pathSegments.length < 2) {
        return "Meeting ID and password are required";
      }

      // The last two segments in the path should be the meeting ID and password
      final meetingId = pathSegments.last;
      // Manually parse the query string
      final queryParameters = uri.queryParameters;

      // Extract the meeting ID and password, handling nullable values

      final password = queryParameters['pwd'];

      // You can further validate the extracted meeting ID and password as needed
      if (meetingId.isEmpty || (password?.isEmpty ?? false)) {
        return "Meeting ID and password cannot be empty";
      }

      final result = _getMeetIdPass(value ?? "");
      if (result.isEmpty || result.length != 2) {
        return "There is some issue with the url";
      }

      return null;
    } catch (e) {
      return "There is some issue with the url";
    }
  }

  final TextEditingController _urlController =
      TextEditingController(text: Constants.meetUrl);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              "assets/app_icon.png",
              height: 50,
            ),
            const SizedBox(width: 10),
            const Text("Zoom with Flutter"),
          ],
        ),
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: TextFormField(
                    controller: _urlController,
                    maxLines: 2,
                    keyboardType: TextInputType.url,
                    validator: _validateURL,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      labelText: "Enter Url",
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 1.0,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: const BorderSide(
                          color: Colors
                              .blue, // Customize the border color for error state.
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: const BorderSide(
                          color: Colors
                              .blue, // Customize the border color for error state.
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onPressed,
                  child: const Text("Join Meeting"),
                ),
                const SizedBox(
                  height: 20,
                ),
              ]),
        ),
      ),
    );
  }

  Future<void> onPressed() async {
    bool zoomInstalled = await isZoomAppInstalled();

    if (zoomInstalled) {
      String url = _urlController.text.trim();
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(
            convertToZoomAppUrl(
              url,
            ),
          ),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch url';
      }
    } else {
      redirectStore();
    }
  }

  String convertToZoomAppUrl(String standardZoomUrl) {
    final Uri zoomUri = Uri.parse(standardZoomUrl);

    // Extracting the Meeting ID and Password from the standard URL
    final String meetingID = zoomUri.pathSegments.last;
    final String? password = zoomUri.queryParameters['pwd'];

    // Constructing the Zoom app-specific URL
    return 'zoomus://zoom.us/join?confno=$meetingID${password != null ? '&pwd=$password' : ''}';
  }

  Future<void> redirectStore() async {
    if (Platform.isAndroid) {
      redirect(
          'https://play.google.com/store/apps/details?id=us.zoom.videomeetings');
      return;
    } else {
      redirect('https://apps.apple.com/us/app/zoom-cloud-meetings/id546505307');
    }
  }

  redirect(String url) async {
    try {
      if (!await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        log('Could not launch url');
      }
    } catch (e) {
      log(e.toString(), name: 'store redirect zoom');
    }
  }
}

Future<bool> isZoomAppInstalled() async {
  const String customScheme = 'zoomus://'; // Zoom app's custom URL scheme
  if (await canLaunchUrl(Uri.parse(customScheme))) {
    return true; // The Zoom app is installed
  } else {
    return false; // The Zoom app is not installed
  }
}

List<String> _getMeetIdPass(String inputUrl) {
  try {
    // Parse the URL
    Uri uri = Uri.parse(inputUrl);

    // Extract the meeting ID from the path
    String meetingId = uri.pathSegments.last;

    // Extract the password from the query parameters
    String? password = uri.queryParameters['pwd'];

    // Check if both meeting ID and password are present
    if (meetingId.isNotEmpty && password != null && password.isNotEmpty) {
      // Remove any trailing .1 or similar numeric suffix
      String cleanedPassword =
          RegExp(r'(.*?)(\.\d+)?$').firstMatch(password)?.group(1) ?? "";

      if (cleanedPassword.isNotEmpty) {
        return [meetingId, cleanedPassword];
      }
    }
  } catch (e) {
    // Handle exception if needed
  }

  // Return an empty list if extraction fails
  return [];
}
