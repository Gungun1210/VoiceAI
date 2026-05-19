import 'package:url_launcher/url_launcher.dart';

class FoodService {
  // Opens Swiggy → Zomato 
  Future<String> orderFood() async {
    // Try Swiggy app
    final swiggy = Uri.parse('swiggy://home');
    if (await canLaunchUrl(swiggy)) {
      await launchUrl(swiggy, mode: LaunchMode.externalApplication);
      return 'swiggy';
    }

    // Try Zomato app
    final zomato = Uri.parse('zomato://home');
    if (await canLaunchUrl(zomato)) {
      await launchUrl(zomato, mode: LaunchMode.externalApplication);
      return 'zomato';
    }

    // Browser fallback — Swiggy web
    final web = Uri.parse('https://www.swiggy.com');
    await launchUrl(web, mode: LaunchMode.externalApplication);
    return 'browser';
  }
}