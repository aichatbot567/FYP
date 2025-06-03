import 'package:flutter/material.dart';
// import 'package:gallery_saver/gallery_saver.dart';

class FullScreenChatImage extends StatefulWidget {
  final String photoUrl;
  const FullScreenChatImage({super.key, required this.photoUrl});

  @override
  _FullScreenChatImageState createState() => _FullScreenChatImageState();
}

class _FullScreenChatImageState extends State<FullScreenChatImage> {
  // Future<void> _saveImageToGallery() async {
  //   try {
  //     final response = await http.get(Uri.parse(widget.photoUrl));
  //     if (response.statusCode == 200) {
  //       final bytes = response.bodyBytes;
  //       final directory = await getTemporaryDirectory();
  //       final filePath = path.join(directory.path, 'image_to_save.png');
  //       final file = File(filePath);
  //       await file.writeAsBytes(bytes);
  //
  //       bool? result = await GallerySaver.saveImage(filePath);
  //       if (result == true) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Image saved to gallery'),
  //             duration: Duration(seconds: 2),
  //           ),
  //         );
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Failed to save image to gallery'),
  //             duration: Duration(seconds: 2),
  //           ),
  //         );
  //       }
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Failed to download image'),
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error: $e'),
  //         duration: Duration(seconds: 2),
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Hero(
                tag: widget.photoUrl,
                child: Image.network(widget.photoUrl),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppBar(
                    elevation: 0.0,
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: <Widget>[
                      // IconButton(
                      //   icon: Icon(Icons.save_alt, color: Colors.black),
                      //   onPressed: _saveImageToGallery,
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
