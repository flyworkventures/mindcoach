import 'package:flutter/material.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';

/// Backend'den gelen feature key'lerini (ör: "stress_management")
/// lokalize edilmiş string'lere çevirir.
class FeatureConvert {
  final BuildContext context;

  FeatureConvert(this.context);

  String call(String key) {
    final l10n = context.l10n;
    switch (key) {
      // family_assistant
      case 'family_conflicts':
        return l10n.featureFamilyConflicts;
      case 'parenting':
        return l10n.featureParenting;
      case 'communication':
        return l10n.featureCommunication;
      case 'boundaries':
        return l10n.featureBoundaries;
      case 'relationship_repair':
        return l10n.featureRelationshipRepair;
      case 'divorce_support':
        return l10n.featureDivorceSupport;
      case 'child_behavior':
        return l10n.featureChildBehavior;
      case 'family_harmony':
        return l10n.featureFamilyHarmony;

      // adult
      case 'stress_management':
        return l10n.featureStressManagement;
      case 'self_confidence':
        return l10n.featureSelfConfidence;
      case 'life_balance':
        return l10n.featureLifeBalance;
      case 'career_guidance':
        return l10n.featureCareerGuidance;
      case 'emotional_regulation':
        return l10n.featureEmotionalRegulation;
      case 'decision_making':
        return l10n.featureDecisionMaking;
      case 'motivation':
        return l10n.featureMotivation;
      case 'personal_growth':
        return l10n.featurePersonalGrowth;

      // child
      case 'emotional_awareness':
        return l10n.featureEmotionalAwareness;
      case 'social_skills':
        return l10n.featureSocialSkills;
      case 'school_adaptation':
        return l10n.featureSchoolAdaptation;
      case 'self_expression':
        return l10n.featureSelfExpression;
      case 'fear_management':
        return l10n.featureFearManagement;
      case 'friendship_building':
        return l10n.featureFriendshipBuilding;
      case 'focus_attention':
        return l10n.featureFocusAttention;
      case 'behavioral_support':
        return l10n.featureBehavioralSupport;

      // teenage
      case 'identity_development':
        return l10n.featureIdentityDevelopment;
      case 'peer_pressure':
        return l10n.featurePeerPressure;
      case 'academic_stress':
        return l10n.featureAcademicStress;
      case 'self_esteem':
        return l10n.featureSelfEsteem;
      case 'digital_wellbeing':
        return l10n.featureDigitalWellbeing;
      case 'anger_management':
        return l10n.featureAngerManagement;
      case 'future_planning':
        return l10n.featureFuturePlanning;
      case 'parent_communication':
        return l10n.featureParentCommunication;

      // personal
      case 'loneliness':
        return l10n.featureLoneliness;
      case 'anxiety_support':
        return l10n.featureAnxietySupport;
      case 'grief_processing':
        return l10n.featureGriefProcessing;
      case 'mindfulness':
        return l10n.featureMindfulness;
      case 'sleep_improvement':
        return l10n.featureSleepImprovement;
      case 'overthinking':
        return l10n.featureOverthinking;
      case 'self_discovery':
        return l10n.featureSelfDiscovery;
      case 'emotional_healing':
        return l10n.featureEmotionalHealing;

      // exam_anxiety
      case 'test_anxiety':
        return l10n.featureTestAnxiety;
      case 'study_techniques':
        return l10n.featureStudyTechniques;
      case 'time_management':
        return l10n.featureTimeManagement;
      case 'performance_pressure':
        return l10n.featurePerformancePressure;
      case 'concentration':
        return l10n.featureConcentration;
      case 'relaxation_methods':
        return l10n.featureRelaxationMethods;
      case 'exam_preparation':
        return l10n.featureExamPreparation;
      case 'confidence_building':
        return l10n.featureConfidenceBuilding;

      default:
        // Bilinmeyen key → snake_case'i Title Case'e çevir
        return key
            .split('_')
            .map((w) => w.isNotEmpty
                ? '${w[0].toUpperCase()}${w.substring(1)}'
                : '')
            .join(' ');
    }
  }
}
