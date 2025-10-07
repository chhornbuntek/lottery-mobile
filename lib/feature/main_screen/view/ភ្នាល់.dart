import 'package:flutter/material.dart';

class BettingScreen extends StatefulWidget {
  const BettingScreen({super.key});

  @override
  State<BettingScreen> createState() => _BettingScreenState();
}

class _BettingScreenState extends State<BettingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _betNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final String _selectedBill = 'ល.រ';
  final Map<String, bool> _checkboxes = {
    '4P': false,
    'F': false,
    'B': false,
    '7P': false,
    'I': false,
    'C': false,
    'Lo': false,
    'N': false,
    'D': false,
  };
  int _focusedFieldIndex =
      0; // Track which field is focused: 0=name, 1=bet, 2=amount

  void _onKeypadPressed(String value) {
    setState(() {
      switch (_focusedFieldIndex) {
        case 0:
          _nameController.text += value;
          break;
        case 1:
          _betNumberController.text += value;
          break;
        case 2:
          _amountController.text += value;
          break;
      }
    });
  }

  void _onClearPressed() {
    setState(() {
      switch (_focusedFieldIndex) {
        case 0:
          _nameController.clear();
          break;
        case 1:
          _betNumberController.clear();
          break;
        case 2:
          _amountController.clear();
          break;
      }
    });
  }

  void _onBackspacePressed() {
    setState(() {
      switch (_focusedFieldIndex) {
        case 0:
          if (_nameController.text.isNotEmpty) {
            _nameController.text = _nameController.text.substring(
              0,
              _nameController.text.length - 1,
            );
          }
          break;
        case 1:
          if (_betNumberController.text.isNotEmpty) {
            _betNumberController.text = _betNumberController.text.substring(
              0,
              _betNumberController.text.length - 1,
            );
          }
          break;
        case 2:
          if (_amountController.text.isNotEmpty) {
            _amountController.text = _amountController.text.substring(
              0,
              _amountController.text.length - 1,
            );
          }
          break;
      }
    });
  }

  void _switchFocus() {
    setState(() {
      _focusedFieldIndex = (_focusedFieldIndex + 1) % 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 1, child: _buildDisplayArea()),
                Expanded(flex: 1, child: _buildInputSection()),
              ],
            ),
          ),
          _buildKeypad(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.yellow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'បង់ប្រាក់',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '0',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text(
              '0',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.print, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Text(
          'Display Area',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2C5F5F), // Dark teal color
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeButton(),
          const SizedBox(height: 10),
          _buildInputField(
            'ឈ្មោះ',
            'ឈ្មោះអតិថិជន',
            controller: _nameController,
          ),
          const SizedBox(height: 10),
          _buildInputField('លេខចាក់:', '', controller: _betNumberController),
          const SizedBox(height: 10),
          _buildInputField('ចំនួន:', '', controller: _amountController),
          const SizedBox(height: 10),
          _buildDropdownField(),
          const SizedBox(height: 10),
          _buildCheckboxGrid(),
        ],
      ),
    );
  }

  Widget _buildTimeButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'ពេល',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint, {
    TextEditingController? controller,
  }) {
    bool isFocused = false;
    if (controller == _nameController) {
      isFocused = _focusedFieldIndex == 0;
    } else if (controller == _betNumberController) {
      isFocused = _focusedFieldIndex == 1;
    } else if (controller == _amountController) {
      isFocused = _focusedFieldIndex == 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            if (controller != null) {
              if (controller == _nameController) {
                _focusedFieldIndex = 0;
              } else if (controller == _betNumberController) {
                _focusedFieldIndex = 1;
              } else if (controller == _amountController) {
                _focusedFieldIndex = 2;
              }
              setState(() {});
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: isFocused
                  ? Border.all(color: Colors.green, width: 2)
                  : null,
            ),
            child: controller != null
                ? TextField(
                    controller: controller,
                    enabled: false, // Disable keyboard
                    decoration: InputDecoration(
                      hintText: hint,
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : Text(
                    hint,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'បុង: ល.រ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedBill,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxGrid() {
    return Column(
      children: [
        _buildCheckboxRow(['4P', 'F', 'B']),
        const SizedBox(height: 12),
        _buildCheckboxRow(['7P', 'I', 'C']),
        const SizedBox(height: 12),
        _buildCheckboxRow(['Lo', 'N', 'D']),
      ],
    );
  }

  Widget _buildCheckboxRow(List<String> labels) {
    return Row(
      children: labels.map((label) {
        return Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _checkboxes[label] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _checkboxes[label] = value ?? false;
                    });
                  },
                  activeColor: Colors.orange,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2C5F5F), // Dark teal color
      ),
      child: Column(
        children: [
          _buildKeypadRow([
            _buildKeypadButton(
              Icons.arrow_back,
              'Back',
              Colors.red,
              onPressed: _onBackspacePressed,
            ),
            _buildNumberButton('7', onPressed: () => _onKeypadPressed('7')),
            _buildNumberButton('8', onPressed: () => _onKeypadPressed('8')),
            _buildNumberButton('9', onPressed: () => _onKeypadPressed('9')),
            _buildKeypadButton(
              Icons.close,
              '',
              Colors.white,
              onPressed: _onClearPressed,
            ),
          ]),
          const SizedBox(height: 8),
          _buildKeypadRow([
            _buildKeypadButton(Icons.list, 'បង្ហាញ', Colors.red),
            _buildNumberButton('4', onPressed: () => _onKeypadPressed('4')),
            _buildNumberButton('5', onPressed: () => _onKeypadPressed('5')),
            _buildNumberButton('6', onPressed: () => _onKeypadPressed('6')),
            _buildKeypadButton(
              Icons.arrow_forward,
              '',
              Colors.white,
              onPressed: _switchFocus,
            ),
          ]),
          const SizedBox(height: 8),
          _buildKeypadRow([
            _buildKeypadButton(Icons.delete, 'លុប', Colors.red),
            _buildNumberButton('1', onPressed: () => _onKeypadPressed('1')),
            _buildNumberButton('2', onPressed: () => _onKeypadPressed('2')),
            _buildNumberButton('3', onPressed: () => _onKeypadPressed('3')),
            _buildKeypadButton(Icons.remove, '', Colors.white),
          ]),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildKeypadButton(
                  Icons.gps_fixed,
                  'ចាក់ថ្មី',
                  Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNumberButton(
                  '0',
                  onPressed: () => _onKeypadPressed('0'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKeypadButton(
                  Icons.arrow_forward,
                  '',
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<Widget> buttons) {
    return Row(
      children: buttons.map((button) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: button,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(
    IconData icon,
    String label,
    Color backgroundColor, {
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (label.isNotEmpty)
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number, {VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _betNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
