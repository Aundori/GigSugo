import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryConfig {
  // Replace these with your actual Cloudinary credentials
  static const String cloudName = 'di77va09t';
  static const String apiKey = '365118546452734';
  static const String apiSecret = 'IYN8RyWjeUH9amc_yK96T69oKcg';
  
  // Cloudinary instance - requires cloud name and API key
  static final cloudinary = CloudinaryPublic(cloudName, apiKey);
}
