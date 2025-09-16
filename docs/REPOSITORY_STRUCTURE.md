# 🏗️ REPOSITORY STRUCTURE - HoloSpot Gamification System

**Complete GitHub repository organization for the HoloSpot gamification system**

---

## 📁 ROOT DIRECTORY STRUCTURE

```
holospot/
├── README.md                    # Main project documentation
├── docs/                        # Documentation directory
│   ├── ESTADO_ATUAL.md         # Current system state
│   ├── DATABASE_SCHEMA_REAL.md # Real database schema documentation
│   ├── CHANGELOG.md            # Version history and changes
│   └── REPOSITORY_STRUCTURE.md # This file
├── sql/                        # All SQL files organized by purpose
│   ├── README.md               # SQL directory guide
│   ├── schema/                 # Table definitions (14 files)
│   ├── functions/              # Stored procedures
│   ├── migrations/             # Database migrations
│   ├── tests/                  # Testing scripts
│   ├── backup/                 # Database backups
│   ├── fixes/                  # Bug fixes and corrections
│   └── debug/                  # Debug and investigation scripts
├── frontend/                   # Frontend application files (if applicable)
├── backend/                    # Backend application files (if applicable)
└── assets/                     # Images, icons, and other assets
```

---

## 📚 DOCUMENTATION (`docs/`)

### **Core Documentation Files**
| File | Purpose | Status |
|------|---------|--------|
| `ESTADO_ATUAL.md` | Current system state and active components | ✅ Complete |
| `DATABASE_SCHEMA_REAL.md` | Real database structure (extracted from DB) | ✅ Complete |
| `CHANGELOG.md` | Version history and major changes | ✅ Complete |
| `REPOSITORY_STRUCTURE.md` | This file - repository organization | ✅ Complete |

### **Planned Documentation**
| File | Purpose | Status |
|------|---------|--------|
| `API_DOCUMENTATION.md` | API endpoints and usage | 📋 Planned |
| `DEPLOYMENT_GUIDE.md` | Production deployment instructions | 📋 Planned |
| `DEVELOPMENT_SETUP.md` | Local development environment setup | 📋 Planned |
| `TROUBLESHOOTING.md` | Common issues and solutions | 📋 Planned |

---

## 🗄️ SQL DIRECTORY (`sql/`)

### **Schema Files (`sql/schema/`) - 15 files**
**Complete table definitions with indexes, constraints, and documentation**

#### Core System Tables (8)
- `01_badges.sql` - Badge definitions and types
- `02_feedbacks.sql` - Feedback system (holofote mentions)
- `03_profiles.sql` - User profiles and basic info
- `04_posts.sql` - Main posts with holofote system
- `05_comments.sql` - Comments on posts
- `06_reactions.sql` - Reactions/likes on posts
- `07_follows.sql` - User follow relationships
- `08_notifications.sql` - System notifications (Fase 5)

#### Gamification Tables (5)
- `09_levels.sql` - Level definitions and progression
- `10_user_points.sql` - User total points and level tracking
- `11_user_badges.sql` - Badges earned by users
- `12_user_streaks.sql` - Detailed streak tracking system
- `13_points_history.sql` - Individual point transactions

#### Debug Tables (1)
- `14_debug_feedback_test.sql` - Debug table (temporary)

#### Documentation
- `README.md` - Schema directory guide and deployment order

### **Functions (`sql/functions/`) - 2 files**
- `all_notifications.sql` - Complete notification system functions
- `feedback_notification.sql` - Feedback-specific notification handling

### **Migrations (`sql/migrations/`) - 1 file**
- `001_fase5_sistema_notificacoes.sql` - Fase 5 notification system

### **Tests (`sql/tests/`) - 1 file**
- `system_verification.sql` - Complete system verification

### **Backup (`sql/backup/`) - 1 file**
- `full_backup.sql` - Complete database backup

### **Fixes (`sql/fixes/`) - 13 files**
- Various bug fixes and system corrections
- Points system fixes
- Trigger fixes
- Permission fixes

### **Debug (`sql/debug/`) - 2 files**
- Debug and investigation scripts
- Points history debugging
- Posts and reactions investigation

---

## 🎯 SYSTEM COMPONENTS

### **Database Tables (14 total)**
| Category | Count | Tables |
|----------|-------|--------|
| **Core Tables** | 9 | badges, comments, feedbacks, follows, notifications, points_history, posts, profiles, reactions |
| **Gamification** | 4 | user_badges, user_points, user_streaks, levels |
| **Debug** | 1 | debug_feedback_test |

### **Key Features Implemented**
- ✅ **Complete Gamification System** (Fase 4)
- ✅ **Notification System** (Fase 5)
- ✅ **Points and Levels** with automatic progression
- ✅ **Badge System** with auto-awarding
- ✅ **Streak Tracking** with milestone bonuses
- ✅ **Anti-spam Protection** for notifications
- ✅ **Row Level Security** (RLS) on all tables
- ✅ **Comprehensive Indexing** for performance

---

## 🚀 DEPLOYMENT WORKFLOW

### **Fresh Installation**
1. **Database Setup**
   ```bash
   # Deploy schema files in order
   psql -f sql/schema/01_badges.sql
   psql -f sql/schema/02_feedbacks.sql
   # ... continue with all schema files
   ```

2. **Functions and Procedures**
   ```bash
   # Deploy function files
   psql -f sql/functions/all_notifications.sql
   psql -f sql/functions/feedback_notification.sql
   ```

3. **Migrations**
   ```bash
   # Apply migrations chronologically
   psql -f sql/migrations/001_fase5_sistema_notificacoes.sql
   ```

4. **Verification**
   ```bash
   # Run system verification
   psql -f sql/tests/system_verification.sql
   ```

### **Updates and Fixes**
1. **Backup First**
   ```bash
   pg_dump database_name > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Apply Fixes**
   ```bash
   # Apply relevant fix files
   psql -f sql/fixes/fix_specific_issue.sql
   ```

3. **Verify Changes**
   ```bash
   # Run verification tests
   psql -f sql/tests/system_verification.sql
   ```

---

## 📊 CURRENT STATUS

### **✅ Completed Components**
- **Database Schema**: 14 tables fully documented
- **Gamification System**: Points, levels, badges, streaks
- **Notification System**: Anti-spam, grouping, standardized messages
- **Security**: RLS policies, SECURITY DEFINER functions
- **Performance**: Comprehensive indexing, optimized queries
- **Documentation**: Real schema extracted and documented

### **🔄 In Progress**
- **Repository Organization**: Ongoing file organization
- **Documentation**: Expanding API and deployment docs
- **Testing**: Additional test coverage

### **📋 Planned**
- **Frontend Integration**: Connect with gamification backend
- **API Documentation**: Complete endpoint documentation
- **Deployment Automation**: CI/CD pipeline setup
- **Monitoring**: Performance and health monitoring

---

## 🔧 MAINTENANCE GUIDELINES

### **Regular Tasks**
- **Weekly**: Run system verification tests
- **Monthly**: Clean up old notifications and debug data
- **Quarterly**: Review and optimize database performance
- **As Needed**: Apply fixes and updates from `sql/fixes/`

### **File Organization Rules**
1. **Schema Changes**: Always create migration files
2. **Bug Fixes**: Document in `sql/fixes/` with descriptive names
3. **New Features**: Update schema files and create migrations
4. **Testing**: Add verification scripts to `sql/tests/`
5. **Documentation**: Update relevant docs when making changes

### **Version Control**
- **Commit Messages**: Use descriptive messages with component tags
- **Branching**: Use feature branches for major changes
- **Tagging**: Tag stable releases with version numbers
- **Documentation**: Update CHANGELOG.md for all releases

---

## 📖 DOCUMENTATION STANDARDS

### **SQL Files**
- **Header Comments**: Purpose, dependencies, relationships
- **Function Documentation**: Parameters, return values, examples
- **Table Comments**: Column descriptions and constraints
- **Index Documentation**: Purpose and query patterns

### **Markdown Files**
- **Clear Structure**: Use headers and sections consistently
- **Status Indicators**: ✅ Complete, 🔄 In Progress, 📋 Planned
- **Code Examples**: Include relevant SQL and bash examples
- **Cross-References**: Link to related files and sections

---

## ⚠️ IMPORTANT NOTES

### **Production Considerations**
- **Never deploy debug tables** to production
- **Always backup** before applying changes
- **Test thoroughly** in development environment
- **Monitor performance** after schema changes

### **Development Guidelines**
- **Follow naming conventions** for consistency
- **Document all changes** thoroughly
- **Use appropriate directories** for file organization
- **Include rollback procedures** for migrations

### **Security Considerations**
- **RLS policies** must be properly configured
- **Function security** should use SECURITY DEFINER appropriately
- **Input validation** must be implemented in all functions
- **Access controls** should be regularly reviewed

---

**📌 This repository structure ensures maintainable, scalable, and well-documented code!**
**📌 Always refer to individual README files in each directory for specific details!**
**📌 Keep this document updated as the repository structure evolves!**

