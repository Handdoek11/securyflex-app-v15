📁 COMPLETE BESTANDSOVERZICHT PER PAGINA - SECURYFLEX APP
🏢 BEDRIJFSKANT (COMPANY)
📊 1. DASHBOARD
🎯 Hoofdbestanden:
lib/company_dashboard/company_dashboard_home.dart - Main container
lib/company_dashboard/screens/company_dashboard_main.dart - Dashboard screen
lib/company_dashboard/screens/company_notifications_screen.dart - Notificaties
🧩 Widgets:
lib/company_dashboard/widgets/company_welcome_view.dart - Welkomst widget
lib/company_dashboard/widgets/active_jobs_overview.dart - Actieve jobs overzicht
lib/company_dashboard/widgets/applications_summary.dart - Sollicitaties samenvatting
lib/company_dashboard/widgets/revenue_metrics_view.dart - Omzet metrics
lib/company_dashboard/widgets/company_settings_overview.dart - Instellingen widget
🔧 Services:
lib/company_dashboard/services/company_service.dart - Company profiel service
lib/company_dashboard/services/job_posting_service.dart - Job management service
lib/company_dashboard/services/application_review_service.dart - Sollicitatie review service
📋 Models:
lib/company_dashboard/models/company_data.dart - Company profiel data
lib/company_dashboard/models/company_tab_data.dart - Navigatie tabs
🎨 Theming:
lib/company_dashboard/company_dashboard_theme.dart - Company theme
💼 2. JOBS
🎯 Hoofdbestanden:
lib/company_dashboard/screens/company_jobs_screen.dart - Jobs management screen
lib/company_dashboard/screens/job_posting_form_screen.dart - Job aanmaken formulier
lib/company_dashboard/screens/company_analytics_screen.dart - Job analytics
🧩 Widgets:
lib/company_dashboard/widgets/job_management_overview.dart - Job management widget
📋 Models:
lib/company_dashboard/models/job_posting_data.dart - Job posting models
🔧 Services:
lib/company_dashboard/services/job_posting_service.dart - Job posting service (gedeeld met Dashboard)
👥 3. SOLLICITATIES
🎯 Hoofdbestanden:
lib/company_dashboard/screens/company_applications_screen.dart - Sollicitaties overzicht
🧩 Widgets:
lib/company_dashboard/widgets/application_management_overview.dart - Sollicitatie management widget
📋 Models:
lib/company_dashboard/models/application_review_data.dart - Sollicitatie review models
🔧 Services:
lib/company_dashboard/services/application_review_service.dart - Application review service (gedeeld met Dashboard)
lib/marketplace/services/application_service.dart - Application service (gedeeld)
💬 4. CHAT
🎯 Hoofdbestanden:
lib/chat/screens/conversations_screen.dart - Chat overzicht (gedeeld)
lib/chat/screens/chat_screen.dart - Individual chat screen (gedeeld)
lib/chat/screens/notification_settings_screen.dart - Chat notificatie instellingen (gedeeld)
🧩 Widgets (Gedeeld):
lib/chat/widgets/unified_conversation_card.dart - Conversatie cards
lib/chat/widgets/unified_message_bubble.dart - Bericht bubbles
lib/chat/widgets/unified_chat_input.dart - Chat input
lib/chat/widgets/unified_typing_indicator.dart - Typing indicator
lib/chat/widgets/unified_attachment_picker.dart - Bijlage picker
lib/chat/widgets/unified_file_preview.dart - Bestand preview
lib/chat/widgets/unified_upload_progress.dart - Upload progress
lib/chat/widgets/assignment_context_widget.dart - Opdracht context
🔧 Services (Gedeeld):
lib/chat/services/chat_mockup_service.dart - Chat mockup service
lib/chat/services/notification_service.dart - Notificatie service
lib/chat/services/file_upload_service.dart - Bestand upload service
lib/chat/services/presence_service.dart - Online status service
lib/chat/services/read_receipt_service.dart - Leesbevestiging service
lib/chat/services/assignment_integration_service.dart - Opdracht integratie
lib/chat/services/auto_chat_service.dart - Automatische chat service
lib/chat/services/background_message_handler.dart - Background berichten
📋 Models (Gedeeld):
lib/chat/models/conversation_model.dart - Conversatie model
lib/chat/models/message_model.dart - Bericht model
lib/chat/models/typing_status_model.dart - Typing status model
🏗️ Architecture (Gedeeld):
lib/chat/bloc/chat_bloc.dart - Chat BLoC
lib/chat/bloc/chat_event.dart - Chat events
lib/chat/bloc/chat_state.dart - Chat states
lib/chat/repositories/chat_repository.dart - Chat repository interface
lib/chat/repositories/chat_repository_impl.dart - Chat repository implementatie
lib/chat/data_sources/chat_remote_data_source.dart - Remote data source
lib/chat/use_cases/create_conversation_use_case.dart - Conversatie aanmaken
lib/chat/use_cases/get_conversations_use_case.dart - Conversaties ophalen
lib/chat/use_cases/get_messages_use_case.dart - Berichten ophalen
lib/chat/use_cases/send_message_use_case.dart - Bericht versturen
🗄️ Database:
lib/chat/database/firestore_structure.dart - Firestore structuur
⚙️ 5. INSTELLINGEN
🎯 Hoofdbestanden:
lib/company_dashboard/screens/company_settings_screen.dart - Company instellingen screen
🧩 Widgets:
lib/company_dashboard/widgets/company_settings_overview.dart - Instellingen overzicht widget (gedeeld met Dashboard)
🌐 Localization:
lib/company_dashboard/localization/company_nl.dart - Nederlandse vertalingen
👮 BEVEILIGERSKANT (GUARD)
📊 1. DASHBOARD
🎯 Hoofdbestanden:
lib/beveiliger_dashboard/beveiliger_dashboard_home.dart - Main container
lib/beveiliger_dashboard/screens/beveiliger_dashboard_main.dart - Dashboard screen
lib/beveiliger_dashboard/screens/daily_overview_screen.dart - Dagelijks overzicht
🧩 Widgets:
lib/beveiliger_dashboard/widgets/earnings_card_widget.dart - Verdiensten card
lib/beveiliger_dashboard/widgets/active_jobs_widget.dart - Actieve jobs widget
lib/beveiliger_dashboard/widgets/recent_shifts_widget.dart - Recente diensten
lib/beveiliger_dashboard/widgets/shift_control_widget.dart - Dienst controle
lib/beveiliger_dashboard/widgets/quick_actions_widget.dart - Snelle acties
lib/beveiliger_dashboard/widgets/section_title_widget.dart - Sectie titels
lib/beveiliger_dashboard/widgets/hours_tracker_widget.dart - Uren tracker
🧩 Daily Overview Widgets:
lib/beveiliger_dashboard/widgets/daily_overview/daily_metrics_widget.dart - Dagelijkse metrics
lib/beveiliger_dashboard/widgets/daily_overview/time_tracking_widget.dart - Tijd tracking
lib/beveiliger_dashboard/widgets/daily_overview/earnings_breakdown_widget.dart - Verdiensten breakdown
lib/beveiliger_dashboard/widgets/daily_overview/planning_snapshot_widget.dart - Planning snapshot
lib/beveiliger_dashboard/widgets/daily_overview/performance_indicators_widget.dart - Prestatie indicatoren
lib/beveiliger_dashboard/widgets/daily_overview/notifications_widget.dart - Notificaties widget
🔧 Services:
lib/beveiliger_dashboard/services/daily_overview_service.dart - Daily overview service
lib/beveiliger_profiel/services/beveiliger_profiel_service.dart - Profiel service (gedeeld)
📋 Models:
lib/beveiliger_dashboard/models/daily_overview_data.dart - Daily overview data
lib/beveiliger_profiel/models/beveiliger_profiel_data.dart - Profiel data (gedeeld)
🎨 UI Components:
lib/beveiliger_dashboard/ui_view/glass_view.dart - Glass effect view
lib/beveiliger_dashboard/beveiliger_dashboard_theme.dart - Guard theme
🏗️ Architecture:
lib/beveiliger_dashboard/bloc/ - BLoC components (indien aanwezig)
💼 2. JOBS
🎯 Hoofdbestanden:
lib/marketplace/jobs_home_screen.dart - Jobs marketplace hoofdscherm
lib/marketplace/job_details_screen.dart - Job details screen
lib/marketplace/job_filters_screen.dart - Job filters screen
🧩 Widgets:
lib/marketplace/job_list_view.dart - Job lijst view
lib/marketplace/calendar_popup_view.dart - Kalender popup
lib/marketplace/custom_calendar.dart - Custom kalender
lib/marketplace/range_slider_view.dart - Range slider
lib/marketplace/slider_view.dart - Slider view
lib/marketplace/widgets/jobs_section_title.dart - Jobs sectie titel
🧩 Marketplace Widgets:
lib/marketplace/widgets/ - Diverse marketplace widgets
🔧 Services:
lib/marketplace/services/application_service.dart - Sollicitatie service
lib/marketplace/services/favorites_service.dart - Favorieten service
📋 Models:
lib/marketplace/model/security_job_data.dart - Security job data
🏗️ State Management:
lib/marketplace/state/job_state_manager.dart - Job state manager
lib/marketplace/bloc/ - BLoC components
🗄️ Repository:
lib/marketplace/repository/ - Data repositories
🎨 Theming:
lib/marketplace/marketplace_app_theme.dart - Marketplace theme
📱 Screens:
lib/marketplace/screens/favorites_screen.dart - Favorieten screen
💬 Dialogs:
lib/marketplace/dialogs/ - Diverse dialogs
📅 3. PLANNING
🎯 Hoofdbestanden:
lib/beveiliger_dashboard/screens/planning_screen.dart - Planning wrapper screen
lib/beveiliger_agenda/screens/planning_main_screen.dart - Planning hoofdscherm
🧩 Widgets:
lib/beveiliger_agenda/widgets/next_shift_card.dart - Volgende dienst card
lib/beveiliger_agenda/widgets/planning_categories.dart - Planning categorieën
lib/beveiliger_agenda/widgets/planning_calendar.dart - Planning kalender
📋 Models:
lib/beveiliger_agenda/models/shift_data.dart - Dienst data
lib/beveiliger_agenda/models/planning_category_data.dart - Planning categorie data
🔧 Utils:
lib/beveiliger_agenda/utils/date_utils.dart - Datum utilities
💬 4. CHAT
🎯 Hoofdbestanden:
Zelfde als bedrijfskant - volledig gedeeld systeem

lib/chat/screens/conversations_screen.dart - Chat overzicht
lib/chat/screens/chat_screen.dart - Individual chat screen
lib/chat/screens/notification_settings_screen.dart - Chat notificatie instellingen
Alle widgets, services, models, en architecture zijn gedeeld tussen beide user roles.

👤 5. PROFIEL
🎯 Hoofdbestanden:
lib/beveiliger_profiel/screens/beveiliger_profiel_screen.dart - Profiel hoofdscherm
lib/beveiliger_profiel/screens/persoonlijke_gegevens_edit_screen.dart - Persoonlijke gegevens bewerken
lib/beveiliger_profiel/screens/certificeringen_vaardigheden_edit_screen.dart - Certificeringen bewerken
lib/beveiliger_profiel/screens/prestatie_details_screen.dart - Prestatie details
🧩 Widgets:
lib/beveiliger_profiel/widgets/sectie_titel_widget.dart - Sectie titel widget
lib/beveiliger_profiel/widgets/persoonlijke_info_widget.dart - Persoonlijke info widget
lib/beveiliger_profiel/widgets/prestatie_statistieken_widget.dart - Prestatie statistieken
lib/beveiliger_profiel/widgets/certificeringen_overzicht_widget.dart - Certificeringen overzicht
lib/beveiliger_profiel/widgets/beschikbaarheid_overzicht_widget.dart - Beschikbaarheid overzicht
📋 Models:
lib/beveiliger_profiel/models/beveiliger_profiel_data.dart - Profiel data model
lib/beveiliger_profiel/models/beveiliger_profiel_content.dart - Profiel content model
🔧 Services:
lib/beveiliger_profiel/services/beveiliger_profiel_service.dart - Profiel service
🎮 Controllers:
lib/beveiliger_profiel/controllers/ - Profiel controllers
🎨 Theming:
lib/beveiliger_profiel/beveiliger_profiel_theme.dart - Profiel theme
🌐 GEDEELDE SYSTEMEN
🔐 Authenticatie:
lib/auth/auth_service.dart - Authenticatie service
lib/auth/auth_wrapper.dart - Auth wrapper
lib/auth/login_screen.dart - Login screen
lib/auth/registration_screen.dart - Registratie screen
lib/auth/profile_screen.dart - Profiel screen
lib/auth/introduction_animation_screen.dart - Intro animatie
lib/auth/bloc/ - Auth BLoC components
lib/auth/components/ - Auth componenten
lib/auth/repository/ - Auth repositories
🎨 Unified Design System:
lib/unified_theme_system.dart - Unified theme systeem
lib/unified_design_tokens.dart - Design tokens
lib/unified_header.dart - Unified header
lib/unified_buttons.dart - Unified buttons
lib/unified_card_system.dart - Unified cards
lib/unified_navigation_system.dart - Unified navigatie
lib/unified_input_system.dart - Unified inputs
lib/unified_shadows.dart - Unified shadows
lib/unified_status_colors.dart - Status kleuren
🧭 Navigatie:
lib/navigation/bloc/ - Navigatie BLoC
⚙️ Core Systemen:
lib/core/bloc/ - Core BLoC components
lib/core/utils/ - Core utilities
🔧 Configuratie:
lib/firebase_options.dart - Firebase configuratie
lib/main.dart - App entry point
📊 SAMENVATTING STATISTIEKEN
📁 Totaal Bestanden per Sectie:
Bedrijfskant:

Dashboard: ~15 bestanden
Jobs: ~8 bestanden
Sollicitaties: ~6 bestanden
Chat: ~25 bestanden (gedeeld)
Instellingen: ~4 bestanden
Beveiligerskant:

Dashboard: ~20 bestanden
Jobs: ~25 bestanden
Planning: ~8 bestanden
Chat: ~25 bestanden (gedeeld)
Profiel: ~15 bestanden
Gedeelde Systemen: ~25 bestanden

🎯 Totaal: ~150+ bestanden voor de complete SecuryFlex applicatie

Dit overzicht toont de uitgebreide en goed georganiseerde architectuur van de SecuryFlex app met duidelijke scheiding tussen bedrijfs- en beveiligerskant, terwijl belangrijke systemen zoals chat en design components efficiënt gedeeld worden.