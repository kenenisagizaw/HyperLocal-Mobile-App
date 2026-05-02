import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';

class ImageUtils {
  static ImageProvider? resolveImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }
    
    final extractedUrl = extractImageUrl(imagePath);
    if (extractedUrl.isEmpty) {
      return null;
    }
    
    final trimmed = extractedUrl.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      return NetworkImage(trimmed);
    }
    
    if (trimmed.startsWith('/')) {
      return NetworkImage('${ApiConstants.baseUrl}$trimmed');
    }
    
    // For local files, check if file exists before loading
    final file = File(extractedUrl);
    if (file.existsSync()) {
      return FileImage(file);
    }
    
    return null;
  }
  
  static String extractImageUrl(String value) {
    if (value.isEmpty) return '';
    
    // Check if it's a JSON object string
    if (value.startsWith('{') && value.endsWith('}')) {
      try {
        // Try to parse as JSON and extract URL
        final urlMatch = RegExp(r'url:\s*([^,}]+)').firstMatch(value);
        if (urlMatch != null) {
          return urlMatch.group(1)?.trim() ?? '';
        }
      } catch (e) {
        // If parsing fails, return empty string
        return '';
      }
    }
    
    return value.trim();
  }
  
  static List<String> extractImageUrls(List<dynamic> images) {
    return images.map((item) => _extractSingleImageUrl(item)).where((url) => url.isNotEmpty).toList();
  }
  
  static String _extractSingleImageUrl(dynamic item) {
    if (item is String) {
      return item;
    }
    
    if (item is Map<String, dynamic>) {
      // Try to extract URL from common fields
      final url = item['url'] ?? 
                 item['path'] ?? 
                 item['src'] ?? 
                 item['image'] ?? 
                 item['imageUrl'] ??
                 item['image_url'];
      
      if (url is String && url.isNotEmpty) {
        return url;
      }
      
      // If it's a complex object, try to convert to JSON and extract
      final jsonString = item.toString();
      if (jsonString.contains('url:')) {
        final urlMatch = RegExp(r'url:\s*([^,}]+)').firstMatch(jsonString);
        if (urlMatch != null) {
          return urlMatch.group(1)?.trim() ?? '';
        }
      }
    }
    
    return item.toString();
  }
  
  static Widget buildImageWithErrorHandling({
    required String? imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final imageProvider = resolveImage(imagePath);
    
    if (imageProvider == null) {
      return errorWidget ?? placeholder ?? _buildDefaultPlaceholder(width, height);
    }
    
    return Image(
      image: imageProvider,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildLoadingPlaceholder(width, height);
      },
    );
  }
  
  static Widget buildNetworkImageWithErrorHandling({
    required String url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildLoadingPlaceholder(width, height);
      },
    );
  }
  
  static Widget _buildDefaultPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(
        Icons.image,
        size: (width ?? 100) * 0.3,
        color: Colors.grey[600],
      ),
    );
  }
  
  static Widget _buildLoadingPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: (width ?? 100) * 0.3,
          height: (width ?? 100) * 0.3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }
}
