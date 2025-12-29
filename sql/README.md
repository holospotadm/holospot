# Estrutura SQL - HoloSpot

Documentação técnica da estrutura do banco de dados PostgreSQL (Supabase).

---

## Estrutura de Diretórios

```
sql/
├── schema/          # 21 arquivos - Definições de tabelas (CREATE TABLE)
├── functions/       # 158 arquivos - Funções PL/pgSQL
├── triggers/        # 13 arquivos - Triggers agrupados por tabela
├── constraints/     # 21 arquivos - Constraints agrupados por tabela
├── policies/        # 21 arquivos - Policies RLS agrupadas por tabela
└── migrations/      # Migrações incrementais
```

---

## Schema (Tabelas)

Diretório: `sql/schema/`

| Arquivo | Tabela |
|---------|--------|
| `01_badges.sql` | badges |
| `02_chain_posts.sql` | chain_posts |
| `03_chains.sql` | chains |
| `04_comments.sql` | comments |
| `05_communities.sql` | communities |
| `06_community_members.sql` | community_members |
| `07_conversations.sql` | conversations |
| `08_feedbacks.sql` | feedbacks |
| `09_follows.sql` | follows |
| `10_invites.sql` | invites |
| `11_levels.sql` | levels |
| `12_messages.sql` | messages |
| `13_notifications.sql` | notifications |
| `14_points_history.sql` | points_history |
| `15_posts.sql` | posts |
| `16_profiles.sql` | profiles |
| `17_reactions.sql` | reactions |
| `18_user_badges.sql` | user_badges |
| `19_user_points.sql` | user_points |
| `20_user_streaks.sql` | user_streaks |
| `21_waitlist.sql` | waitlist |

---

## Functions

Diretório: `sql/functions/`

158 funções organizadas em arquivos individuais. Funções com overload (mesma função, parâmetros diferentes) são nomeadas com sufixo `_v2`, `_v3`, etc.

<details>
<summary>Lista completa de funções (clique para expandir)</summary>

```
add_community_member
add_community_member_v2
add_points_secure
add_points_to_user
add_points_to_user_v2
add_points_to_user_v3
add_post_to_chain
apply_streak_bonus_retroactive
auto_badge_check_bonus
auto_check_badges_after_action
auto_check_badges_with_bonus_after_action
auto_group_all_notifications
auto_group_recent_notifications
award_first_community_post_badge
calculate_holospot_index
calculate_streak_bonus
calculate_streak_bonus_v2
calculate_user_level
calculate_user_streak
cancel_chain
check_and_award_badges
check_and_grant_badges
check_and_grant_badges_with_bonus
check_chain_creation_badges
check_chain_participation_badges
check_notification_spam
check_points_before_deletion
check_username_availability
cleanup_old_notifications
close_chain
count_user_created_chains
count_user_participated_chains
count_user_referrals
create_chain
create_community
create_notification_no_duplicates
create_notification_no_duplicates_v2
create_notification_smart
create_notification_smart_v2
create_notification_ultra_safe
create_notification_ultra_safe_v2
create_notification_with_strict_antispam
create_notification_with_strict_antispam_v2
create_single_notification
create_test_data
debug_streak_bonus
delete_reaction_points_secure
extrair_estado_completo_banco
extrair_sistema_streak_completo
generate_username_from_email
get_badge_bonus_points
get_chain_info
get_chain_participants_count
get_chain_tree
get_community_feed
get_feed_posts
get_global_ranking
get_next_milestone
get_notification_system_stats
get_notification_threshold
get_or_create_conversation
get_points_last_days
get_previous_milestone
get_streak_statistics
get_user_gamification_data
get_user_participation_depth
get_user_streak
get_user_streak_data
get_user_streak_info
group_reaction_notifications
group_similar_notifications
handle_badge_notification_definitive
handle_badge_notification_only
handle_comment
handle_comment_delete_secure
handle_comment_insert_secure
handle_comment_notification
handle_comment_notification_correto
handle_comment_notification_definitive
handle_comment_notification_only
handle_comment_notification_unique
handle_feedback_insert_secure
handle_feedback_notification
handle_feedback_notification_correto
handle_feedback_notification_debug
handle_feedback_notification_definitive
handle_feedback_notification_simple
handle_follow_notification
handle_follow_notification_correto
handle_gamification_notification_definitive
handle_holofote_notification
handle_level_up_notification
handle_mention_notification_correto
handle_new_user
handle_post_insert_secure
handle_reaction_delete_secure
handle_reaction_insert_secure
handle_reaction_notification
handle_reaction_notification_correto
handle_reaction_notification_definitive
handle_reaction_notification_final
handle_reaction_notification_holofote
handle_reaction_notification_only
handle_reaction_notification_smart
handle_reaction_notification_unique
handle_reaction_points_only
handle_reaction_points_simple
handle_reaction_simple
handle_streak_notification_only
initialize_user_points
insert_notification_safe
mark_all_notifications_read
migrate_existing_users_to_gamification
notify_badge_earned
notify_badge_earned_definitive
notify_badge_trigger
notify_comment_smart
notify_feedback_smart
notify_gamification_trigger
notify_level_up
notify_level_up_definitive
notify_point_milestone
notify_point_milestone_definitive
notify_reaction_smart
notify_streak_milestone_correct
process_notification_batch
reaction_delete_handler
reaction_insert_handler
recalculate_all_retroactive_points
recalculate_all_user_points
recalculate_all_users_streaks
recalculate_user_points_secure
recalculate_user_retroactive_points
recalculate_user_streak_from_scratch
remove_community_member
remove_points_secure
run_all_deletion_tests
should_create_notification
sync_user_points
test_comment_deletion
test_feedback_deletion
test_level_up_notification
test_points_integrity
test_reaction_deletion
test_streak_system
trigger_comment_created
trigger_comment_removed
trigger_feedback_removed
update_community
update_conversation_timestamp
update_conversation_timestamp_v2
update_updated_at_column
update_user_profile
update_user_streak
update_user_streak_incremental
update_user_streak_trigger
update_user_streak_with_data
update_user_total_points
```

</details>

---

## Triggers

Diretório: `sql/triggers/`

Triggers agrupados por tabela. Cada arquivo contém todos os triggers de uma tabela.

| Arquivo | Tabela | Qtd Triggers |
|---------|--------|--------------|
| `badges_triggers.sql` | badges | 1 |
| `chain_posts_triggers.sql` | chain_posts | 1 |
| `chains_triggers.sql` | chains | 1 |
| `comments_triggers.sql` | comments | 5 |
| `feedbacks_triggers.sql` | feedbacks | 4 |
| `follows_triggers.sql` | follows | 1 |
| `messages_triggers.sql` | messages | 1 |
| `posts_triggers.sql` | posts | 5 |
| `profiles_triggers.sql` | profiles | 2 |
| `reactions_triggers.sql` | reactions | 6 |
| `user_badges_triggers.sql` | user_badges | 1 |
| `user_points_triggers.sql` | user_points | 3 |
| `user_streaks_triggers.sql` | user_streaks | 1 |

**Total: 32 triggers**

---

## Constraints

Diretório: `sql/constraints/`

Constraints agrupados por tabela (PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK).

| Arquivo | Tabela | Qtd Constraints |
|---------|--------|-----------------|
| `badges_constraints.sql` | badges | 9 |
| `chain_posts_constraints.sql` | chain_posts | 11 |
| `chains_constraints.sql` | chains | 13 |
| `comments_constraints.sql` | comments | 5 |
| `communities_constraints.sql` | communities | 8 |
| `community_members_constraints.sql` | community_members | 6 |
| `conversations_constraints.sql` | conversations | 6 |
| `feedbacks_constraints.sql` | feedbacks | 6 |
| `follows_constraints.sql` | follows | 6 |
| `invites_constraints.sql` | invites | 7 |
| `levels_constraints.sql` | levels | 6 |
| `messages_constraints.sql` | messages | 7 |
| `notifications_constraints.sql` | notifications | 6 |
| `points_history_constraints.sql` | points_history | 5 |
| `posts_constraints.sql` | posts | 8 |
| `profiles_constraints.sql` | profiles | 5 |
| `reactions_constraints.sql` | reactions | 7 |
| `user_badges_constraints.sql` | user_badges | 6 |
| `user_points_constraints.sql` | user_points | 5 |
| `user_streaks_constraints.sql` | user_streaks | 2 |
| `waitlist_constraints.sql` | waitlist | 4 |

**Total: 138 constraints**

---

## Policies (RLS)

Diretório: `sql/policies/`

Row Level Security policies agrupadas por tabela.

| Arquivo | Tabela | Qtd Policies |
|---------|--------|--------------|
| `badges_policies.sql` | badges | 1 |
| `chain_posts_policies.sql` | chain_posts | 3 |
| `chains_policies.sql` | chains | 5 |
| `comments_policies.sql` | comments | 6 |
| `communities_policies.sql` | communities | 4 |
| `community_members_policies.sql` | community_members | 4 |
| `conversations_policies.sql` | conversations | 2 |
| `feedbacks_policies.sql` | feedbacks | 6 |
| `follows_policies.sql` | follows | 3 |
| `invites_policies.sql` | invites | 3 |
| `levels_policies.sql` | levels | 1 |
| `messages_policies.sql` | messages | 3 |
| `notifications_policies.sql` | notifications | 3 |
| `points_history_policies.sql` | points_history | 6 |
| `posts_policies.sql` | posts | 5 |
| `profiles_policies.sql` | profiles | 4 |
| `reactions_policies.sql` | reactions | 7 |
| `user_badges_policies.sql` | user_badges | 3 |
| `user_points_policies.sql` | user_points | 6 |
| `user_streaks_policies.sql` | user_streaks | 5 |
| `waitlist_policies.sql` | waitlist | 3 |

**Total: 83 policies**

---

## Migrations

Diretório: `sql/migrations/`

Migrações incrementais com formato `YYYYMMDD_descricao.sql`.

---

## Convenções

### Nomenclatura de Arquivos

| Tipo | Formato | Exemplo |
|------|---------|---------|
| Schema | `NN_tabela.sql` | `15_posts.sql` |
| Function | `nome_funcao.sql` | `handle_reaction_simple.sql` |
| Function (overload) | `nome_funcao_vN.sql` | `add_points_to_user_v2.sql` |
| Trigger | `tabela_triggers.sql` | `reactions_triggers.sql` |
| Constraint | `tabela_constraints.sql` | `posts_constraints.sql` |
| Policy | `tabela_policies.sql` | `profiles_policies.sql` |
| Migration | `YYYYMMDD_descricao.sql` | `20241229_update_reaction_types.sql` |

### Fluxo de Alterações

1. Criar migração em `migrations/`
2. Executar SQL no Supabase
3. **Atualizar arquivo principal correspondente** (function/trigger/etc)
4. Commit no GitHub

---

## Estatísticas

| Tipo | Quantidade |
|------|------------|
| Tabelas | 21 |
| Funções | 158 |
| Triggers | 32 |
| Constraints | 138 |
| Policies | 83 |

---

**Última extração:** 2025-12-29
