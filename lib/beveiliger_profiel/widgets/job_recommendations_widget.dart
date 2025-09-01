import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';
import 'package:securyflex_app/marketplace/services/job_data_service.dart';
import 'package:securyflex_app/marketplace/services/certificate_matching_service.dart';
import 'package:securyflex_app/beveiliger_profiel/models/specialization.dart';

/// Job Recommendations Widget with marketplace integration
/// 
/// MANDATORY: Use UnifiedCard.standard for recommendation container
/// MANDATORY: Use existing job card components from marketplace
/// MANDATORY: Use existing job matching service integration
/// Display recommended jobs based on selected specializations
/// "Bekijk alle jobs" link to marketplace with pre-applied filters
/// Integration with existing job application flow
class JobRecommendationsWidget extends StatefulWidget {
  /// User ID for personalized recommendations
  final String userId;
  
  /// User role for theming
  final UserRole userRole;
  
  /// User's selected specializations for matching
  final List<Specialization> specializations;
  
  /// User's certificates for job matching
  final List<String> userCertificates;
  
  /// Maximum number of recommendations to show
  final int maxRecommendations;
  
  /// Whether to show skill-level based filtering
  final bool useSkillLevelFiltering;
  
  /// Callback when user navigates to job details
  final Function(SecurityJobData)? onJobTapped;
  
  /// Callback when user navigates to marketplace
  final VoidCallback? onViewAllJobsTapped;

  const JobRecommendationsWidget({
    super.key,
    required this.userId,
    this.userRole = UserRole.guard,
    required this.specializations,
    this.userCertificates = const [],
    this.maxRecommendations = 5,
    this.useSkillLevelFiltering = true,
    this.onJobTapped,
    this.onViewAllJobsTapped,
  });

  @override
  State<JobRecommendationsWidget> createState() => _JobRecommendationsWidgetState();
}

class _JobRecommendationsWidgetState extends State<JobRecommendationsWidget>
    with AutomaticKeepAliveClientMixin {
  
  // Services
  
  // State
  List<SecurityJobData> _recommendedJobs = [];
  List<JobRecommendationMatch> _jobMatches = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Cache
  DateTime? _lastLoadTime;
  static const Duration _cacheValidDuration = Duration(minutes: 10);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadJobRecommendations();
  }

  @override
  void didUpdateWidget(JobRecommendationsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reload if specializations changed
    if (oldWidget.specializations.length != widget.specializations.length ||
        !_listEquals(oldWidget.specializations.map((s) => s.type).toList(),
                    widget.specializations.map((s) => s.type).toList())) {
      _loadJobRecommendations();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (widget.specializations.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return UnifiedCard.standard(
      userRole: widget.userRole,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colorScheme),
          
          SizedBox(height: DesignTokens.spacingM),
          
          if (_isLoading)
            _buildLoadingState(colorScheme)
          else if (_errorMessage != null)
            _buildErrorState(colorScheme)
          else if (_recommendedJobs.isEmpty)
            _buildEmptyState(colorScheme)
          else
            _buildRecommendationsContent(colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          Icons.work_history,
          size: DesignTokens.iconSizeM,
          color: colorScheme.primary,
        ),
        SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aanbevolen Jobs',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeSubtitle,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (widget.specializations.isNotEmpty)
                Text(
                  'Gebaseerd op ${widget.specializations.length} specialisatie${widget.specializations.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (_recommendedJobs.isNotEmpty)
          UnifiedButton.text(
            text: 'Bekijk alle jobs',
            onPressed: _navigateToMarketplace,
          ),
      ],
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Column(
      children: [
        SizedBox(height: DesignTokens.spacingL),
        Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3.0,
              ),
              SizedBox(height: DesignTokens.spacingM),
              Text(
                'Zoeken naar passende jobs...',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: DesignTokens.spacingL),
      ],
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: DesignTokens.iconSizeXL,
            color: colorScheme.error,
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Fout bij laden aanbevelingen',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            _errorMessage ?? 'Onbekende fout opgetreden',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spacingM),
          UnifiedButton.primary(
            text: 'Opnieuw proberen',
            onPressed: _loadJobRecommendations,
            size: UnifiedButtonSize.small,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        children: [
          Icon(
            Icons.work_off,
            size: DesignTokens.iconSizeXL,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Geen passende jobs gevonden',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Probeer je specialisaties uit te breiden of bekijk alle beschikbare jobs.',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spacingM),
          UnifiedButton.primary(
            text: 'Bekijk alle jobs',
            onPressed: _navigateToMarketplace,
            size: UnifiedButtonSize.small,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsContent(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Match statistics
        _buildMatchStatistics(colorScheme),
        
        SizedBox(height: DesignTokens.spacingM),
        
        // Job recommendations list
        ..._jobMatches.take(widget.maxRecommendations).map((jobMatch) => 
          Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
            child: _buildJobRecommendationCard(jobMatch, colorScheme),
          ),
        ),
        
        if (_jobMatches.length > widget.maxRecommendations) ...[
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: colorScheme.onPrimaryContainer,
                  size: DesignTokens.iconSizeS,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: Text(
                    '+${_jobMatches.length - widget.maxRecommendations} meer passende jobs beschikbaar',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                ),
                UnifiedButton.text(
                  text: 'Bekijk alle',
                  onPressed: _navigateToMarketplace,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMatchStatistics(ColorScheme colorScheme) {
    final perfectMatches = _jobMatches.where((match) => match.matchScore >= 90).length;
    final goodMatches = _jobMatches.where((match) => match.matchScore >= 70 && match.matchScore < 90).length;
    final totalJobs = _jobMatches.length;
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              '$perfectMatches',
              'Perfect',
              Icons.star,
              DesignTokens.colorSuccess,
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: colorScheme.outline,
            margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
          ),
          Expanded(
            child: _buildStatItem(
              '$goodMatches',
              'Goed',
              Icons.thumb_up,
              DesignTokens.colorWarning,
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: colorScheme.outline,
            margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
          ),
          Expanded(
            child: _buildStatItem(
              '$totalJobs',
              'Totaal',
              Icons.work,
              colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeS,
          color: color,
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Text(
          value,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightBold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeCaption,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildJobRecommendationCard(JobRecommendationMatch jobMatch, ColorScheme colorScheme) {
    final job = jobMatch.job;
    
    return GestureDetector(
      onTap: () => _handleJobTapped(job),
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [DesignTokens.shadowLight],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job header with match score
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.jobTitle,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeBody,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: DesignTokens.spacingXS),
                      Text(
                        '${job.companyName} • ${job.location}',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeCaption,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: DesignTokens.spacingS),
                
                // Match score badge
                _buildMatchScoreBadge(jobMatch.matchScore, colorScheme),
              ],
            ),
            
            SizedBox(height: DesignTokens.spacingM),
            
            // Job details
            Row(
              children: [
                Icon(
                  Icons.euro,
                  size: DesignTokens.iconSizeS,
                  color: colorScheme.primary,
                ),
                SizedBox(width: DesignTokens.spacingXS),
                Text(
                  '€${job.hourlyRate.toStringAsFixed(2)}/uur',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: colorScheme.primary,
                  ),
                ),
                
                SizedBox(width: DesignTokens.spacingM),
                
                Icon(
                  Icons.schedule,
                  size: DesignTokens.iconSizeS,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: DesignTokens.spacingXS),
                Text(
                  '${job.duration}h',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                
                SizedBox(width: DesignTokens.spacingM),
                
                Icon(
                  Icons.location_on,
                  size: DesignTokens.iconSizeS,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: DesignTokens.spacingXS),
                Text(
                  '${job.distance.toStringAsFixed(1)}km',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            // Match reasons
            if (jobMatch.matchReasons.isNotEmpty) ...[
              SizedBox(height: DesignTokens.spacingM),
              Wrap(
                spacing: DesignTokens.spacingS,
                runSpacing: DesignTokens.spacingXS,
                children: jobMatch.matchReasons.take(3).map((reason) => 
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingS,
                      vertical: DesignTokens.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ],
            
            // Certificate match indicator
            if (job.requiredCertificates.isNotEmpty) ...[
              SizedBox(height: DesignTokens.spacingS),
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    size: DesignTokens.iconSizeS,
                    color: jobMatch.certificateMatchResult.isEligible 
                        ? DesignTokens.colorSuccess 
                        : DesignTokens.colorWarning,
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    jobMatch.certificateMatchResult.isEligible 
                        ? 'Gekwalificeerd' 
                        : 'Extra certificaten vereist',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: jobMatch.certificateMatchResult.isEligible 
                          ? DesignTokens.colorSuccess 
                          : DesignTokens.colorWarning,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchScoreBadge(int matchScore, ColorScheme colorScheme) {
    Color badgeColor;
    String badgeText;
    
    if (matchScore >= 90) {
      badgeColor = DesignTokens.colorSuccess;
      badgeText = 'Perfect';
    } else if (matchScore >= 70) {
      badgeColor = DesignTokens.colorWarning;
      badgeText = 'Goed';
    } else if (matchScore >= 50) {
      badgeColor = DesignTokens.colorInfo;
      badgeText = 'Redelijk';
    } else {
      badgeColor = DesignTokens.colorGray500;
      badgeText = 'Beperkt';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$matchScore%',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: DesignTokens.fontWeightBold,
              color: DesignTokens.colorWhite,
            ),
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 10,
              color: DesignTokens.colorWhite,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods

  bool _listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  Future<void> _loadJobRecommendations() async {
    // Check cache validity
    if (_lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration &&
        _recommendedJobs.isNotEmpty) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get all available jobs
      final allJobs = await JobDataService.getAvailableJobs(limit: 100);
      
      // Calculate job matches based on specializations
      final jobMatches = <JobRecommendationMatch>[];
      
      for (final job in allJobs) {
        final matchScore = _calculateJobMatchScore(job);
        
        if (matchScore >= 30) { // Only include jobs with reasonable match
          final certificateMatch = CertificateMatchingService.matchCertificates(
            widget.userCertificates,
            job.requiredCertificates,
          );
          
          final matchReasons = _generateMatchReasons(job, matchScore);
          
          jobMatches.add(JobRecommendationMatch(
            job: job,
            matchScore: matchScore,
            matchReasons: matchReasons,
            certificateMatchResult: certificateMatch,
          ));
        }
      }
      
      // Sort by match score and certificate eligibility
      jobMatches.sort((a, b) {
        // Prioritize eligible jobs
        if (a.certificateMatchResult.isEligible && !b.certificateMatchResult.isEligible) {
          return -1;
        } else if (!a.certificateMatchResult.isEligible && b.certificateMatchResult.isEligible) {
          return 1;
        }
        
        // Then by match score
        return b.matchScore.compareTo(a.matchScore);
      });
      
      setState(() {
        _jobMatches = jobMatches;
        _recommendedJobs = jobMatches.map((match) => match.job).toList();
        _lastLoadTime = DateTime.now();
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _calculateJobMatchScore(SecurityJobData job) {
    int score = 0;
    int factors = 0;
    
    // Check specialization matches
    for (final specialization in widget.specializations) {
      if (specialization.matchesJobCategory(job.jobType)) {
        // Base score for specialization match
        score += 40;
        factors++;
        
        // Bonus for skill level
        switch (specialization.skillLevel) {
          case SkillLevel.expert:
            score += 20;
            break;
          case SkillLevel.ervaren:
            score += 10;
            break;
          case SkillLevel.beginner:
            score += 5;
            break;
        }
        
        // Higher rated companies get bonus
        if (job.companyRating >= 4.5) {
          score += 10;
        }
        
        // Break after first match to avoid double counting
        break;
      }
    }
    
    // If no specialization match, check for related matches
    if (factors == 0) {
      for (final specialization in widget.specializations) {
        final relatedTypes = specialization.type.relatedSpecializations;
        for (final relatedType in relatedTypes) {
          if (relatedType.matchesJobCategory(job.jobType)) {
            score += 25; // Lower score for related matches
            factors++;
            break;
          }
        }
        if (factors > 0) break;
      }
    }
    
    // Additional scoring factors
    factors++;
    
    // Distance bonus (closer is better)
    if (job.distance <= 5) {
      score += 15;
    } else if (job.distance <= 15) {
      score += 10;
    } else if (job.distance <= 25) {
      score += 5;
    }
    
    // Hourly rate consideration
    if (job.hourlyRate >= 25) {
      score += 10;
    } else if (job.hourlyRate >= 20) {
      score += 5;
    }
    
    // Company rating bonus
    if (job.companyRating >= 4.5) {
      score += 5;
    } else if (job.companyRating >= 4.0) {
      score += 3;
    }
    
    // Certificate match bonus
    if (widget.userCertificates.isNotEmpty && job.requiredCertificates.isNotEmpty) {
      final certMatch = CertificateMatchingService.calculateCompatibilityScore(
        widget.userCertificates,
        job.requiredCertificates,
      );
      score += (certMatch * 0.2).round(); // 20% of certificate match score
    }
    
    return (score / (factors > 0 ? 1 : 1)).clamp(0, 100).round();
  }

  List<String> _generateMatchReasons(SecurityJobData job, int matchScore) {
    final reasons = <String>[];
    
    // Check for specialization matches
    for (final specialization in widget.specializations) {
      if (specialization.matchesJobCategory(job.jobType)) {
        reasons.add('${specialization.displayName} specialisatie');
        
        if (specialization.skillLevel == SkillLevel.expert) {
          reasons.add('Expert niveau');
        } else if (specialization.skillLevel == SkillLevel.ervaren) {
          reasons.add('Ervaren niveau');
        }
        break;
      }
    }
    
    // Distance reason
    if (job.distance <= 5) {
      reasons.add('Dichtbij (${job.distance.toStringAsFixed(1)}km)');
    }
    
    // High pay reason
    if (job.hourlyRate >= 25) {
      reasons.add('Goed betaald (€${job.hourlyRate.toStringAsFixed(2)}/uur)');
    }
    
    // Good company rating
    if (job.companyRating >= 4.5) {
      reasons.add('Top werkgever (${job.companyRating}⭐)');
    }
    
    // Certificate eligibility
    if (widget.userCertificates.isNotEmpty && job.requiredCertificates.isNotEmpty) {
      final certMatch = CertificateMatchingService.matchCertificates(
        widget.userCertificates,
        job.requiredCertificates,
      );
      if (certMatch.isEligible) {
        reasons.add('Voldoet aan certificaat-eisen');
      }
    }
    
    return reasons;
  }

  void _handleJobTapped(SecurityJobData job) {
    widget.onJobTapped?.call(job);
  }

  void _navigateToMarketplace() {
    // Create filter based on user's specializations
    final specializationTypes = widget.specializations
        .map((s) => s.type.displayName)
        .toList();
    
    // In a real implementation, this would navigate to marketplace with pre-applied filters
    widget.onViewAllJobsTapped?.call();
    
    // For demo purposes, just show a message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigeren naar marketplace met filters: ${specializationTypes.join(", ")}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Job recommendation match result
class JobRecommendationMatch {
  final SecurityJobData job;
  final int matchScore;
  final List<String> matchReasons;
  final CertificateMatchResult certificateMatchResult;
  
  const JobRecommendationMatch({
    required this.job,
    required this.matchScore,
    required this.matchReasons,
    required this.certificateMatchResult,
  });
}

