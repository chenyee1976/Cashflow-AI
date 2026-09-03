void downloadFileWeb(List<int> bytes, String fileName, String mimeType) {
  // Non-web fallback
}

void initiateWebSpeechRecognition({
  required Function(String) onResult,
  required Function(dynamic) onError,
  required Function(bool) onDone,
}) {
  onError('unsupported');
}
