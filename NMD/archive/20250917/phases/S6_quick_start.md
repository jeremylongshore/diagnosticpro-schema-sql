# 🚀 NMD Quick Start Guide

**Time Required:** 5 minutes
**Date:** 2025-09-17
**Version:** 1.0.0

## What is NMD?

NMD is a battle-tested schema management system for BigQuery that handles:
- **266 production tables** across 5 datasets
- **Data validation** for scrapers and imports
- **Safe migrations** with automatic rollback
- **Scraper contracts** for consistent data collection

## 🎯 Most Common Tasks

### 1. "I need to validate data before importing to BigQuery"

```bash
# For scraped data (YouTube, Reddit, GitHub)
cat your_data.json | python3 test_pydantic_models.py

# For BigQuery NDJSON format
./S4_runner.py --validate-file your_data.ndjson --table youtube_repair_videos
```

✅ **Success looks like:** `Validation passed: 1000 records`
❌ **Failure looks like:** `ValidationError: dtc_code 'P00X1' does not match pattern`

### 2. "I need to migrate data from staging to production"

```bash
# ALWAYS create snapshots first (30 seconds)
export SNAPSHOT_SUFFIX="$(date +%Y%m%d_%H%M%S)"
bq query --use_legacy_sql=false < sql/rollback_snapshots.sql

# Run migration (2-5 minutes)
./migrate_staging_to_prod.sh

# Verify success
./validate_post_migration.sh
```

✅ **Success:** All 4 tables migrated, record counts match
❌ **Failure:** Automatic rollback initiated, check `migration_logs/`

### 3. "I need to check if a scraper's output matches our schema"

```bash
# Compare with golden samples
head -5 scraper_output.json > sample.json
diff sample.json S5_input_examples/youtube_repair_videos.ndjson

# Validate format
python3 S4_pydantic/validate_scraper_output.py < scraper_output.json
```

✅ **Good output:** Matches field names in `S5_event_contracts.yaml`
❌ **Bad output:** Missing required fields or wrong formats

### 4. "I need to see what tables exist in BigQuery"

```bash
# Quick overview
bq ls diagnosticpro_prod | grep -E "dtc_codes|reddit|youtube|equipment"

# Detailed schema for a table
bq show --schema --format=prettyjson diagnosticpro_prod.equipment_registry

# Record counts
bq query --use_legacy_sql=false \
  "SELECT 'dtc_codes_github' as table_name, COUNT(*) as count FROM \`repair_diagnostics.dtc_codes_github\`
   UNION ALL
   SELECT 'reddit_diagnostic_posts', COUNT(*) FROM \`repair_diagnostics.reddit_diagnostic_posts\`"
```

## 📋 Essential Files You'll Use

| File | When to Use It | Example Command |
|------|---------------|-----------------|
| **S4_runner.py** | Validate any data | `./S4_runner.py --validate-all` |
| **migrate_staging_to_prod.sh** | Move data to production | `./migrate_staging_to_prod.sh` |
| **S5_event_contracts.yaml** | Check scraper requirements | `grep "required_fields" S5_event_contracts.yaml` |
| **S5_input_examples/*.ndjson** | Test data samples | `cat S5_input_examples/youtube_repair_videos.ndjson` |

## 🔥 Speed Run: Import Scraped Data (2 minutes)

```bash
# 1. Validate your data (10 seconds)
python3 test_pydantic_models.py < scraped_data.json
# Output: "✅ All 1000 records valid"

# 2. Convert to BigQuery format (5 seconds)
cat scraped_data.json | jq -c . > import_ready.ndjson

# 3. Load to BigQuery (30 seconds)
bq load --source_format=NEWLINE_DELIMITED_JSON \
  --autodetect \
  repair_diagnostics.youtube_repair_videos \
  import_ready.ndjson

# 4. Verify import (5 seconds)
bq query --use_legacy_sql=false \
  "SELECT COUNT(*) FROM \`repair_diagnostics.youtube_repair_videos\`
   WHERE DATE(created_at) = CURRENT_DATE()"
```

## 🛡️ Safety Features

### Automatic Protections
- ✅ **Snapshots:** Every migration creates backups
- ✅ **Validation:** Data checked before import
- ✅ **Rollback:** Automatic recovery on failure
- ✅ **Logging:** Complete audit trail in `migration_logs/`

### Manual Safety Checks
```bash
# Before ANY production change
./validate_post_migration.sh --dry-run

# Check current data integrity
bq query --use_legacy_sql=false \
  "SELECT COUNT(*) as total,
          COUNT(DISTINCT dtc_code) as unique_codes
   FROM \`repair_diagnostics.dtc_codes_github\`"
```

## 🔍 Quick Troubleshooting

### "My scraper data won't validate"
```bash
# See what fields are expected
cat S5_event_contracts.yaml | grep -A5 "youtube_repair_videos"

# Check your field names
cat your_data.json | jq 'keys' | head -1

# Common fix: rename fields
cat your_data.json | jq '.[] |
  {video_id: .videoId, title, url, description, dtc_code: .error_code}'
```

### "Migration failed halfway"
```bash
# Automatic rollback should handle it, but verify:
./sql/rollback_restore.sql

# Check what went wrong
tail -50 migration_logs/migrate_*.log | grep ERROR
```

### "I don't know what tables exist"
```bash
# See everything
bq ls diagnosticpro_prod | wc -l  # Should show 266+

# See our 4 main tables
echo "Main Tables:"
for table in dtc_codes_github reddit_diagnostic_posts youtube_repair_videos equipment_registry; do
  echo "- $table"
done
```

## 📊 Expected Data Formats

### YouTube Videos (most common)
```json
{
  "video_id": "dQw4w9WgXcQ",
  "title": "How to Replace Brake Pads",
  "url": "https://youtube.com/watch?v=dQw4w9WgXcQ",
  "dtc_code": "C0035",
  "description": "Step by step brake replacement"
}
```

### Reddit Posts
```json
{
  "post_id": "abc123",
  "title": "P0301 Cylinder Misfire Help",
  "url": "https://reddit.com/r/MechanicAdvice/comments/abc123",
  "dtc_code": "P0301",
  "author": "user123"
}
```

### DTC Codes (GitHub)
```json
{
  "dtc_code": "P0301",
  "description": "Cylinder 1 Misfire Detected",
  "category": "powertrain",
  "severity": "moderate"
}
```

## 🎯 Next Steps

1. **Run your first validation:** `./S4_runner.py --help`
2. **Explore golden samples:** `ls -la S5_input_examples/`
3. **Read full docs:** [S6_README.md](S6_README.md)
4. **Check architecture:** [S6_architecture.md](S6_architecture.md)

## 💡 Pro Tips

- 🚀 **Always validate before importing** - saves hours of cleanup
- 📸 **Create snapshots before migrations** - instant rollback available
- 📝 **Check logs for details** - `migration_logs/` has everything
- 🔄 **Use golden samples for testing** - they're pre-validated
- ⚡ **Batch operations for speed** - 1000 records at a time

---

**Need more help?**
- Full documentation: [S6_README.md](S6_README.md)
- Architecture details: [S6_architecture.md](S6_architecture.md)
- Migration guide: [README_MIGRATION.md](README_MIGRATION.md)

**Quick Support:** Check `migration_logs/` for detailed error messages