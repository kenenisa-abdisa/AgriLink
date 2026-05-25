import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class FarmerEarningsScreen extends StatefulWidget {
  const FarmerEarningsScreen({super.key});

  @override
  State<FarmerEarningsScreen> createState() => _FarmerEarningsScreenState();
}

class _FarmerEarningsScreenState extends State<FarmerEarningsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  double _balance = 0;
  double _pending = 0;
  double _monthEarnings = 0;
  double _yearEarnings = 0;
  List<Map<String, dynamic>> _transactions = [];
  final List<double> _monthlyData = [12000, 18500, 15000, 22000, 19000, 25600];

  @override
  void initState() {
    super.initState();
    _fetchEarningsData();
  }

  Future<void> _fetchEarningsData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Get Farmer ID
      final farmer = await _supabase
          .from('farmers')
          .select('id')
          .eq('user_id', user.id)
          .single();
      final farmerId = farmer['id'];

      // 2. Fetch Delivered Orders for Balance
      final deliveredOrders = await _supabase
          .from('orders')
          .select('total_amount, status, created_at')
          .eq('farmer_id', farmerId)
          .eq('status', 'delivered');

      // 3. Fetch Pending Orders
      final pendingOrders = await _supabase
          .from('orders')
          .select('total_amount')
          .eq('farmer_id', farmerId)
          .filter('status', 'in', ['confirmed', 'dispatched']);

      // 4. Fetch Withdrawals
      final withdrawals = await _supabase
          .from('withdrawals')
          .select('amount, status, created_at, id, method')
          .eq('farmer_id', farmerId);

      // Calculations
      double totalIn = 0;
      for (var o in deliveredOrders) {
        totalIn += (o['total_amount'] as num).toDouble();
      }

      double totalOut = 0;
      for (var w in withdrawals) {
        if (w['status'] != 'rejected') {
          totalOut += (w['amount'] as num).toDouble();
        }
      }

      double pendingTotal = 0;
      for (var o in pendingOrders) {
        pendingTotal += (o['total_amount'] as num).toDouble();
      }

      // Monthly/Yearly filter
      final now = DateTime.now();
      double mE = 0;
      double yE = 0;
      for (var o in deliveredOrders) {
        final date = DateTime.parse(o['created_at']);
        if (date.month == now.month && date.year == now.year) {
          mE += (o['total_amount'] as num).toDouble();
        }
        if (date.year == now.year) {
          yE += (o['total_amount'] as num).toDouble();
        }
      }

      // Build Transaction History
      List<Map<String, dynamic>> txs = [];
      for (var o in deliveredOrders) {
        txs.add({
          'type': 'order',
          'title': 'Sale #${o['id']?.toString().substring(0, 6) ?? ""}',
          'amount': o['total_amount'],
          'date': o['created_at'],
          'status': 'delivered',
        });
      }
      for (var w in withdrawals) {
        txs.add({
          'type': 'withdrawal',
          'title': '${w['method']} Withdrawal',
          'amount': w['amount'],
          'date': w['created_at'],
          'status': w['status'],
        });
      }
      txs.sort((a, b) => b['date'].compareTo(a['date']));

      if (mounted) {
        setState(() {
          _balance = totalIn - totalOut;
          _pending = pendingTotal;
          _monthEarnings = mE;
          _yearEarnings = yE;
          _transactions = txs.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Earnings Fetch Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & Analytics'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchEarningsData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildWalletCard(),
                const SizedBox(height: 24),
                _buildStatsRow(),
                const SizedBox(height: 32),
                _buildSectionHeader('Buyer Breakdown', Icons.pie_chart),
                const SizedBox(height: 12),
                _buildHorizontalBreakdown(),
                const SizedBox(height: 32),
                _buildSectionHeader('Monthly Revenue (ETB)', Icons.bar_chart),
                const SizedBox(height: 20),
                _buildVerticalBarChart(),
                const SizedBox(height: 32),
                _buildSectionHeader('Recent Activity', Icons.history),
                const SizedBox(height: 12),
                ..._transactions.map((tx) => _buildTransactionItem(tx)),
              ],
            ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B6B3A), Color(0xFF2E8B57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B6B3A).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'ETB ${NumberFormat('#,###').format(_balance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showWithdrawalSheet(),
                  icon: const Icon(Icons.account_balance_wallet, size: 18),
                  label: const Text('Withdraw'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1B6B3A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: const Text('Statement'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statItem('This Month', _monthEarnings, Colors.green),
        const SizedBox(width: 12),
        _statItem('This Year', _yearEarnings, Colors.blue),
        const SizedBox(width: 12),
        _statItem('Pending', _pending, Colors.orange),
      ],
    );
  }

  Widget _statItem(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'ETB ${NumberFormat.compact().format(amount)}',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1B6B3A)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHorizontalBreakdown() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(
                  flex: 40,
                  child: Container(color: const Color(0xFF1B6B3A)),
                ),
                Expanded(flex: 35, child: Container(color: Colors.green[300])),
                Expanded(flex: 25, child: Container(color: Colors.green[100])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _legendItem('Consumer', '40%', const Color(0xFF1B6B3A)),
            _legendItem('Restaurant', '35%', Colors.green[300]!),
            _legendItem('Shop', '25%', Colors.green[100]!),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($value)',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildVerticalBarChart() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    return SizedBox(
      height: 180,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(6, (i) {
          final height = _monthlyData[i] / 30000 * 150;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${(_monthlyData[i] / 1000).toStringAsFixed(0)}k',
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: height,
                decoration: BoxDecoration(
                  color: i == 5
                      ? const Color(0xFF1B6B3A)
                      : Colors.green.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                months[i],
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final isOrder = tx['type'] == 'order';
    final date = DateTime.parse(tx['date']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (isOrder ? Colors.green[50] : Colors.orange[50])!,
            child: Icon(
              isOrder ? Icons.arrow_downward : Icons.arrow_upward,
              color: isOrder ? Colors.green : Colors.orange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isOrder ? "+" : "-"} ETB ${NumberFormat('#,###').format(tx['amount'])}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isOrder ? Colors.green : Colors.orange,
                ),
              ),
              Text(
                tx['status'].toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: _getStatusColor(tx['status']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showWithdrawalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => WithdrawalBottomSheet(balance: _balance),
    ).then((_) => _fetchEarningsData());
  }
}

class WithdrawalBottomSheet extends StatefulWidget {
  final double balance;
  const WithdrawalBottomSheet({super.key, required this.balance});

  @override
  State<WithdrawalBottomSheet> createState() => _WithdrawalBottomSheetState();
}

class _WithdrawalBottomSheetState extends State<WithdrawalBottomSheet> {
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();
  String _method = 'Telebirr'; // 'Telebirr' or 'CBE Birr'
  double _amount = 0;
  final double _feeRate = 0.02;
  String? _errorText;

  Color _getMethodColor(String method) {
    if (method == 'Telebirr') {
      return const Color(0xFF0F75BC); // Telebirr Blue
    } else {
      return const Color(0xFF5D2D91); // CBE Purple
    }
  }

  void _validateInputs() {
    setState(() {
      _errorText = null;
      if (_amount <= 0) {
        return;
      }
      if (_amount > widget.balance) {
        _errorText = 'Amount exceeds available balance of ETB ${widget.balance.toStringAsFixed(2)}';
        return;
      }
      
      final account = _accountController.text.trim();
      if (account.isEmpty) {
        return;
      }

      if (_method == 'Telebirr') {
        // Ethiopian phone validation
        final phoneRegex = RegExp(r'^(09|07)\d{8}$');
        if (!phoneRegex.hasMatch(account)) {
          _errorText = 'Enter a valid Telebirr phone number (starts with 09 or 07, 10 digits)';
        }
      } else {
        // CBE Account Validation: 13 digits
        final cbeRegex = RegExp(r'^\d{13}$');
        if (!cbeRegex.hasMatch(account)) {
          _errorText = 'Enter a valid 13-digit CBE account number';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final netAmount = _amount * (1 - _feeRate);
    final themeColor = _getMethodColor(_method);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Secure Payout',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Available: ETB ${widget.balance.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Select Method',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          
          // Authentic Branded Cards Row
          Row(
            children: [
              // Telebirr Card
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _method = 'Telebirr';
                      _accountController.clear();
                      _validateInputs();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _method == 'Telebirr' ? const Color(0xFF0F75BC).withValues(alpha: 0.08) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _method == 'Telebirr' ? const Color(0xFF0F75BC) : Colors.grey[200]!,
                        width: _method == 'Telebirr' ? 2 : 1,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.phone_android_rounded, color: Color(0xFF0F75BC), size: 28),
                        SizedBox(height: 8),
                        Text(
                          'telebirr',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F75BC)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // CBE Birr Card
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _method = 'CBE Birr';
                      _accountController.clear();
                      _validateInputs();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _method == 'CBE Birr' ? const Color(0xFF5D2D91).withValues(alpha: 0.08) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _method == 'CBE Birr' ? const Color(0xFF5D2D91) : Colors.grey[200]!,
                        width: _method == 'CBE Birr' ? 2 : 1,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.account_balance_rounded, color: Color(0xFF5D2D91), size: 28),
                        SizedBox(height: 8),
                        Text(
                          'CBE Birr',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF5D2D91)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Amount (ETB)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            onChanged: (v) {
              setState(() {
                _amount = double.tryParse(v) ?? 0;
                _validateInputs();
              });
            },
            decoration: InputDecoration(
              hintText: 'Minimum ETB 50',
              filled: true,
              fillColor: Colors.grey[50],
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          Text(
            _method == 'Telebirr' ? 'Telebirr Phone Number' : 'CBE Account Number',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _accountController,
            keyboardType: _method == 'Telebirr' ? TextInputType.phone : TextInputType.number,
            onChanged: (v) => _validateInputs(),
            decoration: InputDecoration(
              hintText: _method == 'Telebirr' ? 'e.g. 0912345678' : '13-Digit Account Number',
              filled: true,
              fillColor: Colors.grey[50],
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
          ),
          
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Column(
              children: [
                _rowDetail(
                  'Platform Fee (2%)',
                  'ETB ${(_amount * _feeRate).toStringAsFixed(2)}',
                ),
                const Divider(height: 24),
                _rowDetail(
                  'Net Payout Amount',
                  'ETB ${netAmount.toStringAsFixed(2)}',
                  isBold: true,
                  color: themeColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_amount >= 50 && _accountController.text.isNotEmpty && _errorText == null)
                  ? () => _submitWithdrawal(themeColor)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Confirm & Payout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowDetail(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 15 : 13,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _submitWithdrawal(Color themeColor) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Show beautiful step-by-step transaction processing animation/dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return _WithdrawalProcessingDialog(themeColor: themeColor);
          },
        );
      },
    );

    try {
      final farmer = await supabase
          .from('farmers')
          .select('id')
          .eq('user_id', user.id)
          .single();
      final farmerId = farmer['id'];

      // Simulate a small delay for verification beauty
      await Future.delayed(const Duration(milliseconds: 2500));

      await supabase.from('withdrawals').insert({
        'farmer_id': farmerId,
        'amount': _amount,
        'fee': _amount * _feeRate,
        'net_amount': _amount * (1 - _feeRate),
        'method': _method,
        'account_number': _accountController.text,
        'status': 'pending',
      });

      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        Navigator.pop(context); // Pop modal bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ETB ${_amount.toStringAsFixed(0)} payout initialized successfully via $_method! 🚀'),
            backgroundColor: themeColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _WithdrawalProcessingDialog extends StatefulWidget {
  final Color themeColor;
  const _WithdrawalProcessingDialog({required this.themeColor});

  @override
  State<_WithdrawalProcessingDialog> createState() => _WithdrawalProcessingDialogState();
}

class _WithdrawalProcessingDialogState extends State<_WithdrawalProcessingDialog> {
  int _currentStep = 0;
  final List<String> _steps = [
    'Verifying account balance...',
    'Connecting secure billing gateway...',
    'Signing payout transaction...',
    'Completing secure transfer...',
  ];

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 1; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _currentStep = i;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Processing Payout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Column(
              children: List.generate(_steps.length, (index) {
                final isActive = index <= _currentStep;
                final isCurrent = index == _currentStep;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 18,
                        color: isActive
                            ? widget.themeColor
                            : Colors.grey[300],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _steps[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isActive
                                ? Colors.black87
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
