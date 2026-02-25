import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/datasources/remote/request_api.dart';
import 'data/repositories/customer_repository.dart';
import 'data/repositories/provider_repository.dart';
import 'data/repositories/request_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/customer/providers/customer_directory_provider.dart';
import 'features/customer/providers/provider_directory_provider.dart';
import 'features/customer/providers/quote_provider.dart';
import 'features/customer/providers/request_provider.dart';
import 'features/messages/providers/message_provider.dart';
import 'features/payments/providers/payment_provider.dart';
import 'features/reviews/providers/review_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => RequestApi()),
        Provider(create: (_) => CustomerRepository()),
        Provider(create: (_) => ProviderRepository()),
        Provider(
          create: (context) => RequestRepository(context.read<RequestApi>()),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<RequestRepository, RequestProvider>(
          create: (context) =>
              RequestProvider(repository: context.read<RequestRepository>()),
          update: (context, repository, previous) {
            return previous ?? RequestProvider(repository: repository);
          },
        ),
        ChangeNotifierProxyProvider<ProviderRepository,
            ProviderDirectoryProvider>(
          create: (context) => ProviderDirectoryProvider(
            repository: context.read<ProviderRepository>(),
          ),
          update: (context, repository, previous) {
            return previous ?? ProviderDirectoryProvider(repository: repository);
          },
        ),
        ChangeNotifierProxyProvider<CustomerRepository,
            CustomerDirectoryProvider>(
          create: (context) => CustomerDirectoryProvider(
            repository: context.read<CustomerRepository>(),
          ),
          update: (context, repository, previous) {
            return previous ?? CustomerDirectoryProvider(repository: repository);
          },
        ),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
