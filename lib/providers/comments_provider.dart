import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';

final commentsProvider = StreamProvider.family<List<CommentModel>, String>((ref, itemId) {
  return FirebaseFirestore.instance
      .collection('comments')
      .where('itemId', isEqualTo: itemId)
      .snapshots()
      .map((snapshot) {
        final comments = snapshot.docs
            .map((doc) => CommentModel.fromMap(doc.data()))
            .toList();
        comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return comments;
      });
});
