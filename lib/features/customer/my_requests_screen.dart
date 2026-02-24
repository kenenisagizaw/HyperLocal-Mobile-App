import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import 'request_details_screen.dart';

class MyRequestsScreen extends StatefulWidget {
	const MyRequestsScreen({super.key});

	@override
	State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
	@override
	void initState() {
		super.initState();
		Future.microtask(
			() => context.read<RequestProvider>().loadRequests(),
		);
	}

	Color _getStatusColor(RequestStatus status) {
		switch (status) {
			case RequestStatus.pending:
				return Colors.orange;
			case RequestStatus.quoted:
				return Colors.purple;
			case RequestStatus.accepted:
				return Colors.blue;
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
		final auth = context.watch<AuthProvider>();
		final requestProvider = context.watch<RequestProvider>();

		final currentUser = auth.currentUser;
		if (currentUser == null) {
			return const Scaffold(
				body: Center(child: Text('No user logged in')),
			);
		}

		final myRequests =
				requestProvider.getCustomerRequests(currentUser.id);

		return Scaffold(
			appBar: AppBar(title: const Text('My Requests')),
			body: requestProvider.isLoading
					? const Center(child: CircularProgressIndicator())
					: myRequests.isEmpty
							? const Center(
									child: Text(
										'You have not created any requests yet.',
										style: TextStyle(fontSize: 16),
									),
								)
							: ListView.builder(
									padding: const EdgeInsets.all(16),
									itemCount: myRequests.length,
									itemBuilder: (context, index) {
										final request = myRequests[index];

										return Card(
											elevation: 3,
											margin: const EdgeInsets.only(bottom: 16),
											shape: RoundedRectangleBorder(
												borderRadius: BorderRadius.circular(12),
											),
											child: ListTile(
												contentPadding: const EdgeInsets.all(16),
												title: Text(
													request.category,
													style: const TextStyle(
														fontWeight: FontWeight.bold,
														fontSize: 16,
													),
												),
												subtitle: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														const SizedBox(height: 6),
														Text('Description: ${request.description}'),
														Text('Location: ${request.location}'),
														Text('Budget: ${request.budget} ETB'),
														const SizedBox(height: 6),
														Container(
															padding: const EdgeInsets.symmetric(
																horizontal: 8,
																vertical: 4,
															),
															decoration: BoxDecoration(
																color: _getStatusColor(request.status)
																		.withOpacity(0.2),
																borderRadius: BorderRadius.circular(8),
															),
															child: Text(
																_getStatusText(request.status),
																style: TextStyle(
																	color: _getStatusColor(request.status),
																	fontWeight: FontWeight.bold,
																),
															),
														),
													],
												),
												onTap: () {
													Navigator.push(
														context,
														MaterialPageRoute(
															builder: (_) => RequestDetailsScreen(
																request: request,
															),
														),
													);
												},
											),
										);
									},
								),
		);
	}
}