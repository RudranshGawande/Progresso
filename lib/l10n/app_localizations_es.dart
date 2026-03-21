// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get accountSettings => 'Configuración de Cuenta';

  @override
  String get accountSettingsDesc =>
      'Administre sus preferencias de cuenta, idioma y configuración regional.';

  @override
  String get language => 'Idioma';

  @override
  String get timezone => 'Zona Horaria';

  @override
  String get weekStart => 'Inicio de Semana';

  @override
  String get sunday => 'Domingo';

  @override
  String get monday => 'Lunes';

  @override
  String get deleteAccount => 'Eliminar Cuenta';

  @override
  String get totalHours => 'Total Horas';

  @override
  String get productivityTrends => 'Tendencias de Productividad';

  @override
  String get dailyProductivityTrends => 'Tendencias de Productividad Diaria';

  @override
  String get hourlyProductivityTrends => 'Tendencias de Productividad Horaria';

  @override
  String get weeklyFocusComparison => 'Comparación de Enfoque Semanal';

  @override
  String get yearlyProductivityTrends => 'Tendencias de Productividad Anual';

  @override
  String get totalHoursWorked => 'Total Horas Trabajadas';

  @override
  String get focusScore => 'Puntuación de Enfoque';

  @override
  String get dailyGoal => 'Meta Diaria';

  @override
  String get currentStreak => 'Racha Actual';

  @override
  String get goalAnalytics => 'Análisis de Objetivos';

  @override
  String get dashboardOverview => 'Resumen del Panel';

  @override
  String get welcomeBack =>
      'Bienvenido de nuevo, esto es lo que está pasando hoy.';

  @override
  String get searchSessions => 'Buscar sesiones...';

  @override
  String get startNewSession => 'Iniciar Nueva Sesión';

  @override
  String get weeklyProgress => 'Progreso Semanal';

  @override
  String totalFocusHours(Object hours) {
    return 'Total horas de enfoque esta semana: ${hours}h';
  }

  @override
  String get current => 'Actual';

  @override
  String get previous => 'Anterior';

  @override
  String get start => 'Iniciar';

  @override
  String focus(Object hours) {
    return 'Enfoque: ${hours}h';
  }

  @override
  String get performanceInsights => 'Información de Rendimiento';

  @override
  String get dailyOverview => 'Resumen Diario';

  @override
  String get weeklyTotals => 'Totales Semanales';

  @override
  String get monthlyTotals => 'Totales Mensuales';

  @override
  String get annualTotals => 'Totales Anuales';

  @override
  String get avgSessionLength => 'Promedio Sesión';

  @override
  String get tasksCompleted => 'Tareas Completadas';

  @override
  String get today => 'Hoy';

  @override
  String get week => 'Semana';

  @override
  String get month => 'Mes';

  @override
  String get year => 'Año';

  @override
  String get custom => 'Personalizado';

  @override
  String get deleteAccountDesc =>
      'Elimine permanentemente su cuenta y todos los datos asociados. Esta acción no se puede deshacer.';

  @override
  String get delete => 'Eliminar';
}
