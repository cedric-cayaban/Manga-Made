import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ChapterView extends StatefulWidget {
  ChapterView({
    Key? key,
    required this.mangaIdentifier,
    required this.chIdentifier,
    required this.snapshotId,
    required this.genre,
  }) : super(key: key);

  final int mangaIdentifier; // di na siguro magagamit
  final String chIdentifier;
  final String snapshotId;
  final String genre;

  @override
  _ChapterViewState createState() => _ChapterViewState();
}

class _ChapterViewState extends State<ChapterView> {
  List<File> pgImage = [];
  final int batchSize = 2;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    getChapters();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void getChapters() async {
    String mangaGenre = getMangaGenre(widget.genre);

    try {
      var data = await FirebaseFirestore.instance
          .collection(mangaGenre)
          .doc(widget.snapshotId)
          .collection('chapters')
          .where('id', isEqualTo: widget.chIdentifier)
          .get();

      if (!_isMounted) return;

      var chapterDoc = data.docs.first;
      int chConvertNum = int.parse(chapterDoc['pgNumber']);

      int totalBatches = (chConvertNum / batchSize).ceil();

      for (int i = 0; i < totalBatches; i++) {
        int startIndex = i * batchSize;
        int endIndex = (startIndex + batchSize <= chConvertNum)
            ? startIndex + batchSize
            : chConvertNum;

        await fetchImages(startIndex, endIndex, chapterDoc);
      }
    } catch (e) {}
  }

  Future<void> fetchImages(
      int startIndex, int endIndex, DocumentSnapshot chapterDoc) async {
    if (!_isMounted) return;

    String mangaGenre = getMangaGenre(widget.genre);

    var tempDir = await getTemporaryDirectory();
    List<File> downloadedImages = [];

    for (int b = startIndex; b < endIndex; b++) {
      String pageName = 'pg ${(b + 1).toString().padLeft(3, '0')}';
      var pagesCollection = await FirebaseFirestore.instance
          .collection(mangaGenre)
          .doc(widget.snapshotId)
          .collection('chapters')
          .doc(chapterDoc.id)
          .collection(pageName)
          .get();

      for (var pageDoc in pagesCollection.docs) {
        var pageData = pageDoc.data();
        String url = pageData['url'];

        var response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          var tempFile = File(
              '${tempDir.path}/image_${DateTime.now().millisecondsSinceEpoch}_${b.toString().padLeft(3, '0')}.jpg');
          await tempFile.writeAsBytes(response.bodyBytes);
          downloadedImages.add(tempFile);
        } else {}
      }
    }

    if (!_isMounted) return;

    setState(() {
      pgImage.addAll(downloadedImages);
    });
  }

  String getMangaGenre(String genre) {
    switch (genre) {
      case "Action":
        return 'Action Manga';
      case "Romance":
        return 'Romance Manga';
      case "Mystery":
        return 'Mystery Manga';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Chapter ${widget.chIdentifier}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: pgImage.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : PhotoViewGallery.builder(
              itemCount: pgImage.length,
              builder: (context, index) {
                final currentPage = pgImage[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(currentPage),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.contained * 1.75,
                );
              },
            ),
    );
  }
}
