import 'dart:convert';
import 'dart:collection';
import 'package:http/http.dart' as http;

class QualityLinks {
  String? videoId;
  final String accessToken = "ba1f80c3c84fd5409c7e68f612ce8322";

  QualityLinks(this.videoId);

  getQualitiesSync() {
    return getQualitiesAsync();
  }

  Future<SplayTreeMap?> getQualitiesAsync() async {
    try {
      final vimeoLink = Uri.tryParse('https://api.vimeo.com/videos/$videoId');

      var response = await http.get(
        vimeoLink!,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body)['request']['files'];
        final dashData = jsonData['dash'];
        final hlsData = jsonData['hls'];
        final defaultCDN = hlsData['default_cdn'];
        final cdnVideoUrl =
            (hlsData['cdns'][defaultCDN]['url'] as String?) ?? '';
        final rawStreamUrls =
            (dashData['streams'] as List<dynamic>?) ?? <dynamic>[];

        final sepList = cdnVideoUrl.split('/sep/video/');
        final firstUrlPiece = sepList.firstOrNull ?? '';
        final lastUrlPiece =
            ((sepList.lastOrNull ?? '').split('/').lastOrNull) ??
                (sepList.lastOrNull ?? '');

        final SplayTreeMap videoList = SplayTreeMap();

        for (final item in rawStreamUrls) {
          final urlId =
              ((item['id'] ?? '') as String).split('-').firstOrNull ?? '';

          videoList.putIfAbsent(
            "${item['quality']} ${item['fps']}",
                () => '$firstUrlPiece/sep/video/$urlId/$lastUrlPiece',
          );
        }

        if (videoList.isEmpty) {
          videoList.putIfAbsent(
            '720 30',
                () => cdnVideoUrl,
          );
        }

        return videoList;
      } else {
        print('=====> ERROR: ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (error) {
      print('=====> REQUEST ERROR: $error');
      return null;
    }
  }
}
