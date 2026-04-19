import 'dart:async';
import 'package:doantotnghiep/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:doantotnghiep/features/admin/presentation/admin_tutor_approval_screen.dart';
import 'package:doantotnghiep/features/admin/presentation/admin_users_screen.dart';
import 'package:doantotnghiep/features/admin/presentation/admin_reports_screen.dart';
import 'package:doantotnghiep/features/admin/presentation/widgets/admin_scaffold.dart';
import 'package:doantotnghiep/features/admin/presentation/admin_ai_audit_screen.dart';
import 'package:doantotnghiep/features/admin/presentation/admin_market_map_screen.dart';
import 'package:doantotnghiep/features/admin/presentation/admin_course_approval_screen.dart';
import 'package:doantotnghiep/features/admin/presentation/admin_verification_screen.dart';
import 'package:doantotnghiep/features/admin/presentation/admin_log_screen.dart';
import 'package:doantotnghiep/features/admin/presentation/admin_finance_screen.dart';
import 'package:doantotnghiep/features/admin/presentation/admin_user_detail_screen.dart';
import 'package:doantotnghiep/features/admin/presentation/admin_user_activity_screen.dart';
import 'package:doantotnghiep/features/admin/presentation/admin_system_settings_screen.dart';
import 'package:doantotnghiep/features/admin/presentation/admin_broadcast_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/tutor_dashboard_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/widgets/tutor_scaffold.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/student_request_list_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/booking_request_list_screen.dart';
import 'package:doantotnghiep/features/rating/presentation/tutor_reviews_screen.dart';
import 'package:doantotnghiep/features/report/presentation/create_report_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/tutor_statistics_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/blog_list_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/tutor_tuition_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/tutor_transaction_history_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/tutor_profile_edit_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/tutor_material_screen.dart';
import 'package:doantotnghiep/features/group/presentation/create_group_screen.dart';
import 'package:doantotnghiep/features/search/presentation/group_management_screen.dart';
import 'package:doantotnghiep/features/group/domain/models/group_request.dart';
import 'package:doantotnghiep/features/group/domain/models/course.dart';
import 'package:doantotnghiep/features/profile/presentation/views/ekyc_update_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/create_class_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/my_classes_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/class_detail_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/recommended_requests_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/student_booking_detail_screen.dart';
import 'package:doantotnghiep/features/auth/domain/models/app_user.dart';

// Quiz Imports
import 'package:doantotnghiep/features/tutor_dashboard/presentation/tutor_quiz_management_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/create_quiz_screen.dart';
import 'package:doantotnghiep/features/quiz/presentation/views/student_quiz_list_screen.dart';
import 'package:doantotnghiep/features/quiz/presentation/views/quiz_detail_screen.dart';
import 'package:doantotnghiep/features/quiz/presentation/views/quiz_taking_screen.dart';
import 'package:doantotnghiep/features/quiz/presentation/views/quiz_result_screen.dart';
import 'package:doantotnghiep/features/quiz/domain/models/quiz.dart';

// Ensure this model is generic enough or imported correctly if missing
import 'package:doantotnghiep/features/student/presentation/create_tutor_request_screen.dart';
import 'package:doantotnghiep/features/student/presentation/my_request_detail_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/domain/models/tutor_request.dart';
import 'package:doantotnghiep/features/notification/presentation/notification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doantotnghiep/features/student/presentation/my_requests_screen.dart';
import 'package:doantotnghiep/features/student/presentation/my_groups_screen.dart';
import 'package:doantotnghiep/features/student/presentation/group_detail_screen.dart';
import 'package:doantotnghiep/features/student/presentation/my_enrolled_classes_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:doantotnghiep/features/tutor/presentation/views/favorite_tutors_screen.dart';
import 'package:doantotnghiep/features/home/presentation/home_screen.dart';
import 'package:doantotnghiep/features/auth/presentation/views/login_screen.dart';
import 'package:doantotnghiep/features/auth/presentation/views/register_screen.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:doantotnghiep/features/tutor/presentation/views/tutor_detail_screen.dart';
import 'package:doantotnghiep/features/booking/presentation/views/booking_screen.dart';
import 'package:doantotnghiep/features/booking/presentation/views/booking_review_screen.dart';
import 'package:doantotnghiep/features/search/presentation/search_screen.dart';
import 'package:doantotnghiep/features/profile/presentation/views/profile_screen.dart';
import 'package:doantotnghiep/features/wallet/presentation/wallet_screen.dart';
import 'package:doantotnghiep/features/home/presentation/widgets/scaffold_with_navbar.dart';
import 'package:doantotnghiep/features/booking/presentation/views/schedule_screen.dart';
import 'package:doantotnghiep/features/booking/presentation/views/video_call_screen.dart';
import 'package:doantotnghiep/features/smart_match/presentation/learning_style_quiz_screen.dart';
import 'package:doantotnghiep/features/smart_match/presentation/matched_tutors_screen.dart';
import 'package:doantotnghiep/features/chat/presentation/chat_screen.dart';
import 'package:doantotnghiep/features/chat/presentation/chat_list_screen.dart';
import 'package:doantotnghiep/features/chat/presentation/class_chat_screen.dart';
import 'package:doantotnghiep/features/community/presentation/community_screen.dart';
import 'package:doantotnghiep/features/community/presentation/create_question_screen.dart';
import 'package:doantotnghiep/features/community/presentation/question_detail_screen.dart';
import 'package:doantotnghiep/features/profile/presentation/views/settings_screen.dart';
import 'package:doantotnghiep/features/profile/presentation/views/change_password_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/tutor_schedule_management_screen.dart';
import 'package:doantotnghiep/features/map/presentation/map_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(navigationShell: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) {
              final subject = state.uri.queryParameters['subject'];
              return SearchScreen(initialSubject: subject);
            },
          ),
          GoRoute(
             path: '/schedule',
             builder: (context, state) => const ScheduleScreen(),
          ),
          GoRoute(
             path: '/history',
             builder: (context, state) => const ScheduleScreen(initialIndex: 1),
          ),
          GoRoute(
             path: '/messages',
             builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
             path: '/ekyc',
             builder: (context, state) {
               final isTutor = state.uri.queryParameters['isTutor'] == 'true';
               return EkycUpdateScreen(isTutor: isTutor);
             },
          ),
           GoRoute(
             path: '/notifications',
             builder: (context, state) => const NotificationScreen(),
           ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
         path: '/create-tutor-request',
         builder: (context, state) => const CreateTutorRequestScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/my-requests',
        builder: (context, state) => const MyRequestsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/my-study-groups',
        builder: (context, state) => const MyGroupsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/favorite-tutors',
        builder: (context, state) => const FavoriteTutorsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/group-detail',
        builder: (context, state) {
           final group = state.extra as GroupRequest;
           return GroupDetailScreen(group: group);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
         path: '/my-request-detail',
         builder: (context, state) {
            final request = state.extra as TutorRequest;
            return MyRequestDetailScreen(request: request);
         },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tutor-detail',
        builder: (context, state) {
           final tutor = state.extra as Tutor;
           return TutorDetailScreen(tutor: tutor);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/booking',
        builder: (context, state) {
           final tutor = state.extra as Tutor;
           return BookingScreen(tutor: tutor);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/booking-review',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final tutor = extra['tutor'] as Tutor;
          // Nullable extra params
          final date = extra['date'] as DateTime?;
          final timeSlot = extra['timeSlot'] as String?;
          final totalPrice = extra['totalPrice'] as double;
          final bookingType = extra['bookingType'] as String? ?? 'single';
          
          final durationMonths = extra['durationMonths'] as int?;
          final selectedDays = extra['selectedDays'] as List<int>?;
          final learningMode = extra['learningMode'] as String?;
          final longTermSchedule = extra['longTermSchedule'] as Map<int, List<String>>?;

          return BookingReviewScreen(
            tutor: tutor,
            totalPrice: totalPrice,
            bookingType: bookingType,
            selectedDate: date,
            selectedTimeSlot: timeSlot,
            durationMonths: durationMonths,
            selectedDays: selectedDays,
            learningMode: learningMode,
            longTermSchedule: longTermSchedule,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/video-call',
        builder: (context, state) {
           final bookingId = state.extra as String? ?? '';
           return VideoCallScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/report',
        builder: (context, state) {
           return const CreateReportScreen();
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/create-group',
        builder: (context, state) {
           final group = state.extra as GroupRequest?;
           return CreateGroupScreen(group: group);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/group-management',
        builder: (context, state) {
           final group = state.extra as GroupRequest;
           return GroupManagementScreen(group: group);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/create-class',
        builder: (context, state) {
           final classToEdit = state.extra as Course?;
           final isGroup = state.uri.queryParameters['isGroup'] == 'true';
           return CreateClassScreen(classToEdit: classToEdit, isGroup: isGroup);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/class-detail',
        builder: (context, state) {
           final course = state.extra as Course;
           return ClassDetailScreen(course: course);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/my-classes',
        builder: (context, state) {
           final index = int.tryParse(state.uri.queryParameters['index'] ?? '0') ?? 0;
           return MyClassesScreen(initialIndex: index);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/my-enrolled-classes',
        builder: (context, state) => const MyEnrolledClassesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/chat',
        builder: (context, state) {
          Tutor? tutor;
          TutorRequest? initialRequest;

          if (state.extra is Tutor) {
            tutor = state.extra as Tutor;
          } else if (state.extra is Map) {
            final map = state.extra as Map;
            if (map.containsKey('tutor')) {
              tutor = map['tutor'] as Tutor;
              initialRequest = map['request'] as TutorRequest?;
            } else {
              // Construct Tutor from Partner Info (Chat History)
              tutor = Tutor(
                id: map['partner_id']?.toString() ?? '0',
                userId: map['partner_id']?.toString() ?? '0', // Critical for Chat Target
                name: map['partner_name'] ?? 'Chat Partner',
                avatarUrl: map['partner_avatar'] ?? '',
                // Dummy Data for Required Fields
                rating: 0, reviewCount: 0, hourlyRate: 0, subjects: [], bio: '', 
                location: '', gender: 'Khác', teachingMode: [], address: '', weeklySchedule: {},
              );
            }
          }

          if (tutor == null) return const Scaffold(body: Center(child: Text("Lỗi: Không tìm thấy thông tin")));

           return ChatScreen(tutor: tutor, initialRequest: initialRequest);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tutor-reviews',
        builder: (context, state) {
           final tutor = state.extra as Tutor;
           return TutorReviewsScreen(tutor: tutor);
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AdminScaffold(navigationShell: child);
        },
        routes: [
          // Smart Match
        GoRoute(
          path: '/smart-match',
          builder: (context, state) => const LearningStyleQuizScreen(),
          routes: [
            GoRoute(
              path: 'results',
              builder: (context, state) {
                final tags = state.extra as List<String>? ?? [];
                return MatchedTutorsScreen(tags: tags);
              },
            ),
          ],
        ),
        // Community
        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityScreen(),
        ),
        GoRoute(
          path: '/activity', // Existing
          builder: (context, state) => const AdminUserActivityScreen(userId: 0), // Placeholder if needed or verified usage
        ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
            routes: [
               GoRoute(
                path: 'users',
                builder: (context, state) => const AdminUsersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final userId = int.parse(state.pathParameters['id']!);
                      return AdminUserDetailScreen(userId: userId);
                    },
                    routes: [
                      GoRoute(
                        path: 'activities',
                        builder: (context, state) {
                          final userId = int.parse(state.pathParameters['id']!);
                          return AdminUserActivityScreen(userId: userId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'tutors',
                builder: (context, state) => const AdminTutorApprovalScreen(),
              ),
              GoRoute(
                path: 'approve',
                builder: (context, state) => const AdminTutorApprovalScreen(),
              ),
              GoRoute(
                path: 'reports',
                builder: (context, state) => const AdminReportsScreen(),
              ),
              GoRoute(
                path: 'ai-audit',
                builder: (context, state) => const AdminAiAuditScreen(),
              ),
              GoRoute(
                path: 'courses-approve',
                builder: (context, state) => const AdminCourseApprovalScreen(),
              ),
              GoRoute(
                path: 'market-map',
                builder: (context, state) => const AdminMarketMapScreen(),
              ),
              GoRoute(
                path: 'verification',
                builder: (context, state) => const AdminVerificationScreen(),
              ),
              GoRoute(
                path: 'logs',
                builder: (context, state) => const AdminLogScreen(),
              ),
              GoRoute(
                path: 'finance',
                builder: (context, state) => const AdminFinanceScreen(),
              ),
              GoRoute(
                path: 'system-settings',
                builder: (context, state) => const AdminSystemSettingsScreen(),
              ),
              GoRoute(
                path: 'broadcast',
                builder: (context, state) => const AdminBroadcastScreen(),
              ),
            ],
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) {
          return TutorScaffold(navigationShell: child);
        },
        routes: [
          GoRoute(
            path: '/tutor-dashboard',
            builder: (context, state) => const TutorDashboardScreen(),
            routes: [
              GoRoute(
                 path: 'find-students',
                 builder: (context, state) => const StudentRequestListScreen(),
              ),
              GoRoute(
                 path: 'booking-requests',
                 builder: (context, state) => const BookingRequestListScreen(),
              ),
              GoRoute(
                 path: 'schedule',
                 builder: (context, state) => const ScheduleScreen(), // Reusing Student Schedule for now or create new
              ),
              GoRoute(
                 path: 'history',
                 builder: (context, state) => const ScheduleScreen(initialIndex: 1),
              ),
              GoRoute(
                 path: 'messages',
                 builder: (context, state) => const ChatListScreen(),
              ),
               GoRoute(
                 path: 'profile',
                 builder: (context, state) => const ProfileScreen(), // Reusing Profile
              ),
              GoRoute(
                 path: 'statistics',
                 builder: (context, state) => const TutorStatisticsScreen(),
              ),
              GoRoute(
                 path: 'blog',
                 builder: (context, state) => const BlogListScreen(),
              ),
              GoRoute(
                 path: 'tuition',
                 builder: (context, state) => const TutorTuitionScreen(),
              ),
              GoRoute(
                 path: 'recommended-requests',
                 builder: (context, state) => const RecommendedRequestsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/community',
        builder: (context, state) => const CommunityScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/create-question',
        builder: (context, state) => const CreateQuestionScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/question-detail/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return QuestionDetailScreen(questionId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tutor-schedule-management',
        builder: (context, state) => const TutorScheduleManagementScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tutor-profile-edit',
        builder: (context, state) {
          final extra = state.extra;
          final tutor = extra is Tutor ? extra : Tutor.fromJson(extra as Map<String, dynamic>);
          return TutorProfileEditScreen(tutor: tutor);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tutor-materials',
        builder: (context, state) => const TutorMaterialScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tutor-dashboard/transaction-history',
        builder: (context, state) => const TutorTransactionHistoryScreen(),
      ),
      // Quiz Routes
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tutor-quiz-management',
        builder: (context, state) => const TutorQuizManagementScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tutor-create-quiz',
        builder: (context, state) => const CreateQuizScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/quizzes',
        builder: (context, state) => const StudentQuizListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/quiz-detail/:id',
        builder: (context, state) {
           final quiz = state.extra as Quiz?;
           final quizId = int.parse(state.pathParameters['id']!);
           return QuizDetailScreen(quizId: quizId, initialData: quiz);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/quiz-taking/:id',
        builder: (context, state) {
           final quiz = state.extra as Quiz;
           return QuizTakingScreen(quizId: quiz.id, quiz: quiz);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/quiz-result',
        builder: (context, state) {
           final extra = state.extra as Map<String, dynamic>;
           return QuizResultScreen(quiz: extra['quiz'] as Quiz, result: extra['result']);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/class-chat',
        builder: (context, state) {
          final course = state.extra as Course;
          return ClassChatScreen(course: course);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/student-booking-detail',
        builder: (context, state) {
           final student = state.extra as AppUser;
           return StudentBookingDetailScreen(student: student);
        },
      ),
    ],
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final role = prefs.getString('user_role');
      
      final loggingIn = state.uri.path == '/login' || state.uri.path == '/register';

      // 1. Not logged in
      if (token == null) {
        return loggingIn ? null : '/login';
      }

      // 2. Logged in
      if (loggingIn || state.uri.path == '/') {
        if (role == 'admin') {
          return '/admin';
        } else if (role == 'tutor') {
           return '/tutor-dashboard';
        } else {
          return '/';
        }
      }

      return null;
    },
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) { 
        notifyListeners(); 
      },
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

