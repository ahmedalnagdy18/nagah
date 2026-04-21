import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nagah/features/home/domain/model/home_models.dart';
import 'package:nagah/features/home/presentation/widgets/section_card.dart';

class ReportComposerScreen extends StatefulWidget {
  const ReportComposerScreen({
    super.key,
    required this.roads,
    required this.selectedLocation,
    required this.onLogout,
    required this.onSubmit,
  });

  final List<RoadSegment> roads;
  final LocationPoint selectedLocation;
  final VoidCallback onLogout;
  final void Function({
    required String? roadId,
    required IssueType issueType,
    required String description,
    required String? imagePath,
  })
  onSubmit;

  @override
  State<ReportComposerScreen> createState() => _ReportComposerScreenState();
}

class _ReportComposerScreenState extends State<ReportComposerScreen> {
  late IssueType _issueType;
  String? _roadId;
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _issueType = IssueType.accident;
    _roadId = widget.roads.isEmpty ? null : widget.roads.first.id;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasRoads = widget.roads.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        title: const Text('Create report'),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Issue type',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: IssueType.values.map((type) {
                    final selected = _issueType == type;
                    return ChoiceChip(
                      label: Text(type.label),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _issueType = type;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location and road',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.place_rounded, color: Color(0xFFDC2626)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${widget.selectedLocation.latitude.toStringAsFixed(5)}, ${widget.selectedLocation.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (hasRoads)
                  DropdownButtonFormField<String>(
                    initialValue: _roadId,
                    decoration: const InputDecoration(
                      labelText: 'Affected road',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.roads
                        .map(
                          (roadItem) => DropdownMenuItem<String>(
                            value: roadItem.id,
                            child: Text(roadItem.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _roadId = value;
                      });
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'No real roads were loaded from Supabase yet. The report will still be sent, but without linking it to a specific road.',
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Choose the accident point from the map. If you do not choose one, the app will use your current location.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Describe the road issue clearly for review.',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Optional image',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickImageFromGallery,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 56,
                              width: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF111827),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _imagePath != null
                                    ? Icons.image_rounded
                                    : Icons.add_a_photo_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _imagePath != null
                                    ? 'Image selected from gallery. Tap again to change it.'
                                    : 'You can send the report without an image, or tap here to choose one from gallery.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_imagePath != null) ...[
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              File(_imagePath!),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 180,
                                  width: double.infinity,
                                  color: const Color(0xFFF3F4F6),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Could not preview the selected image.',
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _imagePath = null;
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Remove image'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              if (_descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please add a short description.'),
                  ),
                );
                return;
              }

              widget.onSubmit(
                roadId: _roadId,
                issueType: _issueType,
                description: _descriptionController.text.trim(),
                imagePath: _imagePath,
              );
              _descriptionController.clear();
              setState(() {
                _imagePath = null;
                _issueType = IssueType.accident;
                if (widget.roads.isNotEmpty) {
                  _roadId = widget.roads.first.id;
                }
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.send_rounded),
            label: const Text('Submit for admin review'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (!mounted || pickedFile == null) {
      return;
    }

    setState(() {
      _imagePath = pickedFile.path;
    });
  }
}
