import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:jm_imports/features/repairs/domain/repair.dart';
import 'package:jm_imports/features/sales/domain/sale.dart';

class TicketPdfService {
  static Future<Uint8List> generateRepairTicket(Repair repair) async {
    final pdf = pw.Document();

    // Load logo image
    ByteData logoByteData;
    try {
      logoByteData = await rootBundle.load('assets/images/app_logo.png');
    } catch (_) {
      logoByteData = ByteData(0);
    }
    final logoImage = logoByteData.lengthInBytes > 0
        ? pw.MemoryImage(logoByteData.buffer.asUint8List())
        : null;

    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(repair.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Thermal receipt style format (80mm width)
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Center(
                  child: pw.Image(logoImage, width: 50, height: 50),
                ),
              pw.SizedBox(height: 4),
              pw.Text(
                'JM IMPORTS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Reparación de Celulares & Importaciones',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 6),

              pw.Text(
                'TICKET DE RECEPCIÓN',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'N° Ticket: #${repair.id.substring(0, repair.id.length > 8 ? 8 : repair.id.length).toUpperCase()}',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Fecha: $dateStr',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
              ),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),

              // Cliente info
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CLIENTE:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text(repair.clientName, style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 6),
                    pw.Text('EQUIPO:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${repair.deviceBrand} ${repair.deviceModel}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    if (repair.imei != null && repair.imei!.isNotEmpty)
                      pw.Text('IMEI: ${repair.imei}', style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 6),
                    pw.Text('FALLA REPORTADA:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text(repair.reportedProblem, style: const pw.TextStyle(fontSize: 8)),
                    if (repair.physicalCondition.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text('CONDICIÓN FÍSICA:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(repair.physicalCondition, style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),

              // Total Estimado
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('COSTO ESTIMADO:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('S/ ${repair.repairCost.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),

              // Terminos y Condiciones
              pw.Text(
                'TÉRMINOS DEL SERVICIO',
                style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '1. Indispensable presentar este ticket para retirar el equipo.\n'
                '2. Equipos sin retirar tras 30 días pasarán a almacén.\n'
                '3. La garantía solo cubre la falla y repuesto reparado.',
                style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 10),
              pw.Text(
                '¡Gracias por su preferencia!',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateSaleReceipt(Sale sale) async {
    final pdf = pw.Document();

    ByteData logoByteData;
    try {
      logoByteData = await rootBundle.load('assets/images/app_logo.png');
    } catch (_) {
      logoByteData = ByteData(0);
    }
    final logoImage = logoByteData.lengthInBytes > 0
        ? pw.MemoryImage(logoByteData.buffer.asUint8List())
        : null;

    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(sale.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Center(
                  child: pw.Image(logoImage, width: 50, height: 50),
                ),
              pw.SizedBox(height: 4),
              pw.Text(
                'JM IMPORTS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Venta de Repuestos & Accesorios',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 6),

              pw.Text(
                'COMPROBANTE DE VENTA',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Cliente: ${sale.clientName}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Fecha: $dateStr',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
              ),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),

              // Items table
              pw.Column(
                children: sale.items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '${item.quantity}x ${item.sparePartName}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Text(
                          'S/ ${item.totalPrice.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text('S/ ${sale.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Text(
                '¡Gracias por su compra!',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printOrShareRepairTicket(Repair repair) async {
    final pdfBytes = await generateRepairTicket(repair);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'Ticket_${repair.id}.pdf',
    );
  }

  static Future<void> printOrShareSaleReceipt(Sale sale) async {
    final pdfBytes = await generateSaleReceipt(sale);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'Venta_${sale.id}.pdf',
    );
  }
}
