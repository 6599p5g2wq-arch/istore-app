/// إعدادات التطبيق الأساسية.
///
/// غيّر [baseUrl] إلى رابط متجرك بعد رفعه على الاستضافة
/// (نفس المجلد الذي فيه index.php). بدون سلاش في النهاية.
///
/// للتجربة على محاكي أندرويد مع XAMPP على نفس الجهاز:
///   const String baseUrl = 'http://10.0.2.2/istore';
class AppConfig {
  static const String baseUrl = 'http://10.0.2.2/istore';
  static const String apiBase = '$baseUrl/api/v1';
  static const String appName = 'آي ستور';
}
