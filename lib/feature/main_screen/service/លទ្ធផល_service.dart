import '../api/លទ្ធផល_api.dart';

class ResultService {
  // Fetch results with date and time filtering
  static Future<List<Map<String, dynamic>>> fetchResults({
    required DateTime date,
    String? lotteryTime,
  }) async {
    return await ResultApi.getResults(date: date, lotteryTime: lotteryTime);
  }

  // Get available lottery times
  static Future<List<String>> getLotteryTimes() async {
    return await ResultApi.getLotteryTimes();
  }

  // Get all channels
  static Future<List<Map<String, dynamic>>> getChannels() async {
    return await ResultApi.getChannels();
  }

  // Format result data for display - shows all channels even if empty
  static Future<List<Map<String, dynamic>>> formatResultsForDisplay(
    List<Map<String, dynamic>> results,
  ) async {
    // Get all channels from database
    List<Map<String, dynamic>> channels = await getChannels();

    // Create a map of results by channel code
    Map<String, Map<String, dynamic>> resultsByChannel = {};
    for (var result in results) {
      List<String> types = [
        'A',
        'B',
        'C',
        'D',
        'F',
        'I',
        'K',
        'L',
        'N',
        'O',
        'Lo',
      ];

      for (String type in types) {
        String twoKey = 'type_${type.toLowerCase()}_two';
        String threeKey = 'type_${type.toLowerCase()}_three';

        List<dynamic> twoNumbers = result[twoKey] ?? [];
        List<dynamic> threeNumbers = result[threeKey] ?? [];

        if (twoNumbers.isNotEmpty || threeNumbers.isNotEmpty) {
          // Find the sort_order for this channel
          var channel = channels.firstWhere(
            (ch) => ch['channel_code'] == type,
            orElse: () => {'sort_order': 999},
          );

          resultsByChannel[type] = {
            'id': '${result['id']}_$type',
            'category': type,
            'twoDigitNumbers': twoNumbers
                .map((num) => num.toString().padLeft(2, '0'))
                .toList(),
            'threeDigitNumbers': threeNumbers
                .map((num) => num.toString().padLeft(3, '0'))
                .toList(),
            'lottery_time': result['time'] ?? '',
            'date': result['date'] ?? '',
            'hasTwoDigit': twoNumbers.isNotEmpty,
            'hasThreeDigit': threeNumbers.isNotEmpty,
            'sort_order': channel['sort_order'],
          };
        }
      }
    }

    // Create final list with all channels, showing empty ones as blank
    List<Map<String, dynamic>> formattedResults = [];
    for (var channel in channels) {
      String channelCode = channel['channel_code'];
      int sortOrder = channel['sort_order'];

      if (resultsByChannel.containsKey(channelCode)) {
        // Channel has results
        formattedResults.add(resultsByChannel[channelCode]!);
      } else {
        // Channel has no results - show as blank
        formattedResults.add({
          'id': 'empty_$channelCode',
          'category': channelCode,
          'twoDigitNumbers': <String>[],
          'threeDigitNumbers': <String>[],
          'lottery_time': '',
          'date': '',
          'hasTwoDigit': false,
          'hasThreeDigit': false,
          'sort_order': sortOrder,
        });
      }
    }

    // Sort by sort_order
    formattedResults.sort((a, b) {
      int orderA = a['sort_order'] ?? 999;
      int orderB = b['sort_order'] ?? 999;
      return orderA.compareTo(orderB);
    });

    return formattedResults;
  }
}
