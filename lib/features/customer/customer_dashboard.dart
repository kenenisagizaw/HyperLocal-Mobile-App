import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/quote_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/request_provider.dart';
import '../../core/constants/enums.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    RequestsPage(),
    MessagesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.blueGrey,
            selectedFontSize: 14,
            unselectedFontSize: 12,
            selectedIconTheme: const IconThemeData(size: 28),
            unselectedIconTheme: const IconThemeData(size: 22),
            elevation: 10,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Requests'),
              BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
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
      child: Text(
        'Profile\n${user?.name ?? 'Guest'}\n${user?.email ?? ''}',
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ----------------- FULL FEATURE RequestsPage -----------------
class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.quoted:
        return Colors.purple;
      case RequestStatus.booked:
        return Colors.blue;
      case RequestStatus.inProgress:
        return Colors.teal;
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(RequestStatus status) {
    return status
        .toString()
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim();
  }

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
        final List<Quote> quotes = quoteProvider.getQuotesForRequest(req.id);
        final bool canAccept = req.status == RequestStatus.pending;

        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${req.category} - ${req.location}'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(req.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(req.status),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(req.description),
            ),
            children: [
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Quotes:', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...quotes.map(
                (q) => ListTile(
                  title: Text('${q.providerName} - \$${q.price.toStringAsFixed(2)}'),
                  subtitle: Text(q.notes),
                  trailing: canAccept
                      ? ElevatedButton(
                          child: const Text('Accept'),
                          onPressed: () {
                            // Update request status
                            Provider.of<RequestProvider>(context, listen: false)
                                .updateStatus(req.id, RequestStatus.booked);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Request accepted!')),
                            );
                          },
                        )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}