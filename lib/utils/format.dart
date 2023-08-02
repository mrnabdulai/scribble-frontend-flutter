import 'dart:convert';

class FormatUtils {
  bool isValidJson(String jsonString) {
    try {
      // Attempt to decode the JSON string
      json.decode(jsonString);
      return true; // If decoding succeeds, the JSON is valid
    } catch (e) {
      return false; // If an exception is caught, the JSON is invalid
    }
  }
}
