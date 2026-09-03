// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;

void downloadFileWeb(List<int> bytes, String fileName, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void initiateWebSpeechRecognition({
  required Function(String) onResult,
  required Function(dynamic) onError,
  required Function(bool) onDone,
}) {
  try {
    js.context.callMethod('initiateSpeechRecognition', [
      'en-SG',
      js.allowInterop((dynamic transcript) {
        final text = transcript?.toString().trim();
        if (text != null && text.isNotEmpty) {
          onResult(text);
        }
      }),
      js.allowInterop((dynamic error) {
        onError(error);
      }),
      js.allowInterop((dynamic gotResult) {
        onDone(gotResult == true);
      }),
    ]);
  } catch (e) {
    onError(e);
  }
}
