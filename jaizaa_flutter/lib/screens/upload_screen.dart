import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../providers/analysis_provider.dart';
import '../providers/patient_provider.dart';
import '../services/api_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _showNewPatientForm = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String? _selectedPatientId;
  bool _isCreatingPatient = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().loadPatients();
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'docx'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final name = result.files.single.name;
      if (mounted) {
        context.read<AnalysisProvider>().setFile(bytes, name);
      }
    }
  }

  Future<void> _takePhoto() async {
    // On web, ImageSource.camera is not reliably supported—fall back to file picker
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final name = result.files.single.name;
        if (mounted) {
          context.read<AnalysisProvider>().setFile(bytes, name);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image selected: $name (${bytes.length} bytes)'),
              backgroundColor: JaizaaTheme.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      return;
    }

    // Mobile: use real camera
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      final name = image.name.isNotEmpty ? image.name : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      debugPrint('[Camera] Captured: $name, size: ${bytes.length} bytes');
      if (mounted) {
        context.read<AnalysisProvider>().setFile(bytes, name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo captured: $name (${bytes.length} bytes)'),
            backgroundColor: JaizaaTheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _createNewPatient() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _isCreatingPatient = true);
    try {
      final apiService = ApiService();
      final newPatient = await apiService.createPatient(_nameController.text.trim(), _phoneController.text.trim());
      if (mounted) {
        await context.read<PatientProvider>().loadPatients();
        setState(() {
          _selectedPatientId = newPatient['patient_id'].toString();
          _showNewPatientForm = false;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create patient: \$e')));
    } finally {
      if (mounted) setState(() => _isCreatingPatient = false);
    }
  }

  void _analyzeReport() {
    final analysisProvider = context.read<AnalysisProvider>();
    if (analysisProvider.selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file first')));
      return;
    }
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a patient')));
      return;
    }
    
    // Only clear previous approval states — do NOT clear file bytes (analyze() needs them)
    analysisProvider.resetApprovalsForPatient(_selectedPatientId!);
    analysisProvider.setPatient(_selectedPatientId!);
    Navigator.pushNamed(context, '/processing');
  }


  @override
  Widget build(BuildContext context) {
    final analysisProvider = context.watch<AnalysisProvider>();
    final patientProvider = context.watch<PatientProvider>();

    return Scaffold(
      backgroundColor: JaizaaTheme.background,
      appBar: AppBar(
        backgroundColor: JaizaaTheme.surface,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: JaizaaTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Jaizaa',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: JaizaaTheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Upload Report',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildUploadOption(
                        icon: Icons.upload_file,
                        label: 'Select File\n(PDF/Image)',
                        onTap: _pickFile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildUploadOption(
                        icon: Icons.photo_camera,
                        label: 'Take Photo\nof Report',
                        onTap: _takePhoto,
                      ),
                    ),
                  ],
                ),
                if (analysisProvider.selectedFileName != null) ...[
                  const SizedBox(height: 16),
                  _buildFilePreview(analysisProvider.selectedFileName!),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Patient Details',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showNewPatientForm = !_showNewPatientForm;
                          _selectedPatientId = null;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _showNewPatientForm ? 'Select Existing' : 'Add New Patient',
                        style: const TextStyle(color: JaizaaTheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_showNewPatientForm) 
                  _buildNewPatientForm() 
                else 
                  _buildExistingPatientSearch(patientProvider),
                const SizedBox(height: 100), // Padding for the bottom FAB
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: JaizaaTheme.surface.withOpacity(0.9),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: ElevatedButton.icon(
                onPressed: _analyzeReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: JaizaaTheme.primary,
                  foregroundColor: JaizaaTheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                  shadowColor: JaizaaTheme.primary.withOpacity(0.4),
                ),
                icon: const Icon(Icons.troubleshoot),
                label: const Text('ANALYZE REPORT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: JaizaaTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: JaizaaTheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: JaizaaTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(String fileName) {
    IconData fileIcon = Icons.insert_drive_file;
    if (fileName.toLowerCase().endsWith('.pdf')) {
      fileIcon = Icons.picture_as_pdf;
    } else if (fileName.toLowerCase().endsWith('.png') || fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg')) {
      fileIcon = Icons.image;
    } else if (fileName.toLowerCase().endsWith('.docx')) {
      fileIcon = Icons.description;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: JaizaaTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JaizaaTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(fileIcon, color: JaizaaTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(fileName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: JaizaaTheme.textSecondary),
            onPressed: () {
              context.read<AnalysisProvider>().clear();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExistingPatientSearch(PatientProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: JaizaaTheme.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: JaizaaTheme.primary, width: 2)),
      ),
      hint: const Text("Select a patient..."),
      value: _selectedPatientId,
      items: provider.patients.map((p) {
        return DropdownMenuItem<String>(
          value: p['patient_id'].toString(),
          child: Text(p['name']),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedPatientId = val;
        });
      },
    );
  }

  Widget _buildNewPatientForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JaizaaTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Full Name', style: TextStyle(fontFamily: 'JetBrains Mono', color: JaizaaTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              filled: true,
              fillColor: JaizaaTheme.background,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: JaizaaTheme.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Phone Number', style: TextStyle(fontFamily: 'JetBrains Mono', color: JaizaaTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              filled: true,
              fillColor: JaizaaTheme.background,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: JaizaaTheme.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCreatingPatient ? null : _createNewPatient,
              style: ElevatedButton.styleFrom(
                backgroundColor: JaizaaTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: _isCreatingPatient 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Text("Save New Patient"),
            ),
          ),
        ],
      ),
    );
  }
}
