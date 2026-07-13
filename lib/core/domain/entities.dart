/// Tspace Domain Entities — Core Business Models
///
/// These entities represent the pure business objects that are independent
/// of any framework, API, or database. They are used across the domain
/// and presentation layers.
library;

import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════
// USER & SESSION
// ═══════════════════════════════════════════════════════════════════════

/// Represents an authenticated user session.
class UserSession extends Equatable {
  final String accessToken;
  final String refreshToken;
  final User user;

  const UserSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}

/// Core user identity.
class User extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? professionalTitle;
  final bool hasCompletedOnboarding;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.professionalTitle,
    this.hasCompletedOnboarding = false,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    avatarUrl,
    professionalTitle,
    hasCompletedOnboarding,
  ];
}

// ═══════════════════════════════════════════════════════════════════════
// PROFESSIONAL ROLE (ONBOARDING)
// ═══════════════════════════════════════════════════════════════════════

/// The professional track a user selects during onboarding.
///
/// Each role drives which default blocks are generated and which
/// third-party integrations are surfaced first.
enum ProfessionalRole {
  developer(
    label: 'Developer',
    emoji: '💻',
    subtitle: 'Sync repos and tech stack',
  ),
  designer(label: 'Designer', emoji: '🎨', subtitle: 'Showcase design works'),
  photographer(
    label: 'Photographer',
    emoji: '📷',
    subtitle: 'Gallery images & portfolios',
  ),
  writer(
    label: 'Writer',
    emoji: '✍️',
    subtitle: 'Aggregate newsletters & articles',
  ),
  videographer(
    label: 'Videographer',
    emoji: '🎥',
    subtitle: 'Showcase video project reels',
  ),
  musician(
    label: 'Musician',
    emoji: '🎵',
    subtitle: 'Share tracks and performances',
  ),
  marketer(
    label: 'Marketer',
    emoji: '📈',
    subtitle: 'Highlight growth and analytics',
  ),
  consultant(
    label: 'Consultant',
    emoji: '💼',
    subtitle: 'Showcase consulting services',
  );

  final String label;
  final String emoji;
  final String subtitle;

  const ProfessionalRole({
    required this.label,
    required this.emoji,
    required this.subtitle,
  });
}

// ═══════════════════════════════════════════════════════════════════════
// PORTFOLIO & BLOCKS
// ═══════════════════════════════════════════════════════════════════════

/// A user's portfolio with its theme and ordered list of [PortfolioBlock]s.
class Portfolio extends Equatable {
  final String id;
  final String slug;
  final ThemeSettings themeSettings;
  final bool isPublished;
  final List<PortfolioBlock> blocks;

  const Portfolio({
    required this.id,
    required this.slug,
    required this.themeSettings,
    required this.isPublished,
    required this.blocks,
  });

  /// Returns a copy with an updated block list (used after reorder/add/delete).
  Portfolio copyWithBlocks(List<PortfolioBlock> newBlocks) {
    return Portfolio(
      id: id,
      slug: slug,
      themeSettings: themeSettings,
      isPublished: isPublished,
      blocks: newBlocks,
    );
  }

  @override
  List<Object?> get props => [id, slug, themeSettings, isPublished, blocks];
}

/// Visual theme configuration persisted as JSONB on the backend.
class ThemeSettings extends Equatable {
  final String accentColor;
  final String fontFamily;
  final String layoutTemplate; // 'minimal_dark', 'bento_creative', etc.

  const ThemeSettings({
    this.accentColor = '#6366F1',
    this.fontFamily = 'Inter',
    this.layoutTemplate = 'minimal_dark',
  });

  @override
  List<Object?> get props => [accentColor, fontFamily, layoutTemplate];
}

/// The type discriminator for polymorphic portfolio blocks.
enum BlockType {
  profile,
  text,
  link,
  github,
  figma,
  video,
  rss,
  statsCounter,
  prompt,
  image,
  project,
}

/// Grid positioning for a single block within the bento layout.
class GridPosition extends Equatable {
  final int x;
  final int y;
  final int w;
  final int h;

  const GridPosition({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  @override
  List<Object?> get props => [x, y, w, h];
}

/// A single block within a portfolio grid.
///
/// The [content] field is a `Map<String, dynamic>` to support polymorphic
/// block data (GitHub repos, RSS feeds, prompt playgrounds, etc.) stored
/// as JSONB in PostgreSQL.
class PortfolioBlock extends Equatable {
  final String id;
  final BlockType type;
  final GridPosition gridPosition;
  final Map<String, dynamic> content;
  final bool isVisible;
  final int sortOrder;

  const PortfolioBlock({
    required this.id,
    required this.type,
    required this.gridPosition,
    required this.content,
    this.isVisible = true,
    this.sortOrder = 0,
  });

  PortfolioBlock copyWith({
    GridPosition? gridPosition,
    Map<String, dynamic>? content,
    bool? isVisible,
    int? sortOrder,
  }) {
    return PortfolioBlock(
      id: id,
      type: type,
      gridPosition: gridPosition ?? this.gridPosition,
      content: content ?? this.content,
      isVisible: isVisible ?? this.isVisible,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    gridPosition,
    content,
    isVisible,
    sortOrder,
  ];
}

// ═══════════════════════════════════════════════════════════════════════
// ANALYTICS
// ═══════════════════════════════════════════════════════════════════════

/// Aggregated analytics snapshot for the analytics dashboard.
class AnalyticsSnapshot extends Equatable {
  final int totalViews;
  final int resumeDownloads;
  final int linkClicks;
  final List<DailyViewCount> dailyViews;
  final Map<String, double> countryDistribution;

  const AnalyticsSnapshot({
    required this.totalViews,
    required this.resumeDownloads,
    required this.linkClicks,
    required this.dailyViews,
    required this.countryDistribution,
  });

  @override
  List<Object?> get props => [
    totalViews,
    resumeDownloads,
    linkClicks,
    dailyViews,
    countryDistribution,
  ];
}

/// A single day's view count for charting.
class DailyViewCount extends Equatable {
  final DateTime date;
  final int views;

  const DailyViewCount({required this.date, required this.views});

  @override
  List<Object?> get props => [date, views];
}
