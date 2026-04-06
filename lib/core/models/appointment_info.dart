class AppointmentInfo {
  final String specialistName;
  final String topicKey; // örn: 'mentalHealth'
  final DateTime? appointmentDateTime; // Randevu tarihi ve saati
  final String? status; // Randevu durumu: 'scheduled', 'completed', 'cancelled'
  final int? consultantId; // Consultant ID (dil bazlı isim ve job için)
  final String? job; // Consultant'ın görevi
  final int? appointmentId; // Appointment ID (iptal/geri alma için)

  const AppointmentInfo({
    required this.specialistName,
    required this.topicKey,
    this.appointmentDateTime,
    this.status,
    this.consultantId,
    this.job,
    this.appointmentId,
  });
}
