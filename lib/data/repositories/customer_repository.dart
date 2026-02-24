import '../models/user_model.dart';

class CustomerRepository {
  final List<UserModel> _customers = [
    UserModel(
      id: 'customer-1',
      role: UserRole.customer,
      name: 'Michael Abate',
      phone: '0922 445 566',
      email: 'michael@example.com',
      address: 'CMC, Addis Ababa',
      latitude: 9.0150,
      longitude: 38.8245,
    ),
    UserModel(
      id: 'customer-2',
      role: UserRole.customer,
      name: 'Sara Tadesse',
      phone: '0933 778 899',
      email: 'sara@example.com',
      address: 'Kazanchis, Addis Ababa',
      latitude: 9.0091,
      longitude: 38.7614,
    ),
  ];

  Future<List<UserModel>> fetchCustomers() async {
    return _customers;
  }

  UserModel? getCustomerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void upsertCustomer(UserModel customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index == -1) {
      _customers.add(customer);
    } else {
      _customers[index] = customer;
    }
  }
}
