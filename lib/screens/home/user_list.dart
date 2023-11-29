import 'package:flutter/material.dart';
import 'package:projetfinal/services/database.dart';
import 'package:provider/provider.dart';

import '../../models/chat_params.dart';
import '../../models/user.dart';

class UserList extends StatefulWidget {
  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  List<String> favoriteUsers = [];

  void fetchFavorites() async {
    final currentUser = Provider.of<AppUser?>(context);

    if (currentUser != null) {
      final DatabaseService databaseService = DatabaseService(currentUser.uid);

      List<String> favorites =
          await databaseService.getUserFavorites(currentUser.uid);

      setState(() {
        favoriteUsers = favorites;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = Provider.of<List<AppUserData>>(context);
    final currentUser = Provider.of<AppUser?>(context);
    final DatabaseService databaseService = DatabaseService(currentUser!.uid);

    fetchFavorites();
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];

        if (currentUser != null && currentUser.uid == user.uid) {
          return Container();
        }

        return UserTile(
          user: user,
          isFavorite: favoriteUsers.contains(user.uid),
          toggleFavorite: () {
            setState(() {
              print(favoriteUsers);
              if (favoriteUsers.contains(user.uid)) {
                favoriteUsers.remove(user.uid);
              } else {
                favoriteUsers.add(user.uid);
              }
              databaseService.updateUserFavorites(
                  currentUser!.uid, favoriteUsers);
            });
          },
        );
      },
    );
  }
}

class UserTile extends StatelessWidget {
  final AppUserData user;
  final bool isFavorite;
  final VoidCallback toggleFavorite;

  UserTile({
    required this.user,
    required this.isFavorite,
    required this.toggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AppUser?>(context);
    if (currentUser == null) throw Exception("current user not found");
    return GestureDetector(
      onTap: () {
        if (currentUser.uid == user.uid) return;
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: ChatParams(currentUser.uid, user),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Card(
          margin:
              EdgeInsets.only(top: 12.0, bottom: 6.0, left: 20.0, right: 20.0),
          child: ListTile(
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: toggleFavorite,
            ),
          ),
        ),
      ),
    );
  }
}
