import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ys_job/features/profile/data/profile_repository.dart';
import 'package:ys_job/shared/models/job_model.dart';
import 'package:ys_job/shared/models/user_model.dart';
import 'package:ys_job/shared/widgets/base64_thumbnail_avatar.dart';

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
          imageThumbBase64: 'dGh1bWI=',
          cvUrl: 'https://drive.google.com/file/d/cv',
          jobTitle: 'مطوّرة Flutter',
        );

        final restored = UserModel.fromJson(source.toJson());

        expect(restored.phone, source.phone);
        expect(restored.imageBase64, source.imageBase64);
        expect(restored.imageThumbBase64, source.imageThumbBase64);
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
          logoThumbBase64: 'dGh1bWI=',
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
        expect(restored.logoThumbBase64, 'dGh1bWI=');
        expect(legacy.phone, isEmpty);
        expect(legacy.imageBase64, isEmpty);
        expect(legacy.imageThumbBase64, isEmpty);
        expect(legacy.logoBase64, isEmpty);
        expect(legacy.logoThumbBase64, isEmpty);
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
      expect(
        utf8.encode(encoded).length,
        lessThanOrEqualTo(ProfileRepository.maxImageBase64Bytes),
      );
    });

    test('keeps a high-detail image within the Base64 budget', () {
      final random = Random(42);
      final source = img.Image(width: 512, height: 512);
      for (var y = 0; y < source.height; y++) {
        for (var x = 0; x < source.width; x++) {
          source.setPixelRgb(
            x,
            y,
            random.nextInt(256),
            random.nextInt(256),
            random.nextInt(256),
          );
        }
      }
      final bytes = Uint8List.fromList(img.encodeJpg(source, quality: 95));
      final file = PlatformFile(
        name: 'detailed.jpg',
        size: bytes.lengthInBytes,
        bytes: bytes,
      );

      final encoded = ProfileRepository.encodeImageBase64(file);
      final restored = img.decodeImage(base64Decode(encoded));

      expect(
        encoded.length,
        lessThanOrEqualTo(ProfileRepository.maxImageBase64Bytes),
      );
      expect(restored, isNotNull);
      if (restored == null) fail('تعذر فك ترميز الصورة المضغوطة.');
      expect(
        restored.width,
        lessThanOrEqualTo(ProfileRepository.maxImageDimension),
      );
      expect(
        restored.height,
        lessThanOrEqualTo(ProfileRepository.maxImageDimension),
      );
    });

    test(
      'progressively reduces image dimensions for a narrow Base64 budget',
      () {
        final random = Random(7);
        final source = img.Image(width: 512, height: 512);
        for (var y = 0; y < source.height; y++) {
          for (var x = 0; x < source.width; x++) {
            source.setPixelRgb(
              x,
              y,
              random.nextInt(256),
              random.nextInt(256),
              random.nextInt(256),
            );
          }
        }
        final bytes = Uint8List.fromList(img.encodePng(source));
        final file = PlatformFile(
          name: 'resize-required.png',
          size: bytes.lengthInBytes,
          bytes: bytes,
        );
        const narrowBudget = 100 * 1024;

        final encoded = ProfileRepository.encodeImageBase64(
          file,
          maxEncodedBytes: narrowBudget,
        );
        final restored = img.decodeImage(base64Decode(encoded));

        expect(encoded.length, lessThanOrEqualTo(narrowBudget));
        expect(restored, isNotNull);
        if (restored == null) fail('تعذر فك ترميز الصورة بعد التصغير المتدرج.');
        expect(
          restored.width < ProfileRepository.maxImageDimension ||
              restored.height < ProfileRepository.maxImageDimension,
          isTrue,
        );
      },
    );

    test('rejects an image when an explicit Base64 budget cannot fit it', () {
      final source = img.Image(width: 64, height: 64);
      img.fill(source, color: img.ColorRgb8(6, 26, 51));
      final bytes = Uint8List.fromList(img.encodePng(source));
      final file = PlatformFile(
        name: 'too-small-budget.png',
        size: bytes.lengthInBytes,
        bytes: bytes,
      );

      expect(
        () => ProfileRepository.encodeImageBase64(file, maxEncodedBytes: 1),
        throwsFormatException,
      );
      expect(
        () => ProfileRepository.encodeImageBase64(file, maxEncodedBytes: 0),
        throwsArgumentError,
      );
    });

    test('creates a compact thumbnail alongside the full profile image', () {
      final random = Random(21);
      final source = img.Image(width: 512, height: 512);
      for (var y = 0; y < source.height; y++) {
        for (var x = 0; x < source.width; x++) {
          source.setPixelRgb(
            x,
            y,
            random.nextInt(256),
            random.nextInt(256),
            random.nextInt(256),
          );
        }
      }
      final bytes = Uint8List.fromList(img.encodePng(source));
      final file = PlatformFile(
        name: 'profile-source.png',
        size: bytes.lengthInBytes,
        bytes: bytes,
      );

      final payload = ProfileRepository.encodeProfileImage(file);
      final thumbnail = img.decodeImage(base64Decode(payload.thumbnailBase64));

      expect(payload.fullBase64, isNotEmpty);
      expect(payload.thumbnailBase64, isNotEmpty);
      expect(
        payload.thumbnailBase64.length,
        lessThanOrEqualTo(ProfileRepository.maxThumbnailBase64Bytes),
      );
      expect(
        payload.thumbnailBase64.length,
        lessThan(payload.fullBase64.length),
      );
      expect(thumbnail, isNotNull);
      if (thumbnail == null) fail('تعذر فك ترميز النسخة المصغرة.');
      expect(
        thumbnail.width,
        lessThanOrEqualTo(ProfileRepository.maxThumbnailDimension),
      );
      expect(
        thumbnail.height,
        lessThanOrEqualTo(ProfileRepository.maxThumbnailDimension),
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

  group('Thumbnail performance contracts', () {
    test('caps the decoded RGBA memory budget for a list avatar', () {
      const radius = 25.0;
      const devicePixelRatio = 2.0;

      expect(
        Base64ThumbnailAvatar.cacheDimension(
          radius: radius,
          devicePixelRatio: devicePixelRatio,
        ),
        100,
      );
      expect(
        Base64ThumbnailAvatar.decodedRgbaByteBudget(
          radius: radius,
          devicePixelRatio: devicePixelRatio,
        ),
        40000,
      );
    });

    test('decodes a thumbnail safely and rejects malformed Base64', () {
      final decoded = Base64ThumbnailAvatar.decode(base64Encode([1, 2, 3]));

      expect(decoded, isNotNull);
      expect(decoded, orderedEquals([1, 2, 3]));
      expect(Base64ThumbnailAvatar.decode('not-base64!'), isNull);
      expect(Base64ThumbnailAvatar.decode('   '), isNull);
    });

    test('round-trips an employer thumbnail in a search job document', () {
      final job = JobModel(
        id: 'job-thumbnail',
        employerId: 'employer-thumbnail',
        title: 'مطور Flutter',
        description: 'تطوير تطبيقات ويب',
        location: 'صنعاء',
        jobType: 'دوام كامل',
        salaryRange: '',
        isFeatured: false,
        postedAt: DateTime.utc(2026, 8, 20),
        employerName: 'شركة أفق',
        employerLogoThumbBase64: 'dGh1bWI=',
      );

      final restored = JobModel.fromJson(job.toJson());

      expect(restored.employerLogoThumbBase64, 'dGh1bWI=');
      expect(job.toFirestore()['employerLogoThumbBase64'], 'dGh1bWI=');
    });
  });
}
