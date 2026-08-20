import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
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
          resumeUrl: 'https://storage.example/resume.pdf',
          phone: '777000111',
          photoUrl: 'https://storage.example/photo.png',
          jobTitle: 'مطوّرة Flutter',
        );

        final restored = UserModel.fromJson(source.toJson());

        expect(restored.phone, source.phone);
        expect(restored.photoUrl, source.photoUrl);
        expect(restored.jobTitle, source.jobTitle);
        expect(restored.skills, source.skills);
        expect(restored.resumeUrl, source.resumeUrl);
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
          photoUrl: 'https://storage.example/logo.png',
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
        expect(legacy.photoUrl, isEmpty);
        expect(legacy.companyName, isEmpty);
        expect(legacy.jobTitle, isEmpty);
      },
    );
  });

  group('ProfileRepository validation and update contracts', () {
    test('accepts JPG and PNG images under two megabytes only', () {
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
        size: ProfileRepository.maxImageBytes + 1,
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

    test('accepts PDF resumes under five megabytes only', () {
      final accepted = PlatformFile(
        name: 'cv.pdf',
        size: 128,
        bytes: Uint8List(128),
      );
      final unsupported = PlatformFile(
        name: 'cv.docx',
        size: 128,
        bytes: Uint8List(128),
      );
      final oversized = PlatformFile(
        name: 'cv.pdf',
        size: ProfileRepository.maxResumeBytes + 1,
        bytes: Uint8List(1),
      );

      expect(
        () => ProfileRepository.validateResumeFile(accepted),
        returnsNormally,
      );
      expect(
        () => ProfileRepository.validateResumeFile(unsupported),
        throwsFormatException,
      );
      expect(
        () => ProfileRepository.validateResumeFile(oversized),
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
