import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:gap/gap.dart';

class UploadChapters extends StatefulWidget {
  UploadChapters({
    super.key,
    required this.mangaName,
    required this.genre,
    required this.mangaId,
    required this.chapter,
    required this.isNewChapter,
  });

  String genre;
  String mangaId;
  String chapter;
  String mangaName;
  bool isNewChapter;
  @override
  State<UploadChapters> createState() => _UploadChaptersState();
}

class _UploadChaptersState extends State<UploadChapters> {
  @override
  void initState() {
    super.initState();
  }

  CollectionReference? imgRef;
  Reference? ref;

  List<File> imagesToUpload = [];
  FilePickerResult? result;
  PlatformFile? platformFile;
  File? file;

  Future<void>? donePicking;

  Future<void> pickImages() async {
    try {
      EasyLoading.show(status: 'Loading images...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: ['jpg', 'png'],
      );
      if (result != null) {
        for (var file in result.files) {
          imagesToUpload.add(File(file.path!));
        }
      }
    } catch (error) {
    } finally {
      EasyLoading.dismiss();
      setState(() {});
    }
  }

  Future<void> uploadFile() async {
    String genre = '';
    EasyLoading.show(status: 'Uploading chapter...');
    for (int a = 0; a < imagesToUpload.length; a++) {
      String filename = 'pg ${(a + 1).toString().padLeft(3, '0')}';
      String chapter = widget.chapter.toString().padLeft(3, '0');
      String chapterId = widget.chapter;
      ref = FirebaseStorage.instance
          .ref()
          .child('${widget.mangaName}/chapters/$chapter/$filename');
      try {
        await ref!.delete();
      } catch (deleteError) {}

      await ref!
          .putFile((imagesToUpload[a]),
              SettableMetadata(customMetadata: {'filename': filename}))
          .whenComplete(() async {
        await ref!.getDownloadURL().then((value) {
          try {
            switch (widget.genre) {
              case "Action":
                genre = 'Action Manga';
                break;
              case "Romance":
                genre = 'Romance Manga';
                break;
              case "Mystery":
                genre = 'Mystery Manga';
                break;
            }
            FirebaseFirestore.instance
                .collection(genre)
                .doc(widget.mangaId)
                .collection('chapters')
                .doc('Chapter $chapter')
                .set({
              'id': chapterId,
              'pgNumber': '${a + 1}',
            });

            FirebaseFirestore.instance
                .collection(genre)
                .doc(widget.mangaId)
                .collection('chapters')
                .doc('Chapter $chapter')
                .collection(filename)
                .doc('image')
                .set({'url': value});
          } catch (error) {
            EasyLoading.showError('Upload failed');
            return;
          }
        });
      });
    }
    if (widget.isNewChapter) {
      FirebaseFirestore.instance
          .collection(genre)
          .doc(widget.mangaId)
          .update({'chapters': FieldValue.increment(1)});
    }
    EasyLoading.dismiss();
    EasyLoading.showSuccess('Chapter uploaded');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload chapters"),
        actions: [
          IconButton(
              onPressed: () {
                donePicking = pickImages();
              },
              icon: Icon(Icons.add_outlined))
        ],
      ),
      body: Column(
        children: [
          Visibility(
            visible: imagesToUpload.isNotEmpty ? false : true,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 250),
                child: Column(
                  children: [
                    Icon(
                      Icons.image,
                      size: 40,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "Pages will preview here",
                      style: TextStyle(fontSize: 17),
                    )
                  ],
                ),
              ),
            ),
          ),
          Visibility(
            visible: imagesToUpload.isNotEmpty ? true : false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    uploadFile();
                  },
                  child: Text('Upload'),
                ),
                const Gap(10),
                ElevatedButton(
                  onPressed: () {
                    imagesToUpload.clear();
                    setState(() {});
                  },
                  child: Text('Clear'),
                ),
              ],
            ),
          ),
          if (donePicking != null)
            FutureBuilder(
              future: donePicking,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                return Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var file in imagesToUpload)
                          Container(
                            padding: EdgeInsets.all(8),
                            child: Image.file(file),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
