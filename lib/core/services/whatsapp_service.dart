import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jm_imports/features/repairs/domain/repair.dart';
import 'package:jm_imports/features/sales/domain/sale.dart';

class WhatsAppService {
  static String formatPhoneNumber(String rawPhone) {
    String clean = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 9 && clean.startsWith('9')) {
      return '51$clean';
    }
    return clean;
  }

  static Future<bool> launchWhatsApp(String phone, String message) async {
    final cleanPhone = formatPhoneNumber(phone);
    final encodedMessage = Uri.encodeComponent(message);
    final urlString = 'https://wa.me/$cleanPhone?text=$encodedMessage';
    final Uri url = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      return false;
    }
  }

  static Future<bool> sendRepairReceipt({
    required Repair repair,
    required String clientPhone,
  }) async {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(repair.createdAt);
    final msg = '''
🛠️ *JM IMPORTS - Ticket de Recepción*
Hola *${repair.clientName}*, hemos registrado tu equipo en nuestro taller:

📲 *Equipo:* ${repair.deviceBrand} ${repair.deviceModel}
📋 *Falla reportada:* ${repair.reportedProblem}
${repair.physicalCondition.isNotEmpty ? '🔍 *Condición:* ${repair.physicalCondition}\n' : ''}💰 *Costo estimado:* S/ ${repair.repairCost.toStringAsFixed(2)}
📅 *Fecha:* $dateStr

Cualquier consulta estamos atentos por este medio. Gracias por confiar en *JM IMPORTS*.
''';
    return await launchWhatsApp(clientPhone, msg);
  }

  static Future<bool> sendRepairReady({
    required Repair repair,
    required String clientPhone,
  }) async {
    final msg = '''
🎉 *JM IMPORTS - Equipo Listo para Entrega*
Hola *${repair.clientName}*!

Tu equipo *${repair.deviceBrand} ${repair.deviceModel}* ya ha sido *REPARADO* exitosamente y se encuentra listo para entrega.

💰 *Monto a cancelar:* S/ ${repair.repairCost.toStringAsFixed(2)}

Te esperamos en nuestro local. ¡Gracias por elegir *JM IMPORTS*!
''';
    return await launchWhatsApp(clientPhone, msg);
  }

  static Future<bool> sendSaleReceipt({
    required Sale sale,
    required String clientPhone,
  }) async {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(sale.createdAt);
    final itemsList = sale.items
        .map((i) => '• ${i.quantity}x ${i.sparePartName} (S/ ${i.totalPrice.toStringAsFixed(2)})')
        .join('\n');

    final msg = '''
🛒 *JM IMPORTS - Comprobante de Venta*
Cliente: *${sale.clientName}*
Fecha: $dateStr

*Repuestos Adquiridos:*
$itemsList

💵 *TOTAL VENTA:* S/ ${sale.totalAmount.toStringAsFixed(2)}

¡Gracias por tu compra en *JM IMPORTS*!
''';
    return await launchWhatsApp(clientPhone, msg);
  }
}
