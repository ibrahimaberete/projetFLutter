import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/loading.dart';
import '../../models/chat_params.dart';
import '../../models/message.dart';
import '../../services/message_database.dart';
import 'message_item.dart';

class Chat extends StatefulWidget {
  const Chat({Key? key, required this.chatParams}) : super(key: key);
  final ChatParams chatParams;

  @override
  _ChatState createState() => _ChatState(chatParams);
}

class _ChatState extends State<Chat> {
  final MessageDatabaseService messageService = MessageDatabaseService();

  _ChatState(this.chatParams);

  final ChatParams chatParams;

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();

  int _nbElement = 20;
  static const int PAGINATION_INCREMENT = 20;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    listScrollController.addListener(_scrollListener);
  }

  _scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _nbElement += PAGINATION_INCREMENT;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [buildListMessage(), buildInput()],
        ),
        isLoading ? Loading() : Container()
      ],
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: StreamBuilder<List<Message>>(
        stream:
            messageService.getMessage(chatParams.getChatGroupId(), _nbElement),
        builder: (BuildContext context, AsyncSnapshot<List<Message>> snapshot) {
          if (snapshot.hasData) {
            List<Message> listMessage = snapshot.data ?? List.from([]);
            return ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemBuilder: (context, index) => MessageItem(
                  message: listMessage[index],
                  userId: chatParams.userUid,
                  isLastMessage: isLastMessage(index, listMessage)),
              itemCount: listMessage.length,
              reverse: true,
              controller: listScrollController,
            );
          } else {
            return Center(child: Loading());
          }
        },
      ),
    );
  }

  bool isLastMessage(int index, List<Message> listMessage) {
    if (index == 0) return true;
    if (listMessage[index].idFrom != listMessage[index - 1].idFrom) return true;
    return false;
  }

  Widget buildInput() {
    return Container(
      width: double.infinity,
      height: 50.0,
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black, width: 0.5)),
          color: Colors.white),
      child: Row(
        children: [
          Material(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: const Icon(Icons.image),
                onPressed: pickImage,
                color: Colors.blueGrey,
              ),
            ),
            color: Colors.white,
          ),
          Flexible(
            child: TextField(
              onSubmitted: (value) {
                onSendMessage(textEditingController.text, 0);
              },
              style: const TextStyle(color: Colors.blueGrey, fontSize: 15.0),
              controller: textEditingController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Your message...',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          // Button send message
          Material(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => onSendMessage(textEditingController.text, 0),
                color: Colors.blueGrey,
              ),
            ),
            color: Colors.white,
          ),
          IconButton(
            icon: Icon(Icons.emoji_emotions),
            onPressed: () {
              // Afficher le sélecteur d'emoji
              showEmojiPickerModal();
            },
            color: Colors.blueGrey,
          )
        ],
      ),
    );
  }

  Future<void> pickImage() async {
    ImagePicker imagePicker = ImagePicker();

    XFile? pickedFile =
        await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      PickedFile pickedFileConverted = PickedFile(pickedFile.path);

      setState(() {
        isLoading = true;
      });
      uploadFile(pickedFileConverted);
    }
  }

  Future uploadFile(PickedFile file) async {
    String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpeg";
    try {
      Reference reference = FirebaseStorage.instance.ref(fileName);
      final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'picked-file-path': file.path});
      TaskSnapshot snapshot;
      if (kIsWeb) {
        snapshot = await reference.putData(await file.readAsBytes(), metadata);
      } else {
        snapshot = await reference.putFile(File(file.path), metadata);
      }

      String imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1);
      });
    } on Exception {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Error! Try again!");
    }
  }

  void onSendMessage(String content, int type) {
    if (content.trim() != '') {
      messageService.onSendMessage(
          chatParams.getChatGroupId(),
          Message(
              idFrom: chatParams.userUid,
              idTo: chatParams.peer.uid,
              timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
              content: content,
              type: type));
      listScrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      textEditingController.clear();
    } else {
      Fluttertoast.showToast(
          msg: 'Nothing to send',
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  void showEmojiPickerModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return EmojiPicker(
          onEmojiSelected: (emoji, category) {
            textEditingController.text += category.emoji;
          },
          config: Config(),
        );
      },
    );
  }
}
