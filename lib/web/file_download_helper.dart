import 'dart:convert';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

Future<void> downloadTextFile({
  required String filename,
  required String content,
}) async {
  final bytes = Uint8List.fromList(utf8.encode(content));
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/json;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.style.display = 'none';

  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
