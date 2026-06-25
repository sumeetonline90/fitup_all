import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../lib/firebase_options.dart';

Future<void> main(List<String> args) async {
  final bool execute = args.contains('--execute');
  final int batchSize = _readBatchSize(args) ?? 200;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Query<Map<String, dynamic>> query =
      firestore.collectionGroup('water_logs');

  final AggregateQuerySnapshot countSnapshot = await query.count().get();
  final int total = countSnapshot.count ?? 0;
  stdout.writeln('Found $total water log documents.');
  if (!execute) {
    stdout.writeln(
      'Dry run only. Re-run with --execute to delete in batches of $batchSize.',
    );
    exit(0);
  }

  if (total == 0) {
    stdout.writeln('No water logs to delete.');
    exit(0);
  }

  int deleted = 0;
  while (true) {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await query.limit(batchSize).get();
    if (snap.docs.isEmpty) {
      break;
    }
    final WriteBatch batch = firestore.batch();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    deleted += snap.docs.length;
    stdout.writeln('Deleted $deleted / $total...');
  }
  stdout.writeln('Done. Deleted $deleted water logs.');
}

int? _readBatchSize(List<String> args) {
  final String? token = args.cast<String?>().firstWhere(
        (String? item) => item?.startsWith('--batch-size=') ?? false,
        orElse: () => null,
      );
  if (token == null) {
    return null;
  }
  return int.tryParse(token.split('=').last);
}
