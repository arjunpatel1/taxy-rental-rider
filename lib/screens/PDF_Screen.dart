import '../manage_imports.dart';
import 'package:http/http.dart' as http;

class PDFViewer extends StatefulWidget {
  final String invoice;
  final String? filename;

  PDFViewer({required this.invoice, this.filename = ""});

  @override
  State<PDFViewer> createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  PdfController? pdfController;

  @override
  void initState() {
    super.initState();
    viewPDF();
  }

  Future<void> viewPDF() async {
    try {
      pdfController = PdfController(
        document: PdfDocument.openData(InternetFile.get(
          "${widget.invoice}",
        )),
        initialPage: 0,
      );
    } catch (e) {}
  }

  bool sharing = false;

  /// Downloads the invoice to a temp file and opens the share sheet (WhatsApp, Gmail...).
  Future<void> shareInvoice() async {
    setState(() => sharing = true);
    try {
      final response = await http.get(Uri.parse(widget.invoice));
      if (response.statusCode != 200) throw 'download failed';
      final name = widget.filename.validate().isEmpty ? 'invoice' : widget.filename.validate();
      final file = File('${(await getTemporaryDirectory()).path}/$name.pdf');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')], subject: '$mAppName ride invoice'));
    } catch (e) {
      toast('Could not share the invoice');
    }
    if (mounted) setState(() => sharing = false);
  }

  Future<void> downloadPDF() async {
    appStore.setLoading(true);
    final response = await http.get(Uri.parse(widget.invoice));
    if (response.statusCode == 200) {
      try {
        final bytes = response.bodyBytes;
        String path = "~";
        if (Platform.isIOS) {
          var directory = await getApplicationDocumentsDirectory();
          path = directory.path;
        } else {
          path = "/storage/emulated/0/Download";
        }
        String fileName = widget.filename.validate().isEmpty ? "invoice" : widget.filename.validate();
        File file = File('${path}/${fileName}.pdf');
        await file.writeAsBytes(bytes, flush: true);
        appStore.setLoading(false);
        toast("invoice downloaded at ${file.path}");

        final filef = File(file.path);
        if (await filef.exists()) {
          OpenFile.open(file.path);
        } else {
          throw 'File does not exist';
        }
      } catch (e) {
        throw Exception('Failed to download PDF');
      }
    } else {
      appStore.setLoading(false);
      toast("Failed to download pdf");
      throw Exception('Failed to download PDF');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text("${language.invoice}", style: boldTextStyle(color: Colors.white)),
          actions: [
            IconButton(
              tooltip: 'Share invoice',
              onPressed: sharing ? null : shareInvoice,
              icon: sharing ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.share_rounded, color: Colors.white),
            ),
            IconButton(
              tooltip: 'Download invoice',
              onPressed: () {
                downloadPDF();
              },
              icon: Icon(Icons.download, color: Colors.white),
            ),
          ],
        ),
        body: Stack(
          children: [
            PdfView(controller: pdfController!),
            PdfPageNumber(
              controller: pdfController!,
              builder: (_, loadingState, page, pagesCount) {
                if (page == 0) return loaderWidget();
                return SizedBox();
              },
            ),
            Observer(builder: (context) => Visibility(visible: appStore.isLoading, child: Positioned.fill(child: loaderWidget()))),
          ],
        ));
  }
}
