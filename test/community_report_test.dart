import 'package:envirohub_citizen/features/reports/models/community_report.dart';
import 'package:envirohub_citizen/features/reports/models/nearby_report.dart';
import 'package:envirohub_citizen/features/reports/models/report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final communityJson = <String, dynamic>{
    'id': 'report-123',
    'category': {'name': 'Waste', 'slug': 'waste'},
    'description': 'Garbage near the road',
    'status': 'SUBMITTED',
    'address': 'Main road',
    'latitude': 33.6844,
    'longitude': 73.0479,
    'created_at': '2026-09-23T10:00:00Z',
    'confirmation_count': 2,
    'follower_count': 3,
    'is_confirmed': true,
    'is_following': false,
    'images': [
      {
        'id': 'image-1',
        'image': '/media/reports/before.jpg',
        'image_type': 'BEFORE',
        'created_at': '2026-09-23T10:00:00Z',
      },
    ],
  };

  group('Community report mapping', () {
    test('parses safe shared detail, engagement and BEFORE images', () {
      final report = CommunityReport.fromJson(communityJson);
      expect(report.id, 'report-123');
      expect(report.categoryName, 'Waste');
      expect(report.confirmationCount, 2);
      expect(report.followerCount, 3);
      expect(report.isConfirmed, isTrue);
      expect(report.isFollowing, isFalse);
      expect(report.isClosed, isFalse);
      expect(report.images.single.type, 'BEFORE');
    });

    test('closed reports are detected and existing engagement stays visible', () {
      final report = CommunityReport.fromJson({
        ...communityJson,
        'status': 'RESOLVED',
        'is_following': true,
      });
      expect(report.isClosed, isTrue);
      expect(report.isFollowing, isTrue);
      expect(report.confirmationCount, 2);
    });

    test('missing optional engagement fields are mapped safely', () {
      final report = CommunityReport.fromJson({
        ...communityJson,
        'images': [],
        'confirmation_count': null,
        'follower_count': null,
        'is_confirmed': null,
        'is_following': null,
      });
      expect(report.confirmationCount, 0);
      expect(report.followerCount, 0);
      expect(report.isConfirmed, isFalse);
      expect(report.isFollowing, isFalse);
      expect(report.images, isEmpty);
    });
  });

  group('Existing nearby and owner report mapping', () {
    test('nearby response reads distance, counts and personal flags', () {
      final nearby = NearbyReport.fromJson({
        'id': 'report-123',
        'category': {'name': 'Waste', 'slug': 'waste'},
        'status': 'VERIFIED',
        'distance_m': 82.6,
        'created_at': '2026-09-23T10:00:00Z',
        'confirmation_count': 5,
        'follower_count': 1,
        'is_confirmed': false,
        'is_following': true,
      });
      expect(nearby.distanceM, 83);
      expect(nearby.confirmationCount, 5);
      expect(nearby.followerCount, 1);
      expect(nearby.isConfirmed, isFalse);
      expect(nearby.isFollowing, isTrue);
    });

    test('owner detail retains timeline while adding community counts', () {
      final report = ReportDetail.fromJson({
        ...communityJson,
        'timeline': [
          {'status': 'SUBMITTED', 'note': 'Submitted', 'created_at': '2026-09-23T10:00:00Z'},
        ],
      });
      expect(report.timeline.single.note, 'Submitted');
      expect(report.confirmationCount, 2);
      expect(report.followerCount, 3);
      expect(report.images.single.type, 'BEFORE');
    });
  });
}
