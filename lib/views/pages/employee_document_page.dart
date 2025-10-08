import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class EmployeeDocumentsPage extends StatefulWidget {
  final int userId;
  final String userName;

  const EmployeeDocumentsPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  _EmployeeDocumentsPageState createState() => _EmployeeDocumentsPageState();
}

class _EmployeeDocumentsPageState extends State<EmployeeDocumentsPage> {
  List<Map<String, dynamic>> documents = [];
  File? selectedDocument;
  final storage = FlutterSecureStorage();
  final documentTypeController = TextEditingController();
  bool adminOnly = false;

  @override
  void initState() {
    super.initState();
    fetchDocuments();
  }

  Future<void> fetchDocuments() async {
    final token = await storage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse(
        'https://coolbuffs.com/api/documents/user_documents/${widget.userId}',
      ),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );

    if (response.statusCode == 200) {
      final List docs = jsonDecode(response.body);
      setState(() {
        documents = docs.cast<Map<String, dynamic>>();
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch documents')));
    }
  }

  Future<void> pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        selectedDocument = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadDocument() async {
    if (selectedDocument == null || documentTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a file and enter document type"),
        ),
      );
      return;
    }

    final token = await storage.read(key: 'auth_token');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://coolbuffs.com/api/documents/user_documents/${widget.userId}',
      ),
    );

    request.fields['document_type'] = documentTypeController.text;
    request.fields['admin_only'] = adminOnly ? '1' : '0';
    request.files.add(
      await http.MultipartFile.fromPath('document', selectedDocument!.path),
    );

    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Document uploaded successfully")));
      setState(() {
        selectedDocument = null;
        documentTypeController.clear();
      });
      fetchDocuments();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $responseData")));
    }
  }

  Future<void> downloadDocument(Map<String, dynamic> doc) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not authorized")));
      return;
    }

    final url =
        'https://coolbuffs.com/api/documents/user_documents/${doc['id']}/download';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        String filename = doc['document_type'] ?? 'document_${doc['id']}';
        final contentDisposition = response.headers['content-disposition'];
        if (contentDisposition != null) {
          final regex = RegExp(r'filename="(.+)"');
          final match = regex.firstMatch(contentDisposition);
          if (match != null) filename = match.group(1)!;
        }

        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        await OpenFile.open(filePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download file (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error downloading: $e')));
    }
  }

  Future<void> confirmDelete(int docId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this document?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      deleteDocument(docId);
    }
  }

  Future<void> deleteDocument(int docId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not authorized")));
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('https://coolbuffs.com/api/documents/user_documents/$docId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document deleted successfully")),
        );
        fetchDocuments(); // refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete document (${response.statusCode})"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting document: $e")));
    }
  }

  void showUploadModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add Document",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: documentTypeController,
                decoration: const InputDecoration(labelText: "Document Type"),
              ),
              SwitchListTile(
                title: const Text("Admin Only"),
                value: adminOnly,
                onChanged: (val) => setModalState(() => adminOnly = val),
              ),
              ElevatedButton.icon(
                onPressed: pickDocument,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  selectedDocument != null ? "Change File" : "Select File",
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: uploadDocument,
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload Document"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.userName}'s Documents")),
      floatingActionButton: FloatingActionButton(
        onPressed: showUploadModal,
        child: const Icon(Icons.add),
      ),
      body: documents.isEmpty
          ? const Center(child: Text("No documents uploaded yet"))
          : ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      doc['document_type'] ?? "Document ${doc['id']}",
                    ),
                    subtitle: Text(
                      doc['admin_only'] == 1 ? "Admin Only" : "Visible to all",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () => downloadDocument(doc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => confirmDelete(doc['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
