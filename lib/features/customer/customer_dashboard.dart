import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/quote_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/request_provider.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const RequestsPage(),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Pages

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Customer Home'));
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Messages'));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    return Center(
      child: Text('Profile\n${user?.name ?? 'Guest'}\n${user?.email ?? ''}'),
    );
  }
}

// ----------------- FULL FEATURE RequestsPage -----------------
class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = Provider.of<RequestProvider>(context).requests;
    final quoteProvider = Provider.of<QuoteProvider>(context);

    if (requests.isEmpty) {
      return const Center(child: Text('No requests yet'));
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        // now strongly typed
        final List<Quote> quotes = quoteProvider.getQuotesForRequest(req.id);

        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text('${req.category} - ${req.location}'),
            subtitle: Text('Status: ${req.status}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(req.description),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Quotes:', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...quotes.map((q) => ListTile(
                    title: Text('${q.providerName} - \$${q.price.toStringAsFixed(2)}'),
                    subtitle: Text(q.notes),
                    trailing: req.status == 'pending'
                        ? ElevatedButton(
                            child: const Text('Accept'),
                            onPressed: () {
                              Provider.of<RequestProvider>(context, listen: false)
                                  .updateStatus(req.id, 'booked');
                            },
                          )
                        : null,
                  )),
            ],
          ),
        );
      },
    );
  }
}