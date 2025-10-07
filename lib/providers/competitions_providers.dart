import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_config.dart';

final competitionArchiveProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseConfig.client
      .from('organized_competitions')
      .select('organized_competition_id,name,description,start_date,end_date,competition_visible_id,status')
      .eq('is_deleted', false)
      .order('start_date', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});


