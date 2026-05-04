import 'package:mindcoach/models/consultant_model.dart';

/// Görüntülü arama rotası: danışman + (onboarding) deneme modu bilgisi.
class VideoCallRouteArgs {
  const VideoCallRouteArgs({
    required this.specialist,
    this.isTrial = false,
  });

  final ConsultantModel specialist;
  final bool isTrial;
}
