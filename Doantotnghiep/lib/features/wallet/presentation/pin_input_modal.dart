import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinInputModal extends ConsumerStatefulWidget {
  final Future<bool> Function(String) onVerify; // Return true if valid (or handle API call)
  final String title;

  const PinInputModal({
    super.key, 
    required this.onVerify,
    this.title = 'Nhập mã PIN xác nhận'
  });

  @override
  ConsumerState<PinInputModal> createState() => _PinInputModalState();
}

class _PinInputModalState extends ConsumerState<PinInputModal> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await widget.onVerify(_pinController.text);
      if (success && mounted) {
           Navigator.pop(context, _pinController.text); // Return the PIN string
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Text(widget.title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
             const SizedBox(height: 20),
             TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '******',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: _error
                ),
                validator: (value) {
                  if (value == null || value.length != 6) return 'Nhập đủ 6 số';
                  return null;
                },
             ),
             const SizedBox(height: 24),
             FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Xác thực'),
             ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
