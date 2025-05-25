import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationBellIcon extends StatelessWidget {
  final VoidCallback? onTap;
  const NotificationBellIcon({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return IconButton(
        icon: const Icon(Icons.notifications_none_rounded, color: Colors.black, size: 28),
        onPressed: onTap,
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('seen', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        int unseenCount = 0;
        if (snapshot.hasData) {
          unseenCount = snapshot.data!.docs.length;
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.black, size: 28),
              onPressed: onTap,
            ),
            if (unseenCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      unseenCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
