import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// Enhanced data models with better structure and validation
class Transaction {
  final String id; // Added unique identifier
  final double amount;
  final String description;
  final String type;
  final String category;
  final DateTime date;
  final String currency; // Added currency tracking per transaction

  Transaction({
    required this.amount,
    required this.description,
    required this.type,
    required this.category,
    required this.date,
    required this.currency,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString();

  // Added method to convert transaction to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
      'currency': currency,
    };
  }
}

class RecurringTransaction {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String category;
  final DateTime nextDueDate;
  final String frequency; // Added frequency (daily, weekly, monthly, yearly)
  final bool isActive; // Added status tracking

  RecurringTransaction({
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.nextDueDate,
    required this.frequency,
    this.isActive = true,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString();
}

class Budget {
  final String id;
  final String category;
  final double limit;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  double spent = 0.0; // Track actual spending

  Budget({
    required this.category,
    required this.limit,
    required this.currency,
    required this.startDate,
    required this.endDate,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString();
}

class Debt {
  final String id;
  final String lender;
  final double amount;
  final DateTime dueDate;
  final double interestRate; // Added interest rate
  final String currency;
  bool isPaid; // Track payment status

  Debt({
    required this.lender,
    required this.amount,
    required this.dueDate,
    required this.currency,
    this.interestRate = 0.0,
    this.isPaid = false,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString();
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true, // Using Material 3 design
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Transaction> _transactions = [];
  final List<RecurringTransaction> _recurringTransactions = [];
  final List<Budget> _budgets = [];
  final List<Debt> _debts = [];
  
  // Financial tracking
  final Map<String, double> _categoryTotals = {};
  final Map<String, double> _monthlyTotals = {};
  
  // Settings
  String selectedCurrency = 'USD';
  final Map<String, double> _exchangeRates = {
    'USD': 1.0,
    'EUR': 0.85,
    'KGS': 89.5,
  };

  // Predefined categories
  final List<String> _categories = [
    'Food',
    'Transport',
    'Housing',
    'Entertainment',
    'Healthcare',
    'Education',
    'Shopping',
    'Utilities',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _buildMainBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMainBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    double totalIncome = _calculateTotalIncome();
    double totalExpense = _calculateTotalExpense();
    double balance = totalIncome - totalExpense;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance: ${_formatAmount(balance)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Income: ${_formatAmount(totalIncome)}'),
            Text('Expenses: ${_formatAmount(totalExpense)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _buildActionButton(
          icon: Icons.add_chart,
          label: 'Add Transaction',
          onPressed: () => _openAddTransactionDialog(context),
        ),
        _buildActionButton(
          icon: Icons.repeat,
          label: 'Recurring',
          onPressed: _viewRecurringTransactions,
        ),
        _buildActionButton(
          icon: Icons.account_balance_wallet,
          label: 'Budget',
          onPressed: _viewBudget,
        ),
        _buildActionButton(
          icon: Icons.money_off,
          label: 'Debts',
          onPressed: _viewDebts,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    if (_transactions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No transactions yet'),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length.clamp(0, 5),
            itemBuilder: (context, index) {
              final transaction = _transactions[index];
              return ListTile(
                leading: Icon(
                  transaction.type == 'income' ? Icons.add_circle : Icons.remove_circle,
                  color: transaction.type == 'income' ? Colors.green : Colors.red,
                ),
                title: Text(transaction.description),
                subtitle: Text(transaction.category),
                trailing: Text(
                  _formatAmount(transaction.amount),
                  style: TextStyle(
                    color: transaction.type == 'income' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _showTransactionDetails(transaction),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(symbol: selectedCurrency);
    return formatter.format(amount);
  }

  double _calculateTotalIncome() {
    return _transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + _convertAmount(t.amount, t.currency));
  }

  double _calculateTotalExpense() {
    return _transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + _convertAmount(t.amount, t.currency));
  }

  double _convertAmount(double amount, String fromCurrency) {
    if (fromCurrency == selectedCurrency) return amount;
    return amount * (_exchangeRates[selectedCurrency]! / _exchangeRates[fromCurrency]!);
  }
void _viewRecurringTransactions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recurring Transactions'),
          content: _recurringTransactions.isEmpty
              ? const Text('No recurring transactions')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _recurringTransactions.map((transaction) {
                      return ListTile(
                        title: Text(transaction.description),
                        subtitle: Text('${transaction.amount} - ${transaction.frequency}'),
                        trailing: Text(
                          DateFormat('dd/MM/yyyy').format(transaction.nextDueDate),
                        ),
                      );
                    }).toList(),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: _addRecurringTransaction,
              child: const Text('Add New'),
            ),
          ],
        );
      },
    );
  }

  void _viewBudget() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Budget Overview'),
          content: _budgets.isEmpty
              ? const Text('No budgets set')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _budgets.map((budget) {
                      final percentage = (budget.spent / budget.limit * 100).clamp(0, 100);
                      return Column(
                        children: [
                          ListTile(
                            title: Text(budget.category),
                            subtitle: Text(
                              'Spent: ${_formatAmount(budget.spent)} / ${_formatAmount(budget.limit)}',
                            ),
                          ),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(
                              percentage > 90 ? Colors.red : Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: _addBudget,
              child: const Text('Add Budget'),
            ),
          ],
        );
      },
    );
  }

  void _viewDebts() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Debts'),
          content: _debts.isEmpty
              ? const Text('No debts')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _debts.map((debt) {
                      return ListTile(
                        title: Text(debt.lender),
                        subtitle: Text(
                          'Due: ${DateFormat('dd/MM/yyyy').format(debt.dueDate)}',
                        ),
                        trailing: Text(_formatAmount(debt.amount)),
                        leading: Icon(
                          debt.isPaid ? Icons.check_circle : Icons.warning,
                          color: debt.isPaid ? Colors.green : Colors.red,
                        ),
                      );
                    }).toList(),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: _addDebt,
              child: const Text('Add Debt'),
            ),
          ],
        );
      },
    );
  }

  void _addRecurringTransaction() {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String type = 'expense';
    String category = _categories.first;
    String frequency = 'monthly';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Recurring Transaction'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Enter valid number';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: frequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: ['daily', 'weekly', 'monthly', 'yearly']
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (value) => frequency = value!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    _recurringTransactions.add(
                      RecurringTransaction(
                        type: type,
                        amount: double.parse(amountController.text),
                        description: descriptionController.text,
                        category: category,
                        nextDueDate: DateTime.now().add(const Duration(days: 30)),
                        frequency: frequency,
                      ),
                    );
                  });
                  Navigator.pop(context);
                  _showSuccessSnackBar('Recurring transaction added');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _addBudget() {
    final formKey = GlobalKey<FormState>();
    final limitController = TextEditingController();
    String category = _categories.first;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Budget'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => category = value!,
                ),
                TextFormField(
                  controller: limitController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monthly Limit'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (double.tryParse(value) == null) return 'Enter valid number';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final now = DateTime.now();
                  setState(() {
                    _budgets.add(Budget(
                      category: category,
                      limit: double.parse(limitController.text),
                      currency: selectedCurrency,
                      startDate: DateTime(now.year, now.month, 1),
                      endDate: DateTime(now.year, now.month + 1, 0),
                    ));
                  });
                  Navigator.pop(context);
                  _showSuccessSnackBar('Budget added');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _addDebt() {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final lenderController = TextEditingController();
    final dueDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Debt'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: lenderController,
                  decoration: const InputDecoration(labelText: 'Lender Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (double.tryParse(value) == null) return 'Enter valid number';
                    return null;
                  },
                ),
                TextFormField(
                  controller: dueDateController,
                  decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    try {
                      DateTime.parse(value);
                      return null;
                    } catch (e) {
                      return 'Enter valid date';
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    _debts.add(Debt(
                      lender: lenderController.text,
                      amount: double.parse(amountController.text),
                      dueDate: DateTime.parse(dueDateController.text),
                      currency: selectedCurrency,
                    ));
                  });
                  Navigator.pop(context);
                  _showSuccessSnackBar('Debt added');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
  // UI Dialog methods
  void _openAddTransactionDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String type = 'expense';
    String category = _categories.first;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Transaction'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'expense', child: Text('Expense')),
                      DropdownMenuItem(value: 'income', child: Text('Income')),
                    ],
                    onChanged: (value) => type = value!,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.folder),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) => category = value!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final transaction = Transaction(
                    amount: double.parse(amountController.text),
                    description: descriptionController.text,
                    type: type,
                    category: category,
                    date: DateTime.now(),
                    currency: selectedCurrency,
                  );

                  setState(() {
                    _transactions.add(transaction);
                    _updateStatistics(transaction);
                  });

                  logger.i('Saved transaction: ${transaction.toMap()}');
                  Navigator.pop(context);
                  _showSuccessSnackBar('Transaction saved successfully');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _updateStatistics(Transaction transaction) {
    final amount = _convertAmount(transaction.amount, transaction.currency);
    
    // Update category totals
    _categoryTotals[transaction.category] =
        (_categoryTotals[transaction.category] ?? 0.0) +
            (transaction.type == 'expense' ? amount : -amount);
    
    // Update monthly totals
    final monthKey = DateFormat('yyyy-MM').format(transaction.date);
    _monthlyTotals[monthKey] = (_monthlyTotals[monthKey] ?? 0.0) +
        (transaction.type == 'expense' ? amount : -amount);
    
    // Update budget tracking
    if (transaction.type == 'expense') {
      final relevantBudget = _budgets.firstWhere(
        (b) => b.category == transaction.category &&
            transaction.date.isAfter(b.startDate) &&
            transaction.date.isBefore(b.endDate),
        orElse: () => null as Budget,
      );
      
      if (relevantBudget != null) {
        relevantBudget.spent += amount;
        if (relevantBudget.spent > relevantBudget.limit) {
          _showBudgetAlert(relevantBudget);
        }
      }
    }
  }

  void _showBudgetAlert(Budget budget) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Budget Alert'),
          content: Text(
            'You have exceeded the budget for ${budget.category}.\n'
            'Budget: ${_formatAmount(budget.limit)}\n'
            'Spent: ${_formatAmount(budget.spent)}'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Transaction Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Amount', _formatAmount(transaction.amount)),
              _detailRow('Type', transaction.type),
              _detailRow('Category', transaction.category),
              _detailRow('Date', DateFormat('yyyy-MM-dd HH:mm').format(transaction.date)),
              _detailRow('Description', transaction.description),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () => _deleteTransaction(transaction),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _deleteTransaction(Transaction transaction) {
    setState(() {
      _transactions.remove(transaction);
      // Recalculate statistics
      _categoryTotals.clear();
      _monthlyTotals.clear();
      for (var t in _transactions) {
        _updateStatistics(t);
      }
    });
    Navigator.pop(context);
    _showSuccessSnackBar('Transaction deleted');
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Currency'),
                subtitle: Text(selectedCurrency),
                onTap: _changeCurrency,
              ),
              ListTile(
                title: const Text('Categories'),
                subtitle: const Text('Manage categories'),
                onTap: _manageCategories,
              ),
              ListTile(
                title: const Text('Export Data'),
                subtitle: const Text('Export transactions to CSV'),
                onTap: _exportData,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _changeCurrency() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _exchangeRates.keys.map((currency) {
              return RadioListTile<String>(
                title: Text(currency),
                value: currency,
                groupValue: selectedCurrency,
                onChanged: (value) {
                  setState(() {
                    selectedCurrency = value!;
                    // Recalculate statistics with new currency
                    _categoryTotals.clear();
                    _monthlyTotals.clear();
                    for (var transaction in _transactions) {
                      _updateStatistics(transaction);
                    }
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _manageCategories() {
    final newCategoryController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Manage Categories'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._categories.map((category) {
                  return ListTile(
                    title: Text(category),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        if (!_transactions.any((t) => t.category == category)) {
                          setState(() {
                            _categories.remove(category);
                          });
                          Navigator.pop(context);
                          _manageCategories();
                        } else {
                          _showErrorSnackBar('Category is in use');
                        }
                      },
                    ),
                  );
                }),
                const Divider(),
                TextField(
                  controller: newCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'New Category',
                    suffixIcon: Icon(Icons.add),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty && !_categories.contains(value)) {
                      setState(() {
                        _categories.add(value);
                      });
                      newCategoryController.clear();
                      Navigator.pop(context);
                      _manageCategories();
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _exportData() {
    // Here you would implement the data export functionality
    // For example, converting transactions to CSV format
    final csv = _transactions.map((t) => [
      t.date.toIso8601String(),
      t.amount.toString(),
      t.currency,
      t.type,
      t.category,
      t.description,
    ].join(',')).join('\n');
    
    // In a real app, you would use a file picker and save the file
    logger.i('Exported data: $csv');
    _showSuccessSnackBar('Data exported successfully');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
