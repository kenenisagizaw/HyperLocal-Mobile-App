import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../data/models/quote_model.dart';
import '../../providers/quote_provider.dart';


class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AvailableJobsPage(),
    const MyQuotesPage(),
    const MessagesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Quotes'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class AvailableJobsPage extends StatelessWidget {
  const AvailableJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = Provider.of<RequestProvider>(context).requests;
    final quoteProvider = Provider.of<QuoteProvider>(context);

    if (requests.isEmpty) {
      return const Center(child: Text('No available jobs'));
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text('${req.category} - ${req.location}'),
            subtitle: Text(req.description),
            trailing: ElevatedButton(
              child: const Text('Quote'),
              onPressed: () {
                quoteProvider.addQuote(
                  Quote(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    requestId: req.id,
                    providerName: 'You',
                    price: 1500,
                    notes: 'I can do it',
                  ),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quote submitted')),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class MyQuotesPage extends StatelessWidget {
  const MyQuotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final quotes = Provider.of<QuoteProvider>(context).quotes;

    if (quotes.isEmpty) {
      return const Center(child: Text('No quotes yet'));
    }

    return ListView.builder(
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final q = quotes[index];

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text('${q.providerName} - \$${q.price}'),
            subtitle: Text(q.notes),
          ),
        );
      },
    );
  }
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Messages'));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Center(
      child: Text(
        'Profile\n${user?.name ?? 'Guest'}\n${user?.email ?? ''}',
        textAlign: TextAlign.center,
      ),
    );
  }
}