import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/datasources/remote/request_api.dart';
import 'data/repositories/request_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/quote_provider.dart';
import 'providers/request_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => RequestApi()),
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
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
