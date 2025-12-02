---
name: Database Implementation
description: Database schema design, migrations, query optimization with SQL, Exposed ORM, Flyway. Use for database, migration, schema, sql, flyway tags. Provides migration patterns, validation commands, rollback strategies.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Database Implementation Skill

Domain-specific guidance for database schema design, migrations, and data modeling.

## When To Use This Skill

Load this Skill when task has tags:
- `database`, `migration`, `schema`, `sql`, `flyway`
- `exposed`, `orm`, `query`, `index`, `constraint`

## Validation Commands

### Run Migrations
```bash
# Gradle + Flyway
./gradlew flywayMigrate

# Test migration on clean database
./gradlew flywayClean flywayMigrate

# Check migration status
./gradlew flywayInfo

# Validate migrations
./gradlew flywayValidate
```

### Run Tests
```bash
# Migration tests
./gradlew test --tests "*migration*"

# Database integration tests
./gradlew test --tests "*Repository*"

# All tests
./gradlew test
```

## Success Criteria (Before Completing Task)

✅ **Migration runs without errors** on clean database
✅ **Schema matches design specifications**
✅ **Indexes created correctly**
✅ **Constraints validate as expected**
✅ **Rollback works** (if applicable)
✅ **Tests pass** with new schema

## Common Database Tasks

### Creating Migrations
- Add tables with columns, constraints
- Create indexes for performance
- Add foreign keys for referential integrity
- Modify existing schema (ALTER TABLE)
- Seed data (reference data)

### ORM Models
- Map entities to tables (Exposed, JPA)
- Define relationships (one-to-many, many-to-many)
- Configure cascading behavior
- Define custom queries

### Query Optimization
- Add indexes for frequently queried columns
- Analyze query plans (EXPLAIN)
- Optimize N+1 query problems
- Use appropriate JOIN types

## Migration Patterns

### Create Table

```sql
-- V001__create_users_table.sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);
```

### Add Column

```sql
-- V002__add_users_phone.sql
ALTER TABLE users
ADD COLUMN phone VARCHAR(20);

-- Add with default value
ALTER TABLE users
ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;
```

### Create Foreign Key

```sql
-- V003__create_tasks_table.sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(500) NOT NULL,
    user_id UUID NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Foreign key with cascade
    CONSTRAINT fk_tasks_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_tasks_user_id ON tasks(user_id);
```

### Create Junction Table (Many-to-Many)

```sql
-- V004__create_user_roles.sql
CREATE TABLE user_roles (
    user_id UUID NOT NULL,
    role_id UUID NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, role_id),

    CONSTRAINT fk_user_roles_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_user_roles_role
        FOREIGN KEY (role_id)
        REFERENCES roles(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);
```

## Testing Migrations

### Test Migration Execution

```kotlin
@Test
fun `migration V004 creates user_roles table`() {
    // Arrange - Clean database
    flyway.clean()

    // Act - Run migrations
    flyway.migrate()

    // Assert - Check table exists
    val tableExists = database.useConnection { connection ->
        val meta = connection.metaData
        val rs = meta.getTables(null, null, "user_roles", null)
        rs.next()
    }

    assertTrue(tableExists, "user_roles table should exist after migration")
}
```

### Test Constraints

```kotlin
@Test
fun `user_roles enforces foreign key constraint`() {
    // Arrange
    val invalidUserId = UUID.randomUUID()
    val role = createTestRole()

    // Act & Assert
    assertThrows<SQLException> {
        database.transaction {
            UserRoles.insert {
                it[userId] = invalidUserId  // Invalid - user doesn't exist
                it[roleId] = role.id
            }
        }
    }
}
```

## Common Blocker Scenarios

### Blocker 1: Migration Fails on Existing Data

**Issue:** Adding NOT NULL column to table with existing rows
```
ERROR: column "status" contains null values
```

**What to try:**
- Add column as nullable first
- Update existing rows with default value
- Then alter column to NOT NULL

**Example fix:**
```sql
-- Step 1: Add nullable
ALTER TABLE tasks ADD COLUMN status VARCHAR(20);

-- Step 2: Update existing rows
UPDATE tasks SET status = 'pending' WHERE status IS NULL;

-- Step 3: Make NOT NULL
ALTER TABLE tasks ALTER COLUMN status SET NOT NULL;
```

### Blocker 2: Circular Foreign Key Dependencies

**Issue:** Table A references B, B references A - which to create first?

**What to try:**
- Create both tables without foreign keys first
- Add foreign keys in separate migration after both exist

**Example:**
```sql
-- V001: Create tables without FKs
CREATE TABLE users (...);
CREATE TABLE profiles (...);

-- V002: Add foreign keys
ALTER TABLE users ADD CONSTRAINT fk_users_profile ...;
ALTER TABLE profiles ADD CONSTRAINT fk_profiles_user ...;
```

### Blocker 3: Index Creation Takes Too Long

**Issue:** Creating index on large table times out

**What to try:**
- Use CREATE INDEX CONCURRENTLY (PostgreSQL)
- Create index during low-traffic period
- Check if similar index already exists

### Blocker 4: Data Type Mismatch

**Issue:** ORM expects UUID but database has VARCHAR

**What to try:**
- Check migration SQL - correct type used?
- Check ORM mapping - correct type specified?
- Migrate data type if needed:
  ```sql
  ALTER TABLE tasks ALTER COLUMN id TYPE UUID USING id::uuid;
  ```

### Blocker 5: Missing Prerequisite Table

**Issue:** Foreign key references table that doesn't exist yet

**What to try:**
- Check migration order - migrations run in version order (V001, V002, etc.)
- Ensure referenced table created in earlier migration
- Check for typos in table names

**If blocked:** Report to orchestrator - migration order issue or missing prerequisite

## Blocker Report Format

```
⚠️ BLOCKED - Requires Senior Engineer

Issue: [Specific problem - migration fails, constraint violation, etc.]

Attempted Fixes:
- [What you tried #1]
- [What you tried #2]
- [Why attempts didn't work]

Root Cause (if known): [Your analysis]

Partial Progress: [What work you DID complete]

Context for Senior Engineer:
- Migration SQL: [Paste migration]
- Error output: [Database error]
- Related migrations: [Dependencies]

Requires: [What needs to happen]
```

## Exposed ORM Patterns

### Table Definition

```kotlin
object Users : UUIDTable("users") {
    val email = varchar("email", 255).uniqueIndex()
    val passwordHash = varchar("password_hash", 255)
    val name = varchar("name", 255)
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp())
}
```

### Foreign Key Relationship

```kotlin
object Tasks : UUIDTable("tasks") {
    val title = varchar("title", 500)
    val userId = reference("user_id", Users)
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
}
```

### Query with Join

```kotlin
fun findTasksWithUser(userId: UUID): List<TaskWithUser> {
    return (Tasks innerJoin Users)
        .select { Tasks.userId eq userId }
        .map { row ->
            TaskWithUser(
                task = rowToTask(row),
                user = rowToUser(row)
            )
        }
}
```

## Rollback Strategies

### Reversible Migrations

**Good (can rollback):**
- Adding nullable columns
- Adding indexes
- Creating new tables (if no data)

**Difficult to rollback:**
- Dropping columns (data loss)
- Changing data types (data transformation)
- Deleting tables (data loss)

### Include Rollback SQL

For complex migrations, document rollback steps:
```sql
-- Migration: V005__add_user_status.sql
ALTER TABLE users ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active';

-- Rollback (document in comments):
-- ALTER TABLE users DROP COLUMN status;
```

## Performance Tips

### Indexing Strategy

✅ **DO create indexes on:**
- Foreign key columns
- Frequently queried columns (WHERE, JOIN)
- Columns used in ORDER BY
- Unique constraints

❌ **DON'T create indexes on:**
- Small tables (< 1000 rows)
- Columns that change frequently
- Low cardinality columns (gender, boolean)

### Query Optimization

```sql
-- ❌ BAD - Missing index, full table scan
SELECT * FROM users WHERE email = 'user@example.com';

-- ✅ GOOD - Index on email column
CREATE INDEX idx_users_email ON users(email);

-- ❌ BAD - N+1 query problem
SELECT * FROM users;  -- 1 query
SELECT * FROM tasks WHERE user_id = ?;  -- N queries (one per user)

-- ✅ GOOD - Single query with JOIN
SELECT u.*, t.*
FROM users u
LEFT JOIN tasks t ON t.user_id = u.id;
```

## Common Patterns to Follow

1. **Sequential migration versioning** (V001, V002, V003...)
2. **Descriptive migration names** (V004__add_user_status.sql)
3. **Idempotent migrations** (can run multiple times safely)
4. **Test on clean database** before committing
5. **Foreign keys with indexes** for performance
6. **NOT NULL with defaults** for required fields
7. **Timestamps for audit trail** (created_at, updated_at)

## What NOT to Do

❌ Don't modify existing migrations (create new one)
❌ Don't drop columns without data backup
❌ Don't forget indexes on foreign keys
❌ Don't use SELECT * in production queries
❌ Don't skip testing migrations on clean database
❌ Don't forget CASCADE behavior on foreign keys
❌ Don't create migrations that depend on data state

## Focus Areas

When reading task sections, prioritize:
- `requirements` - What schema changes needed
- `technical-approach` - Migration strategy
- `data-model` - Entity relationships
- `migration` - Specific SQL requirements

## Remember

- **Test on clean database** - always validate migration from scratch
- **Indexes on foreign keys** - critical for performance
- **Sequential versioning** - V001, V002, V003...
- **Descriptive names** - migration filename explains what it does
- **Report blockers promptly** - constraint issues, circular dependencies
- **Document rollback** - comment how to reverse if needed
- **Validation is mandatory** - migration must succeed before completion

## Additional Resources

For deeper patterns and examples, see:
- **PATTERNS.md** - Complex schema patterns, performance optimization (load if needed)
- **BLOCKERS.md** - Detailed database-specific blockers (load if stuck)
- **examples.md** - Complete migration examples (load if uncertain)
