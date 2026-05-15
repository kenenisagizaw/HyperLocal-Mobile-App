import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/constants/api_constants.dart';
import 'core/providers/sse_provider.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/sse_initializer_service.dart';
import 'data/datasources/remote/auth_api.dart';
import 'data/datasources/remote/booking_api.dart';
import 'data/datasources/remote/connects_api.dart';
import 'data/datasources/remote/dispute_api.dart';
import 'data/datasources/remote/message_api.dart';
import 'data/datasources/remote/notification_api.dart';
import 'data/datasources/remote/payment_api.dart';
import 'data/datasources/remote/provider_wallet_api.dart';
import 'data/datasources/remote/quote_api.dart';
import 'data/datasources/remote/request_api.dart';
import 'data/datasources/remote/review_api.dart';
import 'data/datasources/remote/wallet_api.dart';
import 'data/datasources/remote/withdrawal_api.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/connects_repository.dart';
import 'data/repositories/customer_repository.dart';
import 'data/repositories/dispute_repository.dart';
import 'data/repositories/message_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/payment_repository.dart';
import 'data/repositories/provider_repository.dart';
import 'data/repositories/provider_wallet_repository.dart';
import 'data/repositories/quote_repository.dart';
import 'data/repositories/request_repository.dart';
import 'data/repositories/review_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'data/repositories/withdrawal_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/providers/password_reset_provider.dart';
import 'features/auth/repositories/password_reset_repository.dart';
import 'features/bookings/providers/booking_provider.dart';
import 'features/bookings/providers/location_share_provider.dart';
import 'features/customer/providers/customer_directory_provider.dart';
import 'features/customer/providers/provider_directory_provider.dart';
import 'features/customer/providers/quote_provider.dart';
import 'features/customer/providers/request_provider.dart';
import 'features/disputes/providers/dispute_provider.dart';
import 'features/messages/providers/message_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/payments/providers/payment_provider.dart';
import 'features/reviews/providers/review_provider.dart';
import 'features/wallet/providers/connects_provider.dart';
import 'features/wallet/providers/provider_wallet_provider.dart';
import 'features/wallet/providers/wallet_provider.dart';
import 'features/wallet/providers/withdrawal_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create a single SseProvider that owns all SSE streams.
  final sseProvider = SseProvider();
  final localNotifications = LocalNotificationService();
  await localNotifications.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => RequestApi()),

        Provider(create: (_) => BookingApi()),

        Provider(create: (_) => ConnectsApi()),

        Provider(create: (_) => DisputeApi()),

        Provider(create: (_) => QuoteApi()),

        Provider(create: (_) => ReviewApi()),

        Provider(create: (_) => MessageApi()),

        Provider(create: (_) => NotificationApi()),

        Provider(create: (_) => PaymentApi()),

        Provider(create: (_) => ProviderWalletApi()),

        Provider(create: (_) => WalletApi()),

        Provider(create: (_) => WithdrawalApi()),

        Provider(create: (_) => CustomerRepository()),

        Provider(create: (_) => ProviderRepository()),

        Provider(
          create: (context) => RequestRepository(context.read<RequestApi>()),
        ),

        Provider(
          create: (context) => BookingRepository(context.read<BookingApi>()),
        ),

        Provider(
          create: (context) => ConnectsRepository(context.read<ConnectsApi>()),
        ),

        Provider(
          create: (context) => DisputeRepository(context.read<DisputeApi>()),
        ),

        Provider(
          create: (context) => QuoteRepository(context.read<QuoteApi>()),
        ),

        Provider(
          create: (context) => ReviewRepository(context.read<ReviewApi>()),
        ),

        Provider(
          create: (context) => MessageRepository(context.read<MessageApi>()),
        ),

        Provider(
          create: (context) =>
              NotificationRepository(context.read<NotificationApi>()),
        ),

        Provider(
          create: (context) => PaymentRepository(context.read<PaymentApi>()),
        ),

        Provider(
          create: (context) =>
              ProviderWalletRepository(context.read<ProviderWalletApi>()),
        ),

        Provider(
          create: (context) => WalletRepository(context.read<WalletApi>()),
        ),

        Provider(
          create: (context) =>
              WithdrawalRepository(context.read<WithdrawalApi>()),
        ),

        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProvider(
          create: (_) => PasswordResetProvider(
            repository: PasswordResetRepository(
              api: AuthApi(
                Dio(
                  BaseOptions(
                    baseUrl: ApiConstants.baseUrl,
                    connectTimeout: const Duration(seconds: 15),
                    receiveTimeout: const Duration(seconds: 15),
                    headers: const {'Accept': 'application/json'},
                  ),
                ),
              ),
            ),
          ),
        ),

        // SSE provider — owns all SSE stream connections.
        ChangeNotifierProvider<SseProvider>.value(value: sseProvider),

        // SSE initializer — syncs SSE connections with auth state.
        ProxyProvider<AuthProvider, SseInitializerService>(
          create: (_) => sseProvider.initializer,

          update: (_, authProvider, initializer) {
            final service = initializer ?? sseProvider.initializer;

            service.syncAuthentication(authProvider.currentUser != null);

            return service;
          },
        ),

        ChangeNotifierProxyProvider<RequestRepository, RequestProvider>(
          create: (context) =>
              RequestProvider(repository: context.read<RequestRepository>()),

          update: (context, repository, previous) {
            return previous ?? RequestProvider(repository: repository);
          },
        ),

        ChangeNotifierProxyProvider<
          ProviderRepository,

          ProviderDirectoryProvider
        >(
          create: (context) => ProviderDirectoryProvider(
            repository: context.read<ProviderRepository>(),
          ),

          update: (context, repository, previous) {
            return previous ??
                ProviderDirectoryProvider(repository: repository);
          },
        ),

        ChangeNotifierProxyProvider<
          CustomerRepository,

          CustomerDirectoryProvider
        >(
          create: (context) => CustomerDirectoryProvider(
            repository: context.read<CustomerRepository>(),
          ),

          update: (context, repository, previous) {
            return previous ??
                CustomerDirectoryProvider(repository: repository);
          },
        ),

        ChangeNotifierProxyProvider<MessageRepository, MessageProvider>(
          create: (context) {
            final provider = MessageProvider(
              repository: context.read<MessageRepository>(),
            );
            provider.attachSse(sseProvider.messageSse);
            return provider;
          },

          update: (context, repository, previous) {
            return previous ?? MessageProvider(repository: repository);
          },
        ),

        Provider<LocalNotificationService>.value(value: localNotifications),

        ChangeNotifierProxyProvider2<
          NotificationRepository,
          LocalNotificationService,
          NotificationProvider
        >(
          create: (context) {
            final provider = NotificationProvider(
              repository: context.read<NotificationRepository>(),
              localNotifications: context.read<LocalNotificationService>(),
            );
            provider.attachSse(sseProvider.notificationSse);
            return provider;
          },

          update: (context, repository, localService, previous) {
            return previous ??
                NotificationProvider(
                  repository: repository,
                  localNotifications: localService,
                );
          },
        ),

        ChangeNotifierProxyProvider<PaymentRepository, PaymentProvider>(
          create: (context) =>
              PaymentProvider(repository: context.read<PaymentRepository>()),

          update: (context, repository, previous) {
            return previous ?? PaymentProvider(repository: repository);
          },
        ),

        ChangeNotifierProxyProvider<ReviewRepository, ReviewProvider>(
          create: (context) =>
              ReviewProvider(repository: context.read<ReviewRepository>()),

          update: (context, repository, previous) {
            return previous ?? ReviewProvider(repository: repository);
          },
        ),

        ChangeNotifierProxyProvider<WalletRepository, WalletProvider>(
          create: (context) =>
              WalletProvider(repository: context.read<WalletRepository>()),

          update: (context, repository, previous) {
            return previous ?? WalletProvider(repository: repository);
          },
        ),

        ChangeNotifierProxyProvider<WithdrawalRepository, WithdrawalProvider>(
          create: (context) => WithdrawalProvider(
            repository: context.read<WithdrawalRepository>(),
          ),

          update: (context, repository, previous) {
            return previous ?? WithdrawalProvider(repository: repository);
          },
        ),

        ChangeNotifierProxyProvider<
          ProviderWalletRepository,

          ProviderWalletProvider
        >(
          create: (context) => ProviderWalletProvider(
            repository: context.read<ProviderWalletRepository>(),
          ),

          update: (context, repository, previous) {
            return previous ?? ProviderWalletProvider(repository: repository);
          },
        ),

        ChangeNotifierProxyProvider<BookingRepository, BookingProvider>(
          create: (context) =>
              BookingProvider(repository: context.read<BookingRepository>()),

          update: (context, repository, previous) {
            return previous ?? BookingProvider(repository: repository);
          },
        ),

        ChangeNotifierProxyProvider<ConnectsRepository, ConnectsProvider>(
          create: (context) =>
              ConnectsProvider(repository: context.read<ConnectsRepository>()),

          update: (context, repository, previous) {
            return previous ?? ConnectsProvider(repository: repository);
          },
        ),

        ChangeNotifierProxyProvider<DisputeRepository, DisputeProvider>(
          create: (context) =>
              DisputeProvider(repository: context.read<DisputeRepository>()),

          update: (context, repository, previous) {
            return previous ?? DisputeProvider(repository: repository);
          },
        ),

        ChangeNotifierProxyProvider<QuoteRepository, QuoteProvider>(
          create: (context) =>
              QuoteProvider(repository: context.read<QuoteRepository>()),

          update: (context, repository, previous) {
            return previous ?? QuoteProvider(repository: repository);
          },
        ),

        // Location sharing provider — wired to the location SSE stream.
        ChangeNotifierProvider<LocationShareProvider>(
          create: (_) {
            final provider = LocationShareProvider();
            provider.attachSse(sseProvider.locationShareSse);
            return provider;
          },
        ),
      ],

      child: const MyApp(),
    ),
  );
}
