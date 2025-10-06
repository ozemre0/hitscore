# 🎯 Multi-User Participation System

## Overview

This update allows all user types (athletes, coaches, officials, etc.) to participate in competitions, not just athletes. The system now uses a more flexible approach where any user can join competitions regardless of their role.

## 🔄 Changes Made

### 1. Database Schema Changes

**Before:**
- `organized_competition_participants` table only had `athlete_id`
- Only users with "athlete" role could participate

**After:**
- Added `user_id` field (references any user)
- Added `participant_role` field (tracks what role they're participating as)
- All user types can now participate

### 2. Code Changes

#### Updated Files:
- `lib/screens/participant_competitions_screen.dart`
- `lib/screens/organized/competition_participants_screen.dart`
- `lib/screens/organized/athlete_multi_select_sheet.dart` → `UserMultiSelectSheet`
- `lib/providers/profile_providers.dart`

#### Key Changes:
- All queries now use `user_id` instead of `athlete_id`
- Added `participant_role` field to track user's role in competition
- Updated UI to display role information
- Renamed components to be more generic (UserMultiSelectSheet)

### 3. Localization Updates

Added new localization keys:
- `athlete`: "Athlete" / "Sporcu"
- `coach`: "Coach" / "Antrenör"

## 🚀 Migration Steps

### 1. Database Migration

Run the SQL migration script:
```sql
-- See database_migration.sql for complete migration
```

### 2. Code Deployment

1. Deploy the updated code
2. Run `flutter gen-l10n` to update localizations
3. Test with different user roles

### 3. Verification

Check that:
- [ ] Athletes can still participate
- [ ] Coaches can participate
- [ ] UI shows role information correctly
- [ ] All existing data is preserved

## 📊 New Data Structure

### organized_competition_participants Table

| Field | Type | Description |
|-------|------|-------------|
| participant_id | UUID | Primary key |
| user_id | UUID | References profiles(id) - any user type |
| participant_role | VARCHAR(20) | Role in competition (athlete, coach, etc.) |
| organized_competition_id | UUID | Competition reference |
| classification_id | UUID | Classification reference |
| status | VARCHAR(20) | pending, accepted, cancelled |
| visible_id | VARCHAR | Display ID |
| first_name | VARCHAR | User's first name |
| last_name | VARCHAR | User's last name |
| created_at | TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | Last update time |

## 🎨 UI Changes

### Participant List
- Shows role badge for non-athletes
- Displays "Coach" or other role names
- Maintains all existing functionality

### User Selection
- Renamed from "Add Athletes" to "Add Users"
- Shows all user types, not just athletes
- Maintains search and filter functionality

## 🔧 Configuration

### Supported Roles
The system supports these participant roles:
- `athlete` (default)
- `coach`
- `official`
- `admin`

### Role Display
- Athletes: No special badge (default)
- Coaches: Shows "Coach" badge
- Other roles: Shows role name

## 🧪 Testing

### Test Cases
1. **Athlete Participation**
   - Athlete joins competition
   - Shows as regular participant
   - Can enter scores

2. **Coach Participation**
   - Coach joins competition
   - Shows "Coach" badge
   - Can enter scores

3. **Mixed Participation**
   - Competition with both athletes and coaches
   - All participants visible in list
   - Role badges displayed correctly

## 🚨 Important Notes

### Backward Compatibility
- All existing data is preserved
- Old `athlete_id` field kept for safety
- Can be removed after thorough testing

### Performance
- Added indexes for better query performance
- No impact on existing functionality

### Security
- Same permission system applies
- Users can only see their own participations
- Competition organizers can manage all participants

## 🔄 Rollback Plan

If issues arise:
1. Revert code changes
2. Keep database changes (they're additive)
3. Old `athlete_id` field still works
4. No data loss

## 📈 Future Enhancements

1. **Role-specific Features**
   - Different permissions per role
   - Role-specific UI elements
   - Custom scoring rules per role

2. **Advanced Role Management**
   - Custom role definitions
   - Role-based competition access
   - Hierarchical permissions

3. **Analytics**
   - Participation statistics by role
   - Role-based performance metrics
   - Competition diversity metrics
