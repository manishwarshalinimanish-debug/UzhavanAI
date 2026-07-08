import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  static Future<void> generateAndShareReport({
    required Map<String, dynamic> reportData,
  }) async {
    final pdf = pw.Document();

    final analytics = Map<String, dynamic>.from(reportData["analytics"] ?? {});

    final farmers = List<dynamic>.from(reportData["farmers"] ?? []);

    final predictions = List<dynamic>.from(reportData["predictions"] ?? []);

    final recoveryTrackers = List<dynamic>.from(
      reportData["recovery_trackers"] ?? [],
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            margin: const pw.EdgeInsets.only(bottom: 15),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "UzhavanAI",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text("Smart Farming Report"),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Page ${context.pageNumber} of ${context.pagesCount}",
              style: const pw.TextStyle(fontSize: 10),
            ),
          );
        },
        build: (context) {
          return [
            pw.Text(
              reportData["project"]?.toString() ?? "UzhavanAI",
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 8),

            pw.Text(
              reportData["description"]?.toString() ??
                  "AI Crop Disease Detection and Smart Farming Assistant",
            ),

            pw.SizedBox(height: 25),

            _sectionTitle("Analytics Summary"),

            pw.TableHelper.fromTextArray(
              headers: const ["Category", "Count"],
              data: [
                ["Farmers", analytics["total_farmers"] ?? 0],
                ["Predictions", analytics["total_predictions"] ?? 0],
                ["Healthy Predictions", analytics["healthy_predictions"] ?? 0],
                [
                  "Diseased Predictions",
                  analytics["diseased_predictions"] ?? 0,
                ],
                ["Recovery Trackers", analytics["recovery_trackers"] ?? 0],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellPadding: const pw.EdgeInsets.all(7),
            ),

            pw.SizedBox(height: 25),

            _sectionTitle("Farmers"),

            if (farmers.isEmpty)
              pw.Text("No farmers found.")
            else
              pw.TableHelper.fromTextArray(
                headers: const ["Name", "Phone", "Village"],
                data: farmers.map((item) {
                  final farmer = Map<String, dynamic>.from(item);

                  return [
                    farmer["name"]?.toString() ?? "--",
                    farmer["phone"]?.toString() ?? "--",
                    farmer["village"]?.toString() ?? "--",
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellPadding: const pw.EdgeInsets.all(6),
              ),

            pw.SizedBox(height: 25),

            _sectionTitle("Prediction History"),

            if (predictions.isEmpty)
              pw.Text("No predictions found.")
            else
              ...predictions.map((item) {
                final prediction = Map<String, dynamic>.from(item);

                return pw.Container(
                  width: double.infinity,
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfText("Crop", prediction["crop"]),
                      _pdfText("Disease", prediction["disease"]),
                      _pdfText(
                        "Confidence",
                        "${prediction["confidence"] ?? 0}%",
                      ),
                      _pdfText("Treatment", prediction["treatment"]),
                      _pdfText("Prevention", prediction["prevention"]),
                      _pdfText("Fertilizer", prediction["fertilizer"]),
                      _pdfText("Date", prediction["created_at"]),
                    ],
                  ),
                );
              }),

            pw.SizedBox(height: 25),

            _sectionTitle("Recovery Trackers"),

            if (recoveryTrackers.isEmpty)
              pw.Text("No recovery trackers found.")
            else
              pw.TableHelper.fromTextArray(
                headers: const ["Crop", "Disease", "Status", "Started"],
                data: recoveryTrackers.map((item) {
                  final tracker = Map<String, dynamic>.from(item);

                  return [
                    tracker["crop"]?.toString() ?? "--",
                    tracker["disease"]?.toString() ?? "--",
                    tracker["status"]?.toString() ?? "--",
                    tracker["started_at"]?.toString() ?? "--",
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellPadding: const pw.EdgeInsets.all(6),
              ),

            pw.SizedBox(height: 30),

            pw.Divider(),

            pw.Center(
              child: pw.Text(
                "Generated by UzhavanAI",
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ];
        },
      ),
    );

    final Uint8List pdfBytes = await pdf.save();

    await Printing.sharePdf(bytes: pdfBytes, filename: "UzhavanAI_Report.pdf");
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _pdfText(String title, dynamic value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: "$title: ",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(text: value?.toString() ?? "--"),
          ],
        ),
      ),
    );
  }
}
