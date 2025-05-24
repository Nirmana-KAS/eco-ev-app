import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();
  double _rating = 3;
  bool _isSubmitting = false;
  String? _submissionMessage;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _submissionMessage = null;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final email = FirebaseAuth.instance.currentUser?.email;

    try {
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'uid': uid,
        'email': email,
        'feedback': _feedbackController.text.trim(),
        'rating': _rating,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        _submissionMessage = "Thank you for your feedback!";
        _feedbackController.clear();
        _rating = 3;
      });
    } catch (e) {
      setState(() {
        _submissionMessage = "Failed to submit feedback. Please try again.";
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF007800);
    final deepPurple = const Color(0xFF007800);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Feedback"),
        backgroundColor: deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Icon(Icons.feedback, color: deepPurple, size: 54),
                const SizedBox(height: 16),
                const Text(
                  "We value your feedback",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Let us know what you think of ECO EV App.",
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // --- Rating Bar ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return IconButton(
                      icon: Icon(
                        _rating >= i + 1 ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = i + 1.0;
                        });
                      },
                    );
                  }),
                ),
                Text(
                  "Rating: $_rating / 5",
                  style: TextStyle(color: green, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 22),

                // --- Feedback Input ---
                TextFormField(
                  controller: _feedbackController,
                  minLines: 3,
                  maxLines: 6,
                  validator: (v) => v == null || v.trim().isEmpty ? "Please enter your feedback." : null,
                  decoration: InputDecoration(
                    hintText: "Type your feedback here...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                  ),
                ),
                const SizedBox(height: 28),

                // --- Submit Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: Text(_isSubmitting ? "Submitting..." : "Submit Feedback"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      elevation: 7,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    onPressed: _isSubmitting ? null : _submitFeedback,
                  ),
                ),
                const SizedBox(height: 18),

                if (_submissionMessage != null)
                  Text(
                    _submissionMessage!,
                    style: TextStyle(
                      color: _submissionMessage!.contains("Thank you") ? green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
