import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../main.dart' show appStore, sharedPref;
import 'Constants.dart' show FIRST_NAME, LAST_NAME, USER_NAME, CONTACT_NUMBER;

/// What goes on a receipt. Built from recharge, bill payment or wallet top-up data.
class ReceiptData {
  final String title; // e.g. "Mobile Recharge"
  final String status; // success | pending | failed
  final num amount;
  final String reference;
  final DateTime date;
  final List<MapEntry<String, String>> rows;
  final String? note;

  ReceiptData({
    required this.title,
    required this.status,
    required this.amount,
    required this.reference,
    required this.date,
    this.rows = const [],
    this.note,
  });

  /// Recharge / bill payment transaction as returned by the recharge APIs.
  factory ReceiptData.fromRecharge(Map<String, dynamic> t) {
    num n(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;
    final service = '${t['service_type'] ?? ''}';
    final surcharge = n(t['surcharge']);
    final rawStatus = '${t['status'] ?? 'pending'}';
    return ReceiptData(
      title: service.toLowerCase() == 'prepaid' ? 'Mobile Recharge' : (service.isEmpty ? 'Payment' : '$service Payment'),
      status: rawStatus == 'success' ? 'success' : (rawStatus == 'pending' ? 'pending' : 'failed'),
      amount: n(t['total_amount']) > 0 ? n(t['total_amount']) : n(t['amount']),
      reference: '${t['client_id'] ?? t['id'] ?? ''}',
      date: DateTime.tryParse('${t['created_at']}')?.toLocal() ?? DateTime.now(),
      rows: [
        if ('${t['operator_name'] ?? ''}'.isNotEmpty) MapEntry('Operator', '${t['operator_name']}'),
        if ('${t['number'] ?? ''}'.isNotEmpty) MapEntry('Number', '${t['number']}'),
        if (service.isNotEmpty) MapEntry('Service', service),
        MapEntry('Amount', ReceiptService.money(n(t['amount']))),
        if (surcharge > 0) MapEntry('Convenience fee', ReceiptService.money(surcharge)),
        MapEntry('Paid from', 'S Taxi wallet'),
        if ('${t['operator_txn_id'] ?? ''}'.isNotEmpty) MapEntry('Operator ref', '${t['operator_txn_id']}'),
      ],
      note: rawStatus == 'refund' || rawStatus == 'failure' ? 'This payment failed and the amount was returned to your wallet.' : null,
    );
  }
}

extension WalletTopupReceipt on ReceiptData {
  /// Wallet top-up as returned by the wallet-topup history API.
  static ReceiptData fromTopup(Map<String, dynamic> t) {
    num n(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;
    final method = '${t['method'] ?? ''}';
    final rawStatus = '${t['status'] ?? ''}';
    return ReceiptData(
      title: 'Wallet Top-up',
      status: rawStatus == 'success' ? 'success' : (['awaiting_verification', 'initiated'].contains(rawStatus) ? 'pending' : 'failed'),
      amount: n(t['amount']),
      reference: '${t['reference'] ?? ''}',
      date: DateTime.tryParse('${t['created_at']}')?.toLocal() ?? DateTime.now(),
      rows: [
        MapEntry('Added to', 'S Taxi wallet'),
        MapEntry('Method', method == 'manual' ? 'Manual payment' : (method == 'admin' ? 'Added by S Taxi' : 'UPI')),
        if ('${t['upi_id'] ?? ''}'.isNotEmpty) MapEntry('Paid to', '${t['upi_id']}'),
        if ('${t['utr'] ?? ''}'.isNotEmpty) MapEntry('UTR', '${t['utr']}'),
      ],
    );
  }
}

class ReceiptService {
  static const _brand = PdfColor.fromInt(0xFF0A3D96);
  static const _brandLight = PdfColor.fromInt(0xFFEEF3FB);
  static const _grey = PdfColor.fromInt(0xFF6B7280);
  static const _text = PdfColor.fromInt(0xFF1B1F2A);

  static String money(num value) => '₹${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';

  static String _fileName(ReceiptData data) {
    final safeRef = data.reference.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    return 'STaxi_Receipt_${safeRef.isEmpty ? DateFormat('yyyyMMdd_HHmmss').format(data.date) : safeRef}.pdf';
  }

  static String _customerName() {
    final full = '${sharedPref.getString(FIRST_NAME) ?? ''} ${sharedPref.getString(LAST_NAME) ?? ''}'.trim();
    return full.isNotEmpty ? full : (sharedPref.getString(USER_NAME) ?? '');
  }

  static Future<Uint8List> buildPdf(ReceiptData data) async {
    final customer = _customerName();
    final mobile = sharedPref.getString(CONTACT_NUMBER) ?? '';
    final supportPhone = appStore.settingModel.contactNumber ?? '';
    final supportEmail = appStore.settingModel.siteEmail ?? '';
    final receiptNo = 'RCPT-${DateFormat('yyMMdd').format(data.date)}-${data.reference.length > 6 ? data.reference.substring(data.reference.length - 6) : data.reference}';

    final regular = pw.Font.ttf(await rootBundle.load('images/receipt_fonts/NotoSans-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('images/receipt_fonts/NotoSans-Bold.ttf'));
    final logo = pw.MemoryImage((await rootBundle.load('images/app_images/ic_app_logo.png')).buffer.asUint8List());

    final statusColor = data.status == 'success'
        ? PdfColor.fromInt(0xFF1E9E57)
        : data.status == 'pending'
            ? PdfColor.fromInt(0xFFE08A00)
            : PdfColor.fromInt(0xFFD93025);
    final statusText = data.status == 'success' ? 'SUCCESSFUL' : (data.status == 'pending' ? 'IN PROCESS' : 'FAILED');

    final doc = pw.Document(title: '${data.title} receipt', author: 'S Taxi', theme: pw.ThemeData.withFont(base: regular, bold: bold));

    doc.addPage(pw.Page(
      // A5 width, a little taller so long bill details and the footer always fit on one page
      pageFormat: PdfPageFormat(PdfPageFormat.a5.width, PdfPageFormat.a5.height * 1.2),
      margin: pw.EdgeInsets.all(24),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // header
          pw.Container(
            padding: pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(color: _brand, borderRadius: pw.BorderRadius.circular(12)),
            child: pw.Row(children: [
              pw.Container(
                width: 38,
                height: 38,
                padding: pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Image(logo),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('S Taxi', style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Payment receipt', style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                ]),
              ),
              pw.Text(DateFormat('dd MMM yyyy').format(data.date), style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
            ]),
          ),
          pw.SizedBox(height: 14),

          // receipt number + billed to
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('BILLED TO', style: pw.TextStyle(color: _grey, fontSize: 8, letterSpacing: 1)),
                pw.SizedBox(height: 2),
                pw.Text(customer.isEmpty ? 'S Taxi customer' : customer, style: pw.TextStyle(color: _text, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                if (mobile.isNotEmpty) pw.Text(mobile, style: pw.TextStyle(color: _grey, fontSize: 9)),
              ]),
            ),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('RECEIPT NO.', style: pw.TextStyle(color: _grey, fontSize: 8, letterSpacing: 1)),
              pw.SizedBox(height: 2),
              pw.Text(receiptNo, style: pw.TextStyle(color: _text, fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ]),
          ]),
          pw.SizedBox(height: 16),

          // amount + status
          pw.Center(child: pw.Text(data.title, style: pw.TextStyle(color: _grey, fontSize: 11))),
          pw.SizedBox(height: 4),
          pw.Center(child: pw.Text(money(data.amount), style: pw.TextStyle(color: _text, fontSize: 28, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: pw.BoxDecoration(color: statusColor, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Text(statusText, style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
            ),
          ),
          pw.SizedBox(height: 22),

          // details
          pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: pw.BoxDecoration(color: _brandLight, borderRadius: pw.BorderRadius.circular(10)),
            child: pw.Column(children: [
              for (final row in [
                MapEntry('Transaction ID', data.reference),
                MapEntry('Date & time', DateFormat('dd MMM yyyy, hh:mm a').format(data.date)),
                ...data.rows,
              ])
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(vertical: 5),
                  child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.SizedBox(width: 110, child: pw.Text(row.key, style: pw.TextStyle(color: _grey, fontSize: 10))),
                    pw.Expanded(child: pw.Text(row.value, textAlign: pw.TextAlign.right, style: pw.TextStyle(color: _text, fontSize: 10, fontWeight: pw.FontWeight.bold))),
                  ]),
                ),
            ]),
          ),

          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300),
          pw.Row(children: [
            pw.Expanded(child: pw.Text(data.status == 'failed' ? 'Amount refunded' : (data.status == 'pending' ? 'Amount debited' : 'Total paid'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
            pw.Text(money(data.amount), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _brand)),
          ]),
          if (data.note != null) ...[
            pw.SizedBox(height: 10),
            pw.Text(data.note!, style: pw.TextStyle(color: _grey, fontSize: 9)),
          ],
          pw.Spacer(),
          if (supportPhone.isNotEmpty || supportEmail.isNotEmpty)
            pw.Center(
              child: pw.Text(
                'Need help? ${[supportPhone, supportEmail].where((v) => v.isNotEmpty).join('  ·  ')}',
                style: pw.TextStyle(color: _text, fontSize: 9),
              ),
            ),
          pw.SizedBox(height: 4),
          pw.Center(child: pw.Text('This is a computer generated receipt and does not need a signature.', style: pw.TextStyle(color: _grey, fontSize: 8))),
          pw.SizedBox(height: 2),
          pw.Center(child: pw.Text('Thank you for using S Taxi', style: pw.TextStyle(color: _brand, fontSize: 9, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    ));

    return doc.save();
  }

  /// Opens the system share sheet (WhatsApp, Gmail, Drive...) with the PDF attached.
  static Future<void> share(ReceiptData data) async {
    final bytes = await buildPdf(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_fileName(data)}');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'S Taxi ${data.title} receipt',
      text: '${data.title} of ${money(data.amount)} · Ref ${data.reference}',
    ));
  }

  /// Saves the PDF to Downloads (app documents on iOS) and opens it. Returns the saved path.
  static Future<String> download(ReceiptData data) async {
    final bytes = await buildPdf(data);
    final name = _fileName(data);

    File? saved;
    if (Platform.isAndroid) {
      // public Downloads first so the rider finds it in the Files app; app storage if that is not allowed
      for (final path in ['/storage/emulated/0/Download', (await getExternalStorageDirectory())?.path]) {
        if (path == null) continue;
        try {
          final file = File('$path/$name');
          await file.writeAsBytes(bytes, flush: true);
          saved = file;
          break;
        } catch (_) {}
      }
    }
    saved ??= await File('${(await getApplicationDocumentsDirectory()).path}/$name').writeAsBytes(bytes, flush: true);

    await OpenFile.open(saved.path, type: 'application/pdf');
    return saved.path;
  }
}
