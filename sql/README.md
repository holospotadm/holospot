# 🗄️ SQL DIRECTORY STRUCTURE

This directory contains all SQL files for the HoloSpot gamification system, organized by purpose and functionality.

## 📁 DIRECTORY STRUCTURE

```
sql/
├── schema/          # Table definitions and structure
├── functions/       # Stored procedures and functions
├── triggers/        # Database triggers
├── migrations/      # Database migrations and updates
├── tests/          # Testing and verification scripts
├── backup/         # Database backups
├── fixes/          # Bug fixes and corrections
└── debug/          # Debug and investigation scripts
```

---

## 📊 SCHEMA (14 files)
**Complete database table definitions with indexes, constraints, and documentation**

### Core Tables
- `01_badges.sql` - Badge definitions and types
- `02_feedbacks.sql` - Feedback system (holofote mentions)
- `03_profiles.sql` - User profiles and basic info
- `04_posts.sql` - Main posts with holofote system
- `05_comments.sql` - Comments on posts
- `06_reactions.sql` - Reactions/likes on posts
- `07_follows.sql` - User follow relationships
- `08_notifications.sql` - System notifications (Fase 5)

### Gamification Tables
- `09_levels.sql` - Level definitions and progression
- `10_user_points.sql` - User total points and level tracking
- `11_user_badges.sql` - Badges earned by users
- `12_user_streaks.sql` - Detailed streak tracking system
- `13_points_history.sql` - Individual point transactions

### Debug Tables
- `14_debug_feedback_test.sql` - Debug table (temporary)

---

## ⚙️ FUNCTIONS (2 files)
**Stored procedures and utility functions**

- `all_notifications.sql` - Complete notification system functions
- `feedback_notification.sql` - Feedback-specific notification handling

---

## 🔄 MIGRATIONS (1 file)
**Database schema changes and updates**

- `001_fase5_sistema_notificacoes.sql` - Fase 5 notification system implementation

---

## 🧪 TESTS (1 file)
**Testing and verification scripts**

- `system_verification.sql` - Complete system verification and health checks

---

## 💾 BACKUP (1 file)
**Database backup files**

- `full_backup.sql` - Complete database backup

---

## 🔧 FIXES (13 files)
**Bug fixes and system corrections**

### Points System Fixes
- `fix_points_system_*.sql` - Various points system corrections
- `fix_points_DEFINITIVO.sql` - Final points system fix
- `fix_points_REAL_SOLUTION.sql` - Real solution for points issues
- `implement_points_history_fields.sql` - Points history implementation

### Trigger Fixes
- `fix_all_triggers_complete.sql` - Complete trigger system fixes
- `fix_post_creation_trigger.sql` - Post creation trigger fixes

### Permission Fixes
- `fix_rls_permissions.sql` - Row Level Security permission fixes

### Implementation Files
- `implement_option1_final.sql` - Final implementation option
- `implement_points_history_fields.sql` - Points history field implementation

---

## 🐛 DEBUG (2 files)
**Debug and investigation scripts**

- `debug_points_history.sql` - Points history debugging
- `investigate_posts_with_reactions.sql` - Posts and reactions investigation

---

## 🚀 DEPLOYMENT GUIDE

### **Fresh Installation**
1. **Schema**: Deploy all files in `schema/` directory in numerical order
2. **Functions**: Deploy all files in `functions/` directory
3. **Migrations**: Deploy files in `migrations/` directory chronologically
4. **Tests**: Run `tests/system_verification.sql` to verify installation

### **Updates and Fixes**
1. **Backup**: Always backup before applying fixes
2. **Fixes**: Apply relevant files from `fixes/` directory
3. **Verification**: Run tests to ensure fixes work correctly
4. **Debug**: Use `debug/` scripts if issues persist

### **Development**
1. **Schema Changes**: Create new migration files
2. **Function Updates**: Update files in `functions/` directory
3. **Testing**: Use `tests/` and `debug/` scripts for validation
4. **Backup**: Regular backups in `backup/` directory

---

## 📋 FILE NAMING CONVENTIONS

### **Schema Files**
- Format: `##_table_name.sql`
- Example: `01_badges.sql`, `10_user_points.sql`
- Numbered for deployment order

### **Migration Files**
- Format: `###_description.sql`
- Example: `001_fase5_sistema_notificacoes.sql`
- Chronological numbering

### **Fix Files**
- Format: `fix_description.sql`
- Example: `fix_points_system_final.sql`
- Descriptive names for the issue being fixed

### **Function Files**
- Format: `function_purpose.sql`
- Example: `all_notifications.sql`
- Descriptive of the function's purpose

---

## 🔍 QUICK REFERENCE

### **Find Schema for Table**
```bash
find schema/ -name "*table_name*"
```

### **Find Fixes for Issue**
```bash
find fixes/ -name "*issue_keyword*"
```

### **List All Functions**
```bash
ls functions/
```

### **Check Migration History**
```bash
ls migrations/ | sort
```

---

## ⚠️ IMPORTANT NOTES

### **Production Deployment**
- Always test in development first
- Backup before applying any changes
- Follow deployment order strictly
- Verify with test scripts after deployment

### **Development Guidelines**
- Document all changes thoroughly
- Use appropriate directory for file type
- Follow naming conventions
- Include rollback procedures for migrations

### **Maintenance**
- Regular backups in `backup/` directory
- Clean up debug files periodically
- Archive old fix files after verification
- Update documentation when structure changes

---

**📌 Each directory contains its own README with specific details!**
**📌 Always refer to individual files for complete implementation details!**

