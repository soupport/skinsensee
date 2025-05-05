import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class DataLoader {
  Future<List<String>> loadSkinConcerns() async {
    // Load the CSV file from assets
    final rawData = await rootBundle.loadString('assets/skinsense_boots_products.csv');
    List<List<dynamic>> rows = const CsvToListConverter().convert(rawData);

    // Find the index of the "Skin_Concerns" column
    int skinConcernsIndex = rows[0].indexOf('Skin_Concerns');
    if (skinConcernsIndex == -1) {
      throw Exception("Skin_Concerns column not found in the CSV");
    }

    // Create a Set to store skin concerns and remove duplicates
    Set<String> skinConcernsSet = <String>{};

    // Start iterating from the second row (since the first row is the header)
    for (var i = 1; i < rows.length; i++) {
      // Extract the skin concern from the current row and split by comma
      String skinConcern = rows[i][skinConcernsIndex].toString();

      // Split skin concerns by commas (if multiple concerns are in the same field)
      List<String> individualConcerns = skinConcern.split(',').map((concern) => concern.trim()).toList();

      // Add each individual concern to the Set (automatically removes duplicates)
      skinConcernsSet.addAll(individualConcerns);

      // You can also print the skin concerns for each product row for debugging purposes
      print('Skin Concerns for Row $i: $individualConcerns');
    }

    // Convert the Set back to a List and return it
    return skinConcernsSet.toList();
  }
}
