import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ys_job/features/profile/data/profile_repository.dart';
import 'package:ys_job/shared/models/user_model.dart';

void main() {
  group('UserModel profile fields', () {
    test(
      'round-trips seeker profile fields while retaining existing fields',
      () {
        final source = UserModel(
          id: 'seeker-1',
          name: 'هدى أحمد',
          email: 'huda@example.com',
          role: UserRole.seeker,
          createdAt: DateTime.utc(2026, 8, 20),
          bio: 'مطوّرة تطبيقات',
          skills: const ['Flutter', 'Firebase'],
          phone: '777000111',
          imageBase64: 'aW1hZ2U=',
          cvUrl: 'https://drive.google.com/file/d/cv',
          jobTitle: 'مطوّرة Flutter',
        );

        final restored = UserModel.fromJson(source.toJson());

        expect(restored.phone, source.phone);
        expect(restored.imageBase64, source.imageBase64);
        expect(restored.jobTitle, source.jobTitle);
        expect(restored.skills, source.skills);
        expect(restored.cvUrl, source.cvUrl);
      },
    );

    test(
      'supports employer-specific fields and old documents without them',
      () {
        final employer = UserModel(
          id: 'employer-1',
          name: 'شركة افق',
          email: 'company@example.com',
          role: UserRole.employer,
          createdAt: DateTime.utc(2026, 8, 20),
          companyName: 'شركة أفق للتقنية',
          industry: 'تقنية المعلومات',
          phone: '777000222',
          logoBase64: 'bG9nbw==',
        );
        final restored = UserModel.fromJson(employer.toJson());
        final legacy = UserModel.fromJson({
          'id': 'legacy',
          'name': 'حساب قديم',
          'email': 'legacy@example.com',
          'role': 'seeker',
          'createdAt': '2026-08-20T00:00:00.000Z',
        });

        expect(restored.companyName, 'شركة أفق للتقنية');
        expect(restored.industry, 'تقنية المعلومات');
        expect(legacy.phone, isEmpty);
        expect(legacy.imageBase64, isEmpty);
        expect(legacy.logoBase64, isEmpty);
        expect(legacy.cvUrl, isEmpty);
        expect(legacy.companyName, isEmpty);
        expect(legacy.jobTitle, isEmpty);
      },
    );
  });

  group('ProfileRepository validation and update contracts', () {
    test('accepts JPG and PNG source images under two megabytes only', () {
      final accepted = PlatformFile(
        name: 'avatar.PNG',
        size: 128,
        bytes: Uint8List(128),
      );
      final unsupported = PlatformFile(
        name: 'avatar.gif',
        size: 128,
        bytes: Uint8List(128),
      );
      final oversized = PlatformFile(
        name: 'avatar.jpg',
        size: ProfileRepository.maxSourceImageBytes + 1,
        bytes: Uint8List(1),
      );

      expect(
        () => ProfileRepository.validateImageFile(accepted),
        returnsNormally,
      );
      expect(
        () => ProfileRepository.validateImageFile(unsupported),
        throwsFormatException,
      );
      expect(
        () => ProfileRepository.validateImageFile(oversized),
        throwsFormatException,
      );
    });

    test('compresses a selected image before Base64 encoding', () {
      final source = img.Image(width: 1024, height: 512);
      img.fill(source, color: img.ColorRgb8(217, 164, 65));
      final bytes = Uint8List.fromList(img.encodePng(source));
      final file = PlatformFile(
        name: 'profile.png',
        size: bytes.lengthInBytes,
        bytes: bytes,
      );

      final encoded = ProfileRepository.encodeImageBase64(file);
      final restored = img.decodeImage(
        UriData.parse('data:image/jpeg;base64,$encoded').contentAsBytes(),
      );

      expect(encoded, isNotEmpty);
      expect(restored, isNotNull);
      if (restored == null) fail('تعذر فك ترميز صورة Base64 الناتجة.');
      expect(
        restored.width,
        lessThanOrEqualTo(ProfileRepository.maxImageDimension),
      );
      expect(
        restored.height,
        lessThanOrEqualTo(ProfileRepository.maxImageDimension),
      );
    });

    test('accepts only external HTTP and HTTPS CV links', () {
      expect(
        ProfileRepository.normalizedExternalCvUrl(
          ' https://drive.google.com/file/d/cv ',
        ),
        'https://drive.google.com/file/d/cv',
      );
      expect(
        () =>
            ProfileRepository.normalizedExternalCvUrl('file:///private/cv.pdf'),
        throwsFormatException,
      );
    });

    test(
      'creates separate update payloads for seeker and employer profiles',
      () {
        final seeker = ProfileRepository.seekerProfilePayload(
          name: ' هدى ',
          bio: ' مطوّرة ',
          skills: const ['Flutter', ' Flutter ', '', 'Firebase'],
          phone: ' 777000111 ',
          jobTitle: ' مطورة Flutter ',
          cvUrl: ' https://drive.google.com/file/d/cv ',
        );
        final employer = ProfileRepository.employerProfilePayload(
          name: ' شركة أفق ',
          companyName: ' أفق للتقنية ',
          industry: ' تقنية المعلومات ',
          bio: ' شركة برمجيات ',
          phone: ' 777000222 ',
        );

        expect(seeker, {
          'name': 'هدى',
          'bio': 'مطوّرة',
          'skills': ['Flutter', 'Firebase'],
          'phone': '777000111',
          'jobTitle': 'مطورة Flutter',
          'cvUrl': 'https://drive.google.com/file/d/cv',
        });
        expect(employer, {
          'name': 'شركة أفق',
          'companyName': 'أفق للتقنية',
          'industry': 'تقنية المعلومات',
          'bio': 'شركة برمجيات',
          'phone': '777000222',
        });
        expect(employer.containsKey('skills'), isFalse);
        expect(seeker.containsKey('industry'), isFalse);
      },
    );
  });
}
