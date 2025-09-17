# 📊 DATABASE SCHEMA FILES

This directory contains the complete database schema for the HoloSpot gamification system, organized by table with comprehensive documentation.

## 📋 TABLE OVERVIEW

### **Core System Tables (8)**
| File | Table | Description | Dependencies |
|------|-------|-------------|--------------|
| `01_badges.sql` | `badges` | Badge definitions and types | None |
| `02_feedbacks.sql` | `feedbacks` | Feedback system (holofote mentions) | profiles, posts |
| `03_profiles.sql` | `profiles` | User profiles and basic info | None (base table) |
| `04_posts.sql` | `posts` | Main posts with holofote system | profiles |
| `05_comments.sql` | `comments` | Comments on posts | profiles, posts |
| `06_reactions.sql` | `reactions` | Reactions/likes on posts | profiles, posts |
| `07_follows.sql` | `follows` | User follow relationships | profiles |
| `08_notifications.sql` | `notifications` | System notifications (Fase 5) | profiles |

### **Gamification Tables (5)**
| File | Table | Description | Dependencies |
|------|-------|-------------|--------------|
| `09_levels.sql` | `levels` | Level definitions and progression | None (reference table) |
| `10_user_points.sql` | `user_points` | User total points and level tracking | profiles, levels |
| `11_user_badges.sql` | `user_badges` | Badges earned by users | profiles, badges |
| `12_user_streaks.sql` | `user_streaks` | Detailed streak tracking system | profiles |
| `13_points_history.sql` | `points_history` | Individual point transactions | profiles |

### **Debug/Temporary Tables (1)**
| File | Table | Description | Status |
|------|-------|-------------|--------|
| `14_debug_feedback_test.sql` | `debug_feedback_test` | Debug table for testing | ⚠️ TEMPORARY |

---

## 🔗 RELATIONSHIP DIAGRAM

```
profiles (base)
├── posts
│   ├── comments
│   ├── reactions
│   └── feedbacks
├── follows
├── notifications
├── user_points ──→ levels
├── user_badges ──→ badges
├── user_streaks
└── points_history
```

---

## 📚 SCHEMA FEATURES

### **🔒 Security Features**
- **Row Level Security (RLS)** enabled on all tables
- **SECURITY DEFINER** functions for safe operations
- **Proper foreign key constraints** with cascade options
- **Input validation** with CHECK constraints

### **⚡ Performance Features**
- **Comprehensive indexing** for all common queries
- **Composite indexes** for complex queries
- **Optimized functions** with proper query plans
- **Efficient data types** (UUID, TIMESTAMPTZ, etc.)

### **🎯 Gamification Features**
- **Automatic point calculation** with triggers
- **Badge auto-awarding** based on achievements
- **Streak tracking** with milestone bonuses
- **Level progression** with point thresholds
- **Anti-spam protection** for notifications

### **📊 Analytics Features**
- **Points history tracking** for detailed analytics
- **Leaderboard functions** for rankings
- **Statistics functions** for user insights
- **Consistency validation** functions

---

## 🚀 DEPLOYMENT ORDER

When deploying to a new database, execute schema files in this order:

### **Phase 1: Base Tables**
1. `03_profiles.sql` - User profiles (base table)
2. `09_levels.sql` - Level definitions
3. `01_badges.sql` - Badge definitions

### **Phase 2: Content Tables**
4. `04_posts.sql` - Posts with holofote system
5. `05_comments.sql` - Comments on posts
6. `06_reactions.sql` - Reactions on posts
7. `02_feedbacks.sql` - Feedback system
8. `07_follows.sql` - Follow relationships

### **Phase 3: System Tables**
9. `08_notifications.sql` - Notification system
10. `13_points_history.sql` - Points transaction history
11. `10_user_points.sql` - User points and levels
12. `11_user_badges.sql` - User badge awards
13. `12_user_streaks.sql` - Streak tracking

### **Phase 4: Debug Tables (Optional)**
14. `14_debug_feedback_test.sql` - Debug table (development only)

---

## 🔧 MAINTENANCE

### **Regular Tasks**
- Run `cleanup_old_notifications()` monthly
- Validate points consistency with `validate_user_points_consistency()`
- Monitor table sizes and index usage
- Clean up debug tables in production

### **Monitoring Queries**
```sql
-- Check table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables WHERE schemaname = 'public' ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes ORDER BY idx_scan DESC;

-- Check function performance
SELECT schemaname, funcname, calls, total_time, mean_time
FROM pg_stat_user_functions ORDER BY total_time DESC;
```

---

## 📖 DOCUMENTATION

Each schema file includes:
- **Complete table definition** with all columns and constraints
- **Comprehensive indexing** for performance
- **Row Level Security policies** for data protection
- **Helper functions** for common operations
- **Detailed comments** explaining purpose and usage
- **Relationship documentation** with other tables

---

## ⚠️ IMPORTANT NOTES

### **Data Integrity**
- All foreign keys use appropriate CASCADE options
- CHECK constraints validate data ranges
- UNIQUE constraints prevent duplicates
- NOT NULL constraints ensure required data

### **Performance Considerations**
- Indexes are optimized for common query patterns
- Functions use SECURITY DEFINER for RLS bypass
- Composite indexes support complex queries
- Proper data types minimize storage overhead

### **Security Considerations**
- RLS policies restrict data access appropriately
- Functions validate input parameters
- Sensitive operations require proper authentication
- Debug tables should not exist in production

---

**📌 Always refer to individual schema files for complete implementation details!**
**📌 Test all changes in development environment before production deployment!**

