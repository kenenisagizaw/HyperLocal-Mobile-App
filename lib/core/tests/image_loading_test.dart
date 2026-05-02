import 'package:flutter/material.dart';
import '../utils/image_utils.dart';

/// Test screen to verify image loading fixes
class ImageLoadingTestScreen extends StatelessWidget {
  const ImageLoadingTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Loading Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Scenarios',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Test 1: JSON object string (the problematic case)
            _buildTestSection(
              'JSON Object String (Problematic Case)',
              '{id: 98584c1c-277f-40c2-9cea-8931c908a02e, serviceRequestId: f9bfccc2-3920-481f-b805-23018e6795cd, url: /uploads/requests/images-1777426695334-584338072.jpg, type: IMAGE, createdAt: 2026-04-29T01:38:21.931Z}',
            ),
            
            // Test 2: Regular URL
            _buildTestSection(
              'Regular URL',
              'https://example.com/image.jpg',
            ),
            
            // Test 3: Relative path
            _buildTestSection(
              'Relative Path',
              '/uploads/images/test.jpg',
            ),
            
            // Test 4: Empty string
            _buildTestSection(
              'Empty String',
              '',
            ),
            
            // Test 5: Invalid URL
            _buildTestSection(
              'Invalid URL',
              'not-a-valid-url',
            ),
            
            // Test 6: Local file path (if exists)
            _buildTestSection(
              'Local File Path',
              '/path/to/local/image.jpg',
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Image Utils Methods Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildUtilsTestSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(String title, String imagePath) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Input: $imagePath',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ImageUtils.buildImageWithErrorHandling(
                imagePath: imagePath,
                width: 100,
                height: 100,
                placeholder: Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Extracted URL: ${ImageUtils.extractImageUrl(imagePath)}',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilsTestSection() {
    // Test the extractImageUrls method with a list of mixed formats
    final testImages = [
      'https://example.com/image1.jpg',
      {
        'id': 'test-1',
        'url': '/uploads/image2.jpg',
        'type': 'IMAGE'
      },
      {
        'url': 'https://example.com/image3.jpg',
        'path': '/different/path.jpg'
      },
      'not-a-valid-image',
    ];

    final extractedUrls = ImageUtils.extractImageUrls(testImages);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'extractImageUrls() Test',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Input: Mixed list of strings and objects',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...extractedUrls.map((url) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $url',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.green,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
