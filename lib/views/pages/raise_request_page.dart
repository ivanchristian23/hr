import 'package:flutter/material.dart';
import 'letter_request_page.dart';
import 'reimbursement_request_page.dart';

class RaiseRequestPage extends StatelessWidget {
  const RaiseRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Raise Request",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 🔹 Letter Request Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                title: const Text(
                  "Letter Request",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LetterRequestPage()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Reimbursement Request Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                title: const Text(
                  "Reimbursement Request",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const ReimbursementRequestPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
