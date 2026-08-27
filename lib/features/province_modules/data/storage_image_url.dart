import 'package:supabase_flutter/supabase_flutter.dart';

String? publicStorageImageUrl(
  SupabaseClient client,
  String bucket,
  String? path,
) {
  if (path == null || path.trim().isEmpty) return null;
  return client.storage.from(bucket).getPublicUrl(path.trim());
}
