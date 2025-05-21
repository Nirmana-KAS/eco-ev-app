import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/station_model.dart';

class MapService {
  static Future<List<StationModel>> getStations() async {
    final snapshot = await FirebaseFirestore.instance.collection('stations').get();
    return snapshot.docs.map((doc) => StationModel.fromMap(doc.data(), doc.id)).toList();
  }
}
